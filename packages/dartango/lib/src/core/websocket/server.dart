import 'dart:async';
import 'dart:io' as io;

import '../http/request.dart';
import '../http/response.dart';
import 'connection.dart';

class WebSocketServer {
  final WebSocketManager manager;
  final List<WebSocketMiddleware> middlewares;
  final Map<String, WebSocketChannel> channels = {};
  
  WebSocketServer({
    WebSocketManager? manager,
    List<WebSocketMiddleware>? middlewares,
  }) : manager = manager ?? WebSocketManager(),
       middlewares = middlewares ?? [];

  Future<HttpResponse> handleUpgrade(HttpRequest request) async {
    // Check if request is a WebSocket upgrade request
    if (!_isWebSocketUpgrade(request)) {
      return HttpResponse.badRequest('Not a WebSocket upgrade request');
    }

    try {
      // Process middlewares
      for (final middleware in middlewares) {
        final result = await middleware.canUpgrade(request);
        if (!result.allowed) {
          return HttpResponse.forbidden(result.reason ?? 'WebSocket upgrade denied');
        }
      }

      // Upgrade the connection
      final httpRequest = request.shelfRequest.context['shelf.io.http_request'] as io.HttpRequest;
      final socket = await io.WebSocketTransformer.upgrade(httpRequest);
      final connection = await manager.handleConnection(socket, request);

      // Process connection middlewares
      for (final middleware in middlewares) {
        await middleware.onConnect(connection);
      }

      // This will never be reached as WebSocket upgrade hijacks the request
      return HttpResponse.ok('WebSocket connection established');
    } catch (e) {
      return HttpResponse.internalServerError('Failed to upgrade to WebSocket: ${e.toString()}');
    }
  }

  bool _isWebSocketUpgrade(HttpRequest request) {
    final connection = request.headers['connection']?.toLowerCase();
    final upgrade = request.headers['upgrade']?.toLowerCase();
    return connection == 'upgrade' && upgrade == 'websocket';
  }

  void addChannel(String name, WebSocketChannel channel) {
    channels[name] = channel;
  }

  void removeChannel(String name) {
    channels.remove(name);
  }

  WebSocketChannel? getChannel(String name) {
    return channels[name];
  }

  void broadcast(String type, dynamic data, {String? excludeConnectionId}) {
    manager.broadcast(type, data, excludeConnectionId: excludeConnectionId);
  }

  void broadcastToChannel(String channel, String type, dynamic data, {String? excludeConnectionId}) {
    manager.broadcastToChannel(channel, type, data, excludeConnectionId: excludeConnectionId);
  }

  Map<String, dynamic> getStats() {
    return {
      ...manager.getStats(),
      'channels': channels.keys.toList(),
    };
  }

  void dispose() {
    manager.dispose();
  }
}

abstract class WebSocketMiddleware {
  Future<UpgradeResult> canUpgrade(HttpRequest request);
  Future<void> onConnect(WebSocketConnection connection) async {}
  Future<void> onDisconnect(WebSocketConnection connection) async {}
  Future<void> onMessage(WebSocketMessage message) async {}
  Future<void> onError(dynamic error, WebSocketConnection connection) async {}
}

class UpgradeResult {
  final bool allowed;
  final String? reason;

  UpgradeResult({required this.allowed, this.reason});

  factory UpgradeResult.allow() => UpgradeResult(allowed: true);
  factory UpgradeResult.deny(String reason) => UpgradeResult(allowed: false, reason: reason);
}

class WebSocketAuthMiddleware extends WebSocketMiddleware {
  final Future<dynamic> Function(String token)? getUserFromToken;
  final bool requireAuth;

  WebSocketAuthMiddleware({
    this.getUserFromToken,
    this.requireAuth = true,
  });

  @override
  Future<UpgradeResult> canUpgrade(HttpRequest request) async {
    if (!requireAuth) return UpgradeResult.allow();

    final token = request.headers['authorization']?.replaceFirst('Bearer ', '') ??
                  request.uri.queryParameters['token'];

    if (token == null) {
      return UpgradeResult.deny('Authentication token required');
    }

    if (getUserFromToken != null) {
      final user = await getUserFromToken!(token);
      if (user == null) {
        return UpgradeResult.deny('Invalid authentication token');
      }
    }

    return UpgradeResult.allow();
  }

  @override
  Future<void> onConnect(WebSocketConnection connection) async {
    if (!requireAuth) return;

    final token = connection.metadata['token'] as String?;
    if (token != null && getUserFromToken != null) {
      final user = await getUserFromToken!(token);
      if (user != null) {
        connection.authenticate(user);
      }
    }
  }
}

class WebSocketRateLimitMiddleware extends WebSocketMiddleware {
  final int maxMessagesPerMinute;
  final Map<String, List<DateTime>> _messageTimes = {};

  WebSocketRateLimitMiddleware({this.maxMessagesPerMinute = 60});

  @override
  Future<UpgradeResult> canUpgrade(HttpRequest request) async {
    return UpgradeResult.allow();
  }

  @override
  Future<void> onMessage(WebSocketMessage message) async {
    final connectionId = message.connection.id;
    final now = DateTime.now();
    
    _messageTimes.putIfAbsent(connectionId, () => []).add(now);
    
    // Clean old messages (older than 1 minute)
    final cutoff = now.subtract(const Duration(minutes: 1));
    _messageTimes[connectionId]!.removeWhere((time) => time.isBefore(cutoff));
    
    // Check rate limit
    if (_messageTimes[connectionId]!.length > maxMessagesPerMinute) {
      message.connection.sendError('Rate limit exceeded', code: 'RATE_LIMIT');
      message.connection.close(1008, 'Rate limit exceeded');
    }
  }

  @override
  Future<void> onDisconnect(WebSocketConnection connection) async {
    _messageTimes.remove(connection.id);
  }
}

class WebSocketLoggingMiddleware extends WebSocketMiddleware {
  final void Function(String message)? logger;

  WebSocketLoggingMiddleware({this.logger});

  void _log(String message) {
    if (logger != null) {
      logger!(message);
    } else {
      print('[WebSocket] $message');
    }
  }

  @override
  Future<UpgradeResult> canUpgrade(HttpRequest request) async {
    _log('WebSocket upgrade request from ${request.remoteAddr}');
    return UpgradeResult.allow();
  }

  @override
  Future<void> onConnect(WebSocketConnection connection) async {
    _log('WebSocket connected: ${connection.id}');
  }

  @override
  Future<void> onDisconnect(WebSocketConnection connection) async {
    _log('WebSocket disconnected: ${connection.id}');
  }

  @override
  Future<void> onMessage(WebSocketMessage message) async {
    _log('WebSocket message: ${message.type} from ${message.connection.id}');
  }

  @override
  Future<void> onError(dynamic error, WebSocketConnection connection) async {
    _log('WebSocket error: $error for connection ${connection.id}');
  }
}

class WebSocketCorsMiddleware extends WebSocketMiddleware {
  final List<String> allowedOrigins;

  WebSocketCorsMiddleware({this.allowedOrigins = const ['*']});

  @override
  Future<UpgradeResult> canUpgrade(HttpRequest request) async {
    final origin = request.headers['origin'];
    
    if (origin == null) {
      return UpgradeResult.deny('Origin header required');
    }

    if (!allowedOrigins.contains('*') && !allowedOrigins.contains(origin)) {
      return UpgradeResult.deny('Origin not allowed');
    }

    return UpgradeResult.allow();
  }
}

class WebSocketRoom {
  final String name;
  final WebSocketManager manager;
  final Set<String> _members = {};
  final Map<String, dynamic> _metadata = {};

  WebSocketRoom(this.name, this.manager);

  Set<String> get members => Set.unmodifiable(_members);
  Map<String, dynamic> get metadata => Map.unmodifiable(_metadata);
  int get memberCount => _members.length;

  void join(String connectionId) {
    _members.add(connectionId);
    _notifyMembershipChange(connectionId, 'joined');
  }

  void leave(String connectionId) {
    _members.remove(connectionId);
    _notifyMembershipChange(connectionId, 'left');
  }

  void broadcast(String type, dynamic data, {String? excludeConnectionId}) {
    for (final connectionId in _members) {
      if (connectionId != excludeConnectionId) {
        manager.sendToConnection(connectionId, type, data);
      }
    }
  }

  void setMetadata(String key, dynamic value) {
    _metadata[key] = value;
  }

  dynamic getMetadata(String key) {
    return _metadata[key];
  }

  void _notifyMembershipChange(String connectionId, String action) {
    broadcast('room_member_$action', {
      'room': name,
      'connection_id': connectionId,
      'member_count': memberCount,
    }, excludeConnectionId: connectionId);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'member_count': memberCount,
      'members': _members.toList(),
      'metadata': _metadata,
    };
  }
}

class WebSocketRoomManager {
  final WebSocketManager manager;
  final Map<String, WebSocketRoom> _rooms = {};

  WebSocketRoomManager(this.manager);

  WebSocketRoom createRoom(String name) {
    final room = WebSocketRoom(name, manager);
    _rooms[name] = room;
    return room;
  }

  WebSocketRoom? getRoom(String name) {
    return _rooms[name];
  }

  void deleteRoom(String name) {
    _rooms.remove(name);
  }

  List<String> getRoomNames() {
    return _rooms.keys.toList();
  }

  List<WebSocketRoom> getRooms() {
    return _rooms.values.toList();
  }

  void joinRoom(String roomName, String connectionId) {
    final room = _rooms[roomName];
    if (room != null) {
      room.join(connectionId);
    }
  }

  void leaveRoom(String roomName, String connectionId) {
    final room = _rooms[roomName];
    if (room != null) {
      room.leave(connectionId);
    }
  }

  void leaveAllRooms(String connectionId) {
    for (final room in _rooms.values) {
      room.leave(connectionId);
    }
  }

  Map<String, dynamic> getStats() {
    return {
      'total_rooms': _rooms.length,
      'rooms': _rooms.map((name, room) => MapEntry(name, room.toJson())),
    };
  }
}