import 'package:flutter/foundation.dart';
import '../models/queue_model.dart';
import '../services/api_service.dart';

class QueueProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Queue> _queues = [];
  Queue? _selectedQueue;
  List<QueueHistory> _queueHistory = [];
  bool _isLoading = false;
  String? _error;
  String? _statusFilter;

  QueueProvider(this._apiService);

  List<Queue> get queues => _queues;
  Queue? get selectedQueue => _selectedQueue;
  List<QueueHistory> get queueHistory => _queueHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;

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
}
