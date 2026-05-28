import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService;
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _notificationsEnabled = false;
  String? _phoneNumber;

  UserProvider(this._apiService);

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get phoneNumber => _phoneNumber;

  void setUser(User user) {
    _user = user;
    _phoneNumber = user.phone;
    _notificationsEnabled = user.whatsappNotificationsEnabled;
    _saveUser();
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getNotifications();
      _notificationsEnabled = data['whatsapp_enabled'] as bool? ?? false;
      _phoneNumber = data['phone'] as String?;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load notifications settings';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePhoneNumber(int userId, String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateUserPhone(userId, phone);
      _phoneNumber = phone;
      if (_user != null) {
        _user = _user!.copyWith(phone: phone);
        _saveUser();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to update phone number';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleNotifications(int userId, bool enabled) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateUserPhone(userId, _phoneNumber ?? '');
      // Note: The API might need a separate endpoint for toggling notifications
      // This is a placeholder - adjust based on actual API
      _notificationsEnabled = enabled;
      if (_user != null) {
        _user = _user!.copyWith(whatsappNotificationsEnabled: enabled);
        _saveUser();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to update notification settings';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveUser() async {
    if (_user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_settings', jsonEncode(_user!.toJson()));
    } catch (e) {
      debugPrint('Error saving user settings: $e');
    }
  }

  Future<void> loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_settings');
      if (userJson != null) {
        final data = jsonDecode(userJson) as Map<String, dynamic>;
        _phoneNumber = data['phone'] as String?;
        _notificationsEnabled = data['whatsapp_notifications_enabled'] as bool? ?? false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user settings: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
