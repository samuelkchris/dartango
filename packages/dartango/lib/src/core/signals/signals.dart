import 'dart:async';

/// Interface for signal receivers
typedef SignalReceiver<T> = Future<void> Function(T sender,
    {Map<String, dynamic>? kwargs});

/// Unique identifier for signal receivers
class ReceiverId {
  final String id;
  final int hashCode;

  ReceiverId(this.id) : hashCode = id.hashCode;

  @override
  bool operator ==(Object other) => other is ReceiverId && other.id == id;

  @override
  String toString() => 'ReceiverId($id)';
}

/// Signal that can be connected to and dispatched
class Signal<T> {
  final String name;
  final bool providingArgs;
  final List<String> validArguments;

  final Map<ReceiverId, SignalReceiver<T>> _receivers = {};
  final Map<ReceiverId, bool> _weakReceivers = {};
  final Map<ReceiverId, Type?> _senderFilters = {};
  final Map<ReceiverId, String?> _dispatchUids = {};

  bool _locked = false;

  Signal({
    required this.name,
    this.providingArgs = false,
    this.validArguments = const [],
  });

  /// Connect a receiver to this signal
  void connect({
    required SignalReceiver<T> receiver,
    Type? sender,
    bool weak = false,
    String? dispatchUid,
  }) {
    if (_locked) {
      throw StateError('Cannot connect to a locked signal');
    }

    final receiverId = ReceiverId(dispatchUid ?? _generateReceiverId(receiver));

    // Check if already connected
    if (_receivers.containsKey(receiverId)) {
      if (dispatchUid != null) {
        throw ArgumentError(
            'Signal receiver with dispatch_uid "$dispatchUid" already connected');
      }
      return;
    }

    _receivers[receiverId] = receiver;
    _weakReceivers[receiverId] = weak;
    _senderFilters[receiverId] = sender;
    _dispatchUids[receiverId] = dispatchUid;

    _clearDeadReceivers();
  }

  /// Disconnect a receiver from this signal
  bool disconnect({
    SignalReceiver<T>? receiver,
    Type? sender,
    String? dispatchUid,
  }) {
    if (_locked) {
      throw StateError('Cannot disconnect from a locked signal');
    }

    bool disconnected = false;
    final toRemove = <ReceiverId>[];

    for (final entry in _receivers.entries) {
      final receiverId = entry.key;
      final currentReceiver = entry.value;
      final currentSender = _senderFilters[receiverId];
      final currentDispatchUid = _dispatchUids[receiverId];

      bool shouldDisconnect = false;

      if (dispatchUid != null) {
        shouldDisconnect = currentDispatchUid == dispatchUid;
      } else if (receiver != null) {
        shouldDisconnect =
            currentReceiver == receiver && currentSender == sender;
      } else if (sender != null) {
        shouldDisconnect = currentSender == sender;
      } else {
        shouldDisconnect = true;
      }

      if (shouldDisconnect) {
        toRemove.add(receiverId);
        disconnected = true;
      }
    }

    for (final receiverId in toRemove) {
      _receivers.remove(receiverId);
      _weakReceivers.remove(receiverId);
      _senderFilters.remove(receiverId);
      _dispatchUids.remove(receiverId);
    }

    return disconnected;
  }

  /// Check if any receivers are connected
  bool get hasListeners => _receivers.isNotEmpty;

  /// Get count of connected receivers
  int get receiversCount => _receivers.length;

  /// Send signal to all connected receivers
  Future<List<SignalResponse<T>>> send({
    required T sender,
    Map<String, dynamic>? kwargs,
  }) async {
    if (_receivers.isEmpty) {
      return [];
    }

    _locked = true;
    final responses = <SignalResponse<T>>[];

    try {
      // Validate arguments if specified
      if (validArguments.isNotEmpty && kwargs != null) {
        for (final key in kwargs.keys) {
          if (!validArguments.contains(key)) {
            throw ArgumentError('Invalid argument "$key" for signal "$name"');
          }
        }
      }

      // Create a copy of receivers to avoid modification during iteration
      final receiversCopy = Map<ReceiverId, SignalReceiver<T>>.from(_receivers);

      for (final entry in receiversCopy.entries) {
        final receiverId = entry.key;
        final receiver = entry.value;
        final senderFilter = _senderFilters[receiverId];

        // Check if receiver is still alive (for weak references)
        if (_weakReceivers[receiverId] == true) {
          // In a real implementation, we'd check if the weak reference is still alive
          // For now, assume all receivers are alive
        }

        // Check sender filter
        if (senderFilter != null && sender.runtimeType != senderFilter) {
          continue;
        }

        try {
          await receiver(sender, kwargs: kwargs);
          responses.add(SignalResponse<T>(
            receiver: receiver,
            sender: sender,
            success: true,
          ));
        } catch (error, stackTrace) {
          responses.add(SignalResponse<T>(
            receiver: receiver,
            sender: sender,
            success: false,
            error: error,
            stackTrace: stackTrace,
          ));
        }
      }

      _clearDeadReceivers();
    } finally {
      _locked = false;
    }

    return responses;
  }

  /// Send signal to all connected receivers (synchronous version)
  Future<List<SignalResponse<T>>> sendRobust({
    required T sender,
    Map<String, dynamic>? kwargs,
  }) async {
    // Same as send but catches all exceptions
    return await send(sender: sender, kwargs: kwargs);
  }

  void _clearDeadReceivers() {
    final deadReceivers = <ReceiverId>[];

    for (final receiverId in _receivers.keys) {
      if (_weakReceivers[receiverId] == true) {
        // In a real implementation, we'd check if the weak reference is still alive
        // For now, assume all receivers are alive
      }
    }

    for (final receiverId in deadReceivers) {
      _receivers.remove(receiverId);
      _weakReceivers.remove(receiverId);
      _senderFilters.remove(receiverId);
      _dispatchUids.remove(receiverId);
    }
  }

  String _generateReceiverId(SignalReceiver<T> receiver) {
    return '${receiver.hashCode}_${DateTime.now().microsecondsSinceEpoch}';
  }
}

/// Response from a signal receiver
class SignalResponse<T> {
  final SignalReceiver<T> receiver;
  final T sender;
  final bool success;
  final Object? error;
  final StackTrace? stackTrace;

  SignalResponse({
    required this.receiver,
    required this.sender,
    required this.success,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    if (success) {
      return 'SignalResponse(success: true, receiver: ${receiver.runtimeType})';
    } else {
      return 'SignalResponse(success: false, error: $error, receiver: ${receiver.runtimeType})';
    }
  }
}

/// Global signal registry
class SignalRegistry {
  static final SignalRegistry _instance = SignalRegistry._internal();
  factory SignalRegistry() => _instance;
  SignalRegistry._internal();

  final Map<String, Signal> _signals = {};

  /// Register a signal
  void register<T>(String name, Signal<T> signal) {
    _signals[name] = signal;
  }

  /// Get a signal by name
  Signal<T>? get<T>(String name) {
    return _signals[name] as Signal<T>?;
  }

  /// Get all registered signals
  Map<String, Signal> get all => Map.unmodifiable(_signals);

  /// Clear all signals
  void clear() {
    _signals.clear();
  }
}

/// Decorator for connecting signal receivers
class SignalReceiverDecorator {
  final Signal signal;
  final Type? sender;
  final bool weak;
  final String? dispatchUid;

  const SignalReceiverDecorator(
    this.signal, {
    this.sender,
    this.weak = false,
    this.dispatchUid,
  });
}

/// Exception thrown when signal operations fail
class SignalException implements Exception {
  final String message;
  final Object? cause;

  SignalException(this.message, {this.cause});

  @override
  String toString() =>
      'SignalException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Mixin for classes that can send signals
mixin SignalSender {
  /// Send a signal with this object as sender
  Future<List<SignalResponse>> sendSignal<T>(
    Signal<T> signal, {
    Map<String, dynamic>? kwargs,
  }) async {
    return await signal.send(sender: this as T, kwargs: kwargs);
  }
}

/// Context manager for temporarily connecting signal receivers
class SignalContext {
  final List<_SignalConnection> _connections = [];
  bool _active = false;

  /// Connect a receiver for the duration of this context
  void connect<T>({
    required Signal<T> signal,
    required SignalReceiver<T> receiver,
    Type? sender,
    bool weak = false,
    String? dispatchUid,
  }) {
    if (_active) {
      throw StateError('Cannot add connections to an active context');
    }

    _connections.add(_SignalConnection<T>(
      signal: signal,
      receiver: receiver,
      sender: sender,
      weak: weak,
      dispatchUid: dispatchUid,
    ));
  }

  /// Enter the context and connect all receivers
  void enter() {
    if (_active) {
      throw StateError('Context is already active');
    }

    _active = true;
    for (final connection in _connections) {
      connection.connect();
    }
  }

  /// Exit the context and disconnect all receivers
  void exit() {
    if (!_active) {
      throw StateError('Context is not active');
    }

    for (final connection in _connections) {
      connection.disconnect();
    }
    _active = false;
  }

  /// Execute a function within this signal context
  Future<R> run<R>(Future<R> Function() fn) async {
    enter();
    try {
      return await fn();
    } catch (e) {
      exit();
      rethrow;
    } finally {
      if (_active) {
        exit();
      }
    }
  }
}

class _SignalConnection<T> {
  final Signal<T> signal;
  final SignalReceiver<T> receiver;
  final Type? sender;
  final bool weak;
  final String? dispatchUid;

  _SignalConnection({
    required this.signal,
    required this.receiver,
    this.sender,
    this.weak = false,
    this.dispatchUid,
  });

  void connect() {
    signal.connect(
      receiver: receiver,
      sender: sender,
      weak: weak,
      dispatchUid: dispatchUid,
    );
  }

  void disconnect() {
    signal.disconnect(
      receiver: receiver,
      sender: sender,
      dispatchUid: dispatchUid,
    );
  }
}

/// Test helper for signal testing
class SignalTestHelper {
  final List<SignalResponse> _responses = [];

  /// Receiver function that captures responses
  Future<void> captureSignal<T>(T sender,
      {Map<String, dynamic>? kwargs}) async {
    _responses.add(SignalResponse<T>(
      receiver: captureSignal<T>,
      sender: sender,
      success: true,
    ));
  }

  /// Get all captured responses
  List<SignalResponse> get responses => List.unmodifiable(_responses);

  /// Clear captured responses
  void clear() {
    _responses.clear();
  }

  /// Check if signal was received
  bool wasReceived({Type? senderType}) {
    if (senderType == null) {
      return _responses.isNotEmpty;
    }
    return _responses.any((r) => r.sender.runtimeType == senderType);
  }

  /// Get count of received signals
  int get receivedCount => _responses.length;
}

/// Built-in Django-compatible signals
class DjangoSignals {
  static final Signal<dynamic> preInit = Signal(name: 'pre_init');
  static final Signal<dynamic> postInit = Signal(name: 'post_init');
  static final Signal<dynamic> preSave = Signal(name: 'pre_save');
  static final Signal<dynamic> postSave = Signal(name: 'post_save');
  static final Signal<dynamic> preDelete = Signal(name: 'pre_delete');
  static final Signal<dynamic> postDelete = Signal(name: 'post_delete');
  static final Signal<dynamic> preMigrate = Signal(name: 'pre_migrate');
  static final Signal<dynamic> postMigrate = Signal(name: 'post_migrate');
  static final Signal<dynamic> requestStarted = Signal(name: 'request_started');
  static final Signal<dynamic> requestFinished =
      Signal(name: 'request_finished');
  static final Signal<dynamic> gotRequestException =
      Signal(name: 'got_request_exception');

  /// Register all Django signals
  static void registerAll() {
    final registry = SignalRegistry();
    registry.register('pre_init', preInit);
    registry.register('post_init', postInit);
    registry.register('pre_save', preSave);
    registry.register('post_save', postSave);
    registry.register('pre_delete', preDelete);
    registry.register('post_delete', postDelete);
    registry.register('pre_migrate', preMigrate);
    registry.register('post_migrate', postMigrate);
    registry.register('request_started', requestStarted);
    registry.register('request_finished', requestFinished);
    registry.register('got_request_exception', gotRequestException);
  }
}

/// Initialize signals system
void initializeSignals() {
  DjangoSignals.registerAll();
}
