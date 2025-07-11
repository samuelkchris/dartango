import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class WebSocketService extends ChangeNotifier {
  WebSocket? _socket;
  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;
  String? _errorMessage;
  final Map<String, List<Function(Map<String, dynamic>)>> _listeners = {};
  final String _baseUrl;
  String? _authToken;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  WebSocketService({String? baseUrl})
      : _baseUrl = baseUrl ?? Constants.defaultWebSocketUrl;

  WebSocketConnectionState get connectionState => _connectionState;
  String? get errorMessage => _errorMessage;
  bool get isConnected =>
      _connectionState == WebSocketConnectionState.connected;

  Future<void> connect({String? authToken}) async {
    if (_connectionState == WebSocketConnectionState.connecting ||
        _connectionState == WebSocketConnectionState.connected) {
      return;
    }

    _authToken = authToken;
    _setConnectionState(WebSocketConnectionState.connecting);

    try {
      final uri = Uri.parse(_baseUrl);
      final headers = <String, dynamic>{};

      if (_authToken != null) {
        headers['Authorization'] = 'Bearer $_authToken';
      }

      _socket = await WebSocket.connect(
        uri.toString(),
        headers: headers,
      );

      _setConnectionState(WebSocketConnectionState.connected);
      _resetReconnectAttempts();

      _socket!.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      if (kDebugMode) {
        print('WebSocket connected to $_baseUrl');
      }
    } catch (e) {
      _handleError(e);
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _socket?.close();
    _socket = null;
    _setConnectionState(WebSocketConnectionState.disconnected);

    if (kDebugMode) {
      print('WebSocket disconnected');
    }
  }

  void send(String event, Map<String, dynamic> data) {
    if (!isConnected) {
      if (kDebugMode) {
        print('Cannot send message: WebSocket not connected');
      }
      return;
    }

    final message = jsonEncode({
      'event': event,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _socket!.add(message);
  }

  void subscribe(String event, Function(Map<String, dynamic>) callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = [];
    }
    _listeners[event]!.add(callback);
  }

  void unsubscribe(String event, Function(Map<String, dynamic>) callback) {
    if (_listeners.containsKey(event)) {
      _listeners[event]!.remove(callback);
      if (_listeners[event]!.isEmpty) {
        _listeners.remove(event);
      }
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final event = data['event'] as String?;
      final payload = data['data'] as Map<String, dynamic>? ?? {};

      if (event != null && _listeners.containsKey(event)) {
        for (final callback in _listeners[event]!) {
          callback(payload);
        }
      }

      if (kDebugMode) {
        print('WebSocket message received: $event');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing WebSocket message: $e');
      }
    }
  }

  void _handleError(dynamic error) {
    _errorMessage = error.toString();
    _setConnectionState(WebSocketConnectionState.error);

    if (kDebugMode) {
      print('WebSocket error: $error');
    }

    if (_shouldReconnect) {
      _scheduleReconnection();
    }
  }

  void _handleDisconnection() {
    _setConnectionState(WebSocketConnectionState.disconnected);

    if (kDebugMode) {
      print('WebSocket disconnected');
    }

    if (_shouldReconnect) {
      _scheduleReconnection();
    }
  }

  void _scheduleReconnection() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('Max reconnection attempts reached');
      }
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);

    if (kDebugMode) {
      print(
          'Scheduling reconnection in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)');
    }

    Future.delayed(delay, () {
      if (_shouldReconnect && !isConnected) {
        connect(authToken: _authToken);
      }
    });
  }

  void _setConnectionState(WebSocketConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }

  void _resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

class WebSocketEvent {
  static const String userCreated = 'user_created';
  static const String userUpdated = 'user_updated';
  static const String userDeleted = 'user_deleted';
  static const String groupCreated = 'group_created';
  static const String groupUpdated = 'group_updated';
  static const String groupDeleted = 'group_deleted';
  static const String systemMetrics = 'system_metrics';
  static const String activityLog = 'activity_log';
  static const String notification = 'notification';
  static const String sessionUpdate = 'session_update';
}
