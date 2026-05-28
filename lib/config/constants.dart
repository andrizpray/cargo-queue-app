class AppConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api';
  static const String apiBaseUrl = '$baseUrl$apiVersion';
  static const String wsUrl = 'ws://localhost:8000/app/cargo-queue-key';
}

class ApiEndpoints {
  static const String queues = '/queues';
  static const String queueHistory = '/queue-history';
  static const String vehicles = '/vehicles';
  static const String vehicleTypes = '/vehicle-types';
  static const String locations = '/locations';
  static const String createQueue = '/queues';
  static const String updateQueueStatus = '/queues/{id}/status';

  static String queueById(int id) => '/queues/$id';
  static String updateStatus(int id) => '/queues/$id/status';
}
