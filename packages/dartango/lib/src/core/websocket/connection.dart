import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../http/request.dart';

class WebSocketConnection {
  final String id;
  final WebSocket socket;
  final DateTime connectedAt;
  final Map<String, dynamic> metadata;
  final StreamController<WebSocketMessage> _messageController;
  final List<String> _subscriptions = [];

  bool _isAuthenticated = false;
  dynamic _user;

  WebSocketConnection({
    required this.id,
    required this.socket,
    required this.connectedAt,
    Map<String, dynamic>? metadata,
  })  : metadata = metadata ?? {},
        _messageController = StreamController<WebSocketMessage>.broadcast();

  Stream<WebSocketMessage> get messages => _messageController.stream;
  List<String> get subscriptions => List.unmodifiable(_subscriptions);
  bool get isAuthenticated => _isAuthenticated;
  dynamic get user => _user;
  bool get isConnected => socket.readyState == WebSocket.open;

  void send(dynamic data) {
    if (isConnected) {
      socket.add(jsonEncode(data));
    }
  }

  void sendMessage(String type, dynamic data, {String? target}) {
    send({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      if (target != null) 'target': target,
    });
  }

  void sendError(String error, {String? code}) {
    sendMessage('error', {
      'message': error,
      if (code != null) 'code': code,
    });
  }

  void authenticate(dynamic user) {
    _isAuthenticated = true;
    _user = user;
    sendMessage('auth_success', {'user': user});
  }

  void subscribe(String channel) {
    if (!_subscriptions.contains(channel)) {
      _subscriptions.add(channel);
      sendMessage('subscribed', {'channel': channel});
    }
  }

  void unsubscribe(String channel) {
    _subscriptions.remove(channel);
    sendMessage('unsubscribed', {'channel': channel});
  }

  void close([int? code, String? reason]) {
    _messageController.close();
    socket.close(code, reason);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connected_at': connectedAt.toIso8601String(),
      'is_authenticated': _isAuthenticated,
      'subscriptions': _subscriptions,
      'metadata': metadata,
    };
  }
}

class WebSocketMessage {
  final String type;
  final dynamic data;
  final DateTime timestamp;
  final String? target;
  final WebSocketConnection connection;

  WebSocketMessage({
    required this.type,
    required this.data,
    required this.timestamp,
    this.target,
    required this.connection,
  });

  factory WebSocketMessage.fromJson(
    Map<String, dynamic> json,
    WebSocketConnection connection,
  ) {
    return WebSocketMessage(
      type: json['type'] as String,
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      target: json['target'] as String?,
      connection: connection,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      if (target != null) 'target': target,
      'connection_id': connection.id,
    };
  }
}

class WebSocketManager {
  final Map<String, WebSocketConnection> _connections = {};
  final Map<String, Set<String>> _channels = {};
  final StreamController<WebSocketMessage> _messageController;
  final StreamController<WebSocketConnection> _connectionController;
  final StreamController<WebSocketConnection> _disconnectionController;

  WebSocketManager()
      : _messageController = StreamController<WebSocketMessage>.broadcast(),
        _connectionController =
            StreamController<WebSocketConnection>.broadcast(),
        _disconnectionController =
            StreamController<WebSocketConnection>.broadcast();

  Stream<WebSocketMessage> get messages => _messageController.stream;
  Stream<WebSocketConnection> get connections => _connectionController.stream;
  Stream<WebSocketConnection> get disconnections =>
      _disconnectionController.stream;

  List<WebSocketConnection> get activeConnections =>
      _connections.values.where((conn) => conn.isConnected).toList();

  int get connectionCount => _connections.length;

  Future<WebSocketConnection> handleConnection(
    WebSocket socket,
    HttpRequest request,
  ) async {
    final connectionId = _generateConnectionId();
    final connection = WebSocketConnection(
      id: connectionId,
      socket: socket,
      connectedAt: DateTime.now(),
      metadata: {
        'user_agent': request.headers['user-agent'],
        'remote_address': request.remoteAddr,
        'path': request.path,
        'query_parameters': request.uri.queryParameters,
      },
    );

    _connections[connectionId] = connection;
    _connectionController.add(connection);

    // Listen for messages
    socket.listen(
      (data) => _handleMessage(data, connection),
      onDone: () => _handleDisconnection(connection),
      onError: (error) => _handleError(error, connection),
    );

    // Send welcome message
    connection.sendMessage('connected', {
      'connection_id': connectionId,
      'server_time': DateTime.now().toIso8601String(),
    });

    return connection;
  }

  void _handleMessage(dynamic data, WebSocketConnection connection) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WebSocketMessage.fromJson(json, connection);

      _messageController.add(message);

      // Handle built-in message types
      switch (message.type) {
        case 'subscribe':
          final channel = message.data['channel'] as String?;
          if (channel != null) {
            _subscribeToChannel(connection, channel);
          }
          break;
        case 'unsubscribe':
          final channel = message.data['channel'] as String?;
          if (channel != null) {
            _unsubscribeFromChannel(connection, channel);
          }
          break;
        case 'ping':
          connection.sendMessage('pong', message.data);
          break;
      }
    } catch (e) {
      connection.sendError('Invalid message format', code: 'INVALID_JSON');
    }
  }

  void _handleDisconnection(WebSocketConnection connection) {
    _connections.remove(connection.id);

    // Remove from all channels
    for (final channel in connection.subscriptions) {
      _channels[channel]?.remove(connection.id);
      if (_channels[channel]?.isEmpty == true) {
        _channels.remove(channel);
      }
    }

    _disconnectionController.add(connection);
  }

  void _handleError(dynamic error, WebSocketConnection connection) {
    connection.sendError('Connection error: ${error.toString()}');
  }

  void _subscribeToChannel(WebSocketConnection connection, String channel) {
    _channels.putIfAbsent(channel, () => <String>{}).add(connection.id);
    connection.subscribe(channel);
  }

  void _unsubscribeFromChannel(WebSocketConnection connection, String channel) {
    _channels[channel]?.remove(connection.id);
    if (_channels[channel]?.isEmpty == true) {
      _channels.remove(channel);
    }
    connection.unsubscribe(channel);
  }

  void broadcast(String type, dynamic data, {String? excludeConnectionId}) {
    final message = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    for (final connection in activeConnections) {
      if (connection.id != excludeConnectionId) {
        connection.send(message);
      }
    }
  }

  void broadcastToChannel(String channel, String type, dynamic data,
      {String? excludeConnectionId}) {
    final connectionIds = _channels[channel] ?? <String>{};
    final message = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'channel': channel,
    };

    for (final connectionId in connectionIds) {
      final connection = _connections[connectionId];
      if (connection != null &&
          connection.isConnected &&
          connection.id != excludeConnectionId) {
        connection.send(message);
      }
    }
  }

  void sendToConnection(String connectionId, String type, dynamic data) {
    final connection = _connections[connectionId];
    if (connection != null && connection.isConnected) {
      connection.sendMessage(type, data);
    }
  }

  void sendToUser(dynamic userId, String type, dynamic data) {
    for (final connection in activeConnections) {
      if (connection.isAuthenticated && connection.user?['id'] == userId) {
        connection.sendMessage(type, data);
      }
    }
  }

  void closeConnection(String connectionId, {int? code, String? reason}) {
    final connection = _connections[connectionId];
    if (connection != null) {
      connection.close(code, reason);
    }
  }

  void closeAllConnections({int? code, String? reason}) {
    for (final connection in activeConnections) {
      connection.close(code, reason);
    }
  }

  List<String> getChannels() {
    return _channels.keys.toList();
  }

  List<WebSocketConnection> getChannelConnections(String channel) {
    final connectionIds = _channels[channel] ?? <String>{};
    return connectionIds
        .map((id) => _connections[id])
        .where((conn) => conn != null && conn.isConnected)
        .cast<WebSocketConnection>()
        .toList();
  }

  WebSocketConnection? getConnection(String connectionId) {
    return _connections[connectionId];
  }

  Map<String, dynamic> getStats() {
    return {
      'total_connections': _connections.length,
      'active_connections': activeConnections.length,
      'channels': _channels.length,
      'channel_subscriptions': _channels
          .map((channel, connections) => MapEntry(channel, connections.length)),
    };
  }

  String _generateConnectionId() {
    return 'conn_${DateTime.now().millisecondsSinceEpoch}_${_connections.length}';
  }

  void dispose() {
    closeAllConnections();
    _messageController.close();
    _connectionController.close();
    _disconnectionController.close();
  }
}

class WebSocketChannel {
  final String name;
  final WebSocketManager manager;
  final List<String> _permissions = [];

  WebSocketChannel(this.name, this.manager);

  List<String> get permissions => List.unmodifiable(_permissions);

  void addPermission(String permission) {
    if (!_permissions.contains(permission)) {
      _permissions.add(permission);
    }
  }

  void removePermission(String permission) {
    _permissions.remove(permission);
  }

  bool hasPermission(String permission) {
    return _permissions.contains(permission);
  }

  void broadcast(String type, dynamic data, {String? excludeConnectionId}) {
    manager.broadcastToChannel(name, type, data,
        excludeConnectionId: excludeConnectionId);
  }

  List<WebSocketConnection> get connections {
    return manager.getChannelConnections(name);
  }

  int get connectionCount => connections.length;

  bool canJoin(WebSocketConnection connection) {
    // Override this method to implement custom join logic
    return true;
  }

  void onJoin(WebSocketConnection connection) {
    // Override this method to handle join events
  }

  void onLeave(WebSocketConnection connection) {
    // Override this method to handle leave events
  }

  void onMessage(WebSocketMessage message) {
    // Override this method to handle channel messages
  }
}

mixin WebSocketAuthMixin {
  Future<bool> authenticate(
      WebSocketConnection connection, Map<String, dynamic> credentials) async {
    // Implement your authentication logic here
    return false;
  }

  Future<dynamic> getUserFromToken(String token) async {
    // Implement your user lookup logic here
    return null;
  }

  bool canAccessChannel(WebSocketConnection connection, String channel) {
    // Implement your authorization logic here
    return connection.isAuthenticated;
  }
}
