import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cargo_queue_app/services/api_service.dart';
import 'package:cargo_queue_app/providers/user_provider.dart';

void main() {
  group('UserProvider API Integration Tests', () {
    test('updatePhoneNumber should call PUT /api/users/{id}/phone', () async {
      int capturedUserId = 0;
      String? capturedPhone;
      
      final mockClient = MockClient((http.Request request) async {
        if (request.method == 'PUT' && 
            request.url.path == '/api/users/123/phone') {
          capturedUserId = 123;
          capturedPhone = jsonDecode(request.body)['phone'] as String;
          return http.Response('{"success": true}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient, baseUrl: 'http://localhost:8000/api');
      final userProvider = UserProvider(apiService);

      final result = await userProvider.updatePhoneNumber(123, '+1234567890');

      expect(result, true);
      expect(capturedUserId, 123);
      expect(capturedPhone, '+1234567890');
    });

    test('loadNotifications should call GET /api/notifications', () async {
      bool getNotificationsCalled = false;
      
      final mockClient = MockClient((http.Request request) async {
        if (request.method == 'GET' && 
            request.url.path == '/api/notifications') {
          getNotificationsCalled = true;
          return http.Response(
            jsonEncode({
              'whatsapp_enabled': true,
              'phone': '+1234567890'
            }), 
            200
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient, baseUrl: 'http://localhost:8000/api');
      final userProvider = UserProvider(apiService);

      await userProvider.loadNotifications();

      expect(getNotificationsCalled, true);
      expect(userProvider.notificationsEnabled, true);
      expect(userProvider.phoneNumber, '+1234567890');
    });

    test('updatePhoneNumber should return false on API error', () async {
      final mockClient = MockClient((http.Request request) async {
        if (request.method == 'PUT' && 
            request.url.path == '/api/users/123/phone') {
          return http.Response('{"message": "Invalid phone number"}', 400);
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient, baseUrl: 'http://localhost:8000/api');
      final userProvider = UserProvider(apiService);

      final result = await userProvider.updatePhoneNumber(123, 'invalid');

      expect(result, false);
      expect(userProvider.error, isNotNull);
    });
  });

  group('ApiService Tests', () {
    test('updateUserPhone should send correct request', () async {
      String? capturedBody;
      Uri? capturedUri;
      
      final mockClient = MockClient((http.Request request) async {
        capturedUri = request.url;
        capturedBody = request.body;
        return http.Response('{"success": true}', 200);
      });

      final apiService = ApiService(client: mockClient, baseUrl: 'http://localhost:8000/api');
      
      await apiService.updateUserPhone(456, '+9876543210');

      expect(capturedUri?.path, '/api/users/456/phone');
      expect(capturedBody, '{"phone":"+9876543210"}');
    });
  });
}
