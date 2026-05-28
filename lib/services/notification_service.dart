import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _permissionGranted = false;
  bool _firstLaunchChecked = false;

  bool get permissionGranted => _permissionGranted;

  Future<bool> requestPermission() async {
    try {
      // Request notification permission
      final status = await Permission.notification.request();
      
      if (status.isGranted) {
        _permissionGranted = true;
        return true;
      } else if (status.isDenied) {
        _permissionGranted = false;
        return false;
      } else if (status.isPermanentlyDenied) {
        // Open app settings if permanently denied
        await openAppSettings();
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  Future<bool> checkPermission() async {
    try {
      final status = await Permission.notification.status;
      _permissionGranted = status.isGranted;
      return _permissionGranted;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  Future<void> requestPermissionOnFirstLaunch() async {
    if (_firstLaunchChecked) return;
    _firstLaunchChecked = true;

    final hasPermission = await checkPermission();
    if (!hasPermission) {
      await requestPermission();
    }
  }
}
