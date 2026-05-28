import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/queue_model.dart';
import '../models/vehicle_model.dart';
import '../models/location_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiService {
  final http.Client _client;
  final String _baseUrl;

  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<dynamic> _get(String endpoint) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> _post(String endpoint, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> _put(String endpoint, Map<String, dynamic> body) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    final message = body['message'] ?? 'Request failed';
    throw ApiException(message as String, statusCode: response.statusCode);
  }

  // Queue endpoints
  Future<List<Queue>> getQueues({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final data = await _get('${ApiEndpoints.queues}$query') as List<dynamic>;
    return data
        .map((json) => Queue.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Queue> getQueue(int id) async {
    final data = await _get(ApiEndpoints.queueById(id));
    return Queue.fromJson(data as Map<String, dynamic>);
  }

  Future<Queue> createQueue(Map<String, dynamic> payload) async {
    final data = await _post(ApiEndpoints.createQueue, payload);
    return Queue.fromJson(data as Map<String, dynamic>);
  }

  Future<Queue> updateQueueStatus(int id, String status,
      {String? notes}) async {
    final payload = <String, dynamic>{'status': status};
    if (notes != null) payload['notes'] = notes;
    final data = await _put(ApiEndpoints.updateStatus(id), payload);
    return Queue.fromJson(data as Map<String, dynamic>);
  }

  Future<List<QueueHistory>> getQueueHistory(int queueId) async {
    final data = await _get('${ApiEndpoints.queues}/$queueId/history')
        as List<dynamic>;
    return data
        .map((json) => QueueHistory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Vehicle endpoints
  Future<List<Vehicle>> getVehicles() async {
    final data = await _get(ApiEndpoints.vehicles) as List<dynamic>;
    return data
        .map((json) => Vehicle.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle?> getVehicleByPlate(String plate) async {
    final data =
        await _get('${ApiEndpoints.vehicles}?plate_number=$plate') as List;
    if (data.isEmpty) return null;
    return Vehicle.fromJson(data.first as Map<String, dynamic>);
  }

  Future<List<VehicleType>> getVehicleTypes() async {
    final data = await _get(ApiEndpoints.vehicleTypes) as List<dynamic>;
    return data
        .map((json) => VehicleType.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Location endpoints
  Future<List<Location>> getLocations() async {
    final data = await _get(ApiEndpoints.locations) as List<dynamic>;
    return data
        .map((json) => Location.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
