import 'package:flutter/foundation.dart';
import '../models/vehicle_model.dart';
import '../services/api_service.dart';

class VehicleProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Vehicle> _vehicles = [];
  List<VehicleType> _vehicleTypes = [];
  Vehicle? _scannedVehicle;
  bool _isLoading = false;
  String? _error;

  VehicleProvider(this._apiService);

  List<Vehicle> get vehicles => _vehicles;
  List<VehicleType> get vehicleTypes => _vehicleTypes;
  Vehicle? get scannedVehicle => _scannedVehicle;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicles = await _apiService.getVehicles();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load vehicles.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVehicleTypes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicleTypes = await _apiService.getVehicleTypes();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load vehicle types.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Vehicle?> lookupVehicleByPlate(String plate) async {
    _isLoading = true;
    _error = null;
    _scannedVehicle = null;
    notifyListeners();

    try {
      final vehicle = await _apiService.getVehicleByPlate(plate);
      _scannedVehicle = vehicle;
      notifyListeners();
      return vehicle;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to look up vehicle.';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearScannedVehicle() {
    _scannedVehicle = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
