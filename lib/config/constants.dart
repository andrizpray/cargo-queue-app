class AppConstants {
  // Change this to your server IP/domain when deploying
  static const String baseUrl = 'http://43.134.37.14:8000';
  static const String apiVersion = '/api';
  static const String apiBaseUrl = '$baseUrl$apiVersion';
  static const String wsUrl = 'ws://43.134.37.14:8000/app/cargo-queue-key';
}

class ApiEndpoints {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String queues = '/queues';
  static const String queueHistory = '/queue-history';
  static const String vehicles = '/vehicles';
  static const String vehicleTypes = '/vehicle-types';
  static const String locations = '/locations';
  static const String createQueue = '/queues';
  static const String updateQueueStatus = '/queues/{id}/status';
  static const String notifications = '/notifications';
  static const String userPhone = '/users/{id}/phone';

  static String queueById(int id) => '/queues/$id';
  static String updateStatus(int id) => '/queues/$id/status';
  static String updateUserPhone(int userId) => '/users/$userId/phone';
}
