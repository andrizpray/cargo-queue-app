import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/logger.dart';

enum WebSocketEventType {
  queueCreated('queue.created'),
  queueStatusChanged('queue.status-changed'),
  queueDeleted('queue.deleted');

  final String value;
  const WebSocketEventType(this.value);

  static WebSocketEventType? fromString(String value) {
    try {
      return WebSocketEventType.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }
}

class WebSocketEvent {
  final WebSocketEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['event'] as String?;
    final type = WebSocketEventType.fromString(typeStr ?? '');

    return WebSocketEvent(
      type: type ?? WebSocketEventType.queueCreated,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

class WebSocketService {
  final String url;
  WebSocketChannel? _channel;
  StreamController<WebSocketEvent>? _eventController;
  StreamController<bool>? _connectionStatusController;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  bool _isConnecting = false;
  static const int _reconnectDelaySeconds = 5;
  static const int _maxReconnectAttempts = 10;
  int _reconnectAttempts = 0;

  WebSocketService({required this.url});

  /// Stream of WebSocket events
  Stream<WebSocketEvent> get events => _eventController?.stream ?? Stream.empty();

  /// Stream of connection status (true = connected, false = disconnected)
  Stream<bool> get connectionStatus =>
      _connectionStatusController?.stream ?? Stream.empty();

  /// Current connection status
  bool get isConnected => _channel != null && !_isDisposed;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnecting || isConnected) return;

    _isConnecting = true;
    _eventController ??= StreamController<WebSocketEvent>.broadcast();
    _connectionStatusController ??=
        StreamController<bool>.broadcast();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Wait for connection to establish
      await _channel!.ready;

      _reconnectAttempts = 0;
      _connectionStatusController?.add(true);

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
    } catch (e) {
      _handleError(e);
    } finally {
      _isConnecting = false;
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _connectionStatusController?.add(false);
  }

  /// Send a message through WebSocket
  void send(String event, Map<String, dynamic> data) {
    if (!isConnected) {
      throw Exception('WebSocket is not connected');
    }

    final message = jsonEncode({
      'event': event,
      'data': data,
    });

    _channel?.sink.add(message);
  }

  /// Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final json = jsonDecode(message) as Map<String, dynamic>;
        final event = WebSocketEvent.fromJson(json);
        _eventController?.add(event);
      }
    } catch (e) {
      AppLogger.error('Error parsing WebSocket message', e);
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    AppLogger.error('WebSocket error', error);
    _connectionStatusController?.add(false);
    _attemptReconnect();
  }

  /// Handle WebSocket connection closed
  void _handleDone() {
    AppLogger.info('WebSocket connection closed');
    _channel = null;
    _connectionStatusController?.add(false);
    _attemptReconnect();
  }

  /// Attempt to reconnect with exponential backoff
  void _attemptReconnect() {
    if (_isDisposed || _isConnecting) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.info('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delaySeconds = _reconnectDelaySeconds * _reconnectAttempts;

    AppLogger.info(
        'Attempting to reconnect in ${delaySeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  /// Dispose resources
  Future<void> dispose() async {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    await _eventController?.close();
    await _connectionStatusController?.close();
    _channel = null;
    _eventController = null;
    _connectionStatusController = null;
  }
}

