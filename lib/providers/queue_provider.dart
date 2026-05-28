import 'package:flutter/foundation.dart';
import '../models/queue_model.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../config/constants.dart';
import '../utils/logger.dart';

class QueueProvider extends ChangeNotifier {
  final ApiService _apiService;
  late final WebSocketService _wsService;

  List<Queue> _queues = [];
  Queue? _selectedQueue;
  List<QueueHistory> _queueHistory = [];
  bool _isLoading = false;
  String? _error;
  String? _statusFilter;
  bool _wsConnected = false;

  QueueProvider(this._apiService) {
    _wsService = WebSocketService(url: AppConstants.wsUrl);
    _initializeWebSocket();
  }

  List<Queue> get queues => _queues;
  Queue? get selectedQueue => _selectedQueue;
  List<QueueHistory> get queueHistory => _queueHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;
  bool get wsConnected => _wsConnected;

  /// Initialize WebSocket connection and listeners
  void _initializeWebSocket() {
    // Listen to connection status changes
    _wsService.connectionStatus.listen((isConnected) {
      _wsConnected = isConnected;
      notifyListeners();
      if (isConnected) {
        AppLogger.info('WebSocket connected');
      } else {
        AppLogger.info('WebSocket disconnected');
      }
    });

    // Listen to WebSocket events
    _wsService.events.listen((event) {
      _handleWebSocketEvent(event);
    });

    // Connect to WebSocket
    _wsService.connect();
  }

  /// Handle incoming WebSocket events
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

  /// Handle queue.created event
  void _handleQueueCreated(Map<String, dynamic> data) {
    try {
      final queue = Queue.fromJson(data);
      // Add to the beginning of the list
      _queues.insert(0, queue);
      notifyListeners();
      AppLogger.info('Queue created: ${queue.queueNumber}');
    } catch (e) {
      AppLogger.error('Error handling queue created event', e);
    }
  }

  /// Handle queue.status-changed event
  void _handleQueueStatusChanged(Map<String, dynamic> data) {
    try {
      final queueId = data['id'] as int?;
      final newStatus = data['status'] as String?;

      if (queueId == null || newStatus == null) return;

      // Update in queues list
      final index = _queues.indexWhere((q) => q.id == queueId);
      if (index != -1) {
        final updatedQueue = _queues[index].copyWith(
          status: QueueStatusExtension.fromString(newStatus),
        );
        _queues[index] = updatedQueue;
      }

      // Update selected queue if it matches
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

  /// Handle queue.deleted event
  void _handleQueueDeleted(Map<String, dynamic> data) {
    try {
      final queueId = data['id'] as int?;

      if (queueId == null) return;

      // Remove from queues list
      _queues.removeWhere((q) => q.id == queueId);

      // Clear selected queue if it was deleted
      if (_selectedQueue?.id == queueId) {
        _selectedQueue = null;
      }

      notifyListeners();
      AppLogger.info('Queue $queueId deleted');
    } catch (e) {
      AppLogger.error('Error handling queue deleted event', e);
    }
  }

  Future<void> loadQueues({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _statusFilter = status;
      _queues = await _apiService.getQueues(status: status);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load queues. Check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadQueue(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedQueue = await _apiService.getQueue(id);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load queue details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Queue?> createQueue(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queue = await _apiService.createQueue(payload);
      _queues.insert(0, queue);
      notifyListeners();
      return queue;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = 'Failed to create queue.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateQueueStatus(int id, String status, {String? notes}) async {
    _error = null;

    try {
      final updated =
          await _apiService.updateQueueStatus(id, status, notes: notes);
      final index = _queues.indexWhere((q) => q.id == id);
      if (index != -1) {
        _queues[index] = updated;
      }
      if (_selectedQueue?.id == id) {
        _selectedQueue = updated;
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to update queue status.';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadQueueHistory(int queueId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _queueHistory = await _apiService.getQueueHistory(queueId);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load queue history.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectQueue(Queue queue) {
    _selectedQueue = queue;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}

