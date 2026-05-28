# Key Implementation Snippets

## 1. WebSocketService - Connection Management

```dart
// lib/services/websocket_service.dart

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

  // Streams for events and connection status
  Stream<WebSocketEvent> get events => _eventController?.stream ?? Stream.empty();
  Stream<bool> get connectionStatus => _connectionStatusController?.stream ?? Stream.empty();
  bool get isConnected => _channel != null && !_isDisposed;

  // Connect with automatic reconnection
  Future<void> connect() async {
    if (_isConnecting || isConnected) return;
    _isConnecting = true;
    _eventController ??= StreamController<WebSocketEvent>.broadcast();
    _connectionStatusController ??= StreamController<bool>.broadcast();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;
      _reconnectAttempts = 0;
      _connectionStatusController?.add(true);
      
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

  // Exponential backoff reconnection
  void _attemptReconnect() {
    if (_isDisposed || _isConnecting) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.info('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delaySeconds = _reconnectDelaySeconds * _reconnectAttempts;
    AppLogger.info('Attempting to reconnect in ${delaySeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed) connect();
    });
  }
}
```

## 2. QueueProvider - Event Handling

```dart
// lib/providers/queue_provider.dart

class QueueProvider extends ChangeNotifier {
  final ApiService _apiService;
  late final WebSocketService _wsService;
  bool _wsConnected = false;

  QueueProvider(this._apiService) {
    _wsService = WebSocketService(url: AppConstants.wsUrl);
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    // Listen to connection status
    _wsService.connectionStatus.listen((isConnected) {
      _wsConnected = isConnected;
      notifyListeners();
      AppLogger.info(isConnected ? 'WebSocket connected' : 'WebSocket disconnected');
    });

    // Listen to events
    _wsService.events.listen((event) {
      _handleWebSocketEvent(event);
    });

    _wsService.connect();
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case WebSocketEventType.queueCreated:
        _handleQueueCreated(event.data);
        break;
      case WebSocketEventType.queueStatusChanged:
        _handleQueueStatusChanged(event.data);
        break;
      case WebSocketEventType.queueDeleted:
        _handleQueueDeleted(event.data);
        break;
    }
  }

  void _handleQueueCreated(Map<String, dynamic> data) {
    try {
      final queue = Queue.fromJson(data);
      _queues.insert(0, queue);
      notifyListeners();
      AppLogger.info('Queue created: ${queue.queueNumber}');
    } catch (e) {
      AppLogger.error('Error handling queue created event', e);
    }
  }

  void _handleQueueStatusChanged(Map<String, dynamic> data) {
    try {
      final queueId = data['id'] as int?;
      final newStatus = data['status'] as String?;
      if (queueId == null || newStatus == null) return;

      final index = _queues.indexWhere((q) => q.id == queueId);
      if (index != -1) {
        _queues[index] = _queues[index].copyWith(
          status: QueueStatusExtension.fromString(newStatus),
        );
      }

      if (_selectedQueue?.id == queueId) {
        _selectedQueue = _selectedQueue!.copyWith(
          status: QueueStatusExtension.fromString(newStatus),
        );
      }

      notifyListeners();
      AppLogger.info('Queue $queueId status changed to $newStatus');
    } catch (e) {
      AppLogger.error('Error handling queue status changed event', e);
    }
  }

  void _handleQueueDeleted(Map<String, dynamic> data) {
    try {
      final queueId = data['id'] as int?;
      if (queueId == null) return;

      _queues.removeWhere((q) => q.id == queueId);
      if (_selectedQueue?.id == queueId) {
        _selectedQueue = null;
      }

      notifyListeners();
      AppLogger.info('Queue $queueId deleted');
    } catch (e) {
      AppLogger.error('Error handling queue deleted event', e);
    }
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}
```

## 3. HomeScreen - Connection Indicator & Live Count

```dart
// lib/screens/home_screen.dart

bottomNavigationBar: Consumer<QueueProvider>(
  builder: (context, provider, _) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Queues: ${provider.queues.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provider.wsConnected ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                provider.wsConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  fontSize: 13,
                  color: provider.wsConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  },
),
```

## 4. QueueDetailScreen - Live Status Indicator

```dart
// lib/screens/queue_detail_screen.dart

Consumer<QueueProvider>(
  builder: (context, provider, _) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: provider.wsConnected ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            provider.wsConnected
                ? 'Live updates enabled'
                : 'Live updates disabled',
            style: TextStyle(
              fontSize: 12,
              color: provider.wsConnected ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  },
),
```

## 5. WebSocket Event Types

```dart
// lib/services/websocket_service.dart

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
```

## 6. Logger Utility

```dart
// lib/utils/logger.dart

class AppLogger {
  static const String _tag = 'CargoQueue';

  static void info(String message) {
    // ignore: avoid_print
    print('[$_tag] INFO: $message');
  }

  static void error(String message, [dynamic error]) {
    // ignore: avoid_print
    print('[$_tag] ERROR: $message${error != null ? ' - $error' : ''}');
  }

  static void debug(String message) {
    // ignore: avoid_print
    print('[$_tag] DEBUG: $message');
  }
}
```

## 7. Constants Configuration

```dart
// lib/config/constants.dart

class AppConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api';
  static const String apiBaseUrl = '$baseUrl$apiVersion';
  static const String wsUrl = 'ws://localhost:8000/app/cargo-queue-key';
}
```

## 8. Dependencies

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter
  
  # ... other dependencies ...
  
  # WebSocket client for real-time updates
  web_socket_channel: ^2.4.0
```

## Event Flow Diagram

```
Backend Event
    ↓
WebSocket Stream
    ↓
WebSocketService._handleMessage()
    ↓
WebSocketEvent.fromJson()
    ↓
_eventController.add(event)
    ↓
QueueProvider._handleWebSocketEvent()
    ↓
_handleQueueCreated/StatusChanged/Deleted()
    ↓
Update _queues list
    ↓
notifyListeners()
    ↓
UI Updates (HomeScreen, QueueDetailScreen)
```

## Testing Example

```dart
// Example: Testing queue.created event

// Backend sends:
{
  "event": "queue.created",
  "data": {
    "id": 1,
    "queue_number": "Q001",
    "status": "waiting",
    "vehicle": {...},
    "location": {...},
    ...
  }
}

// Result:
// 1. WebSocketService receives and parses event
// 2. QueueProvider._handleQueueCreated() called
// 3. New Queue object created from data
// 4. Queue inserted at top of _queues list
// 5. notifyListeners() triggers UI rebuild
// 6. HomeScreen shows updated queue count
// 7. New queue appears at top of list
```
