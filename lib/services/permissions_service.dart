import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  /// Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    return _handlePermissionStatus(status, 'Camera', context);
  }

  /// Request storage permissions based on platform and Android version
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+)
      if (await _isAndroid13OrHigher()) {
        // For Photos and Videos
        final photosStatus = await Permission.photos.request();
        final videosStatus = await Permission.videos.request();
        // For PDF files
        final documentStatus = await Permission.mediaLibrary.request();

        // All permissions must be granted
        return _handlePermissionStatus(photosStatus, 'Photos', context) &&
               _handlePermissionStatus(videosStatus, 'Videos', context) &&
               _handlePermissionStatus(documentStatus, 'Documents', context);
      } else {
        // For Android 12 or lower
        final status = await Permission.storage.request();
        return _handlePermissionStatus(status, 'Storage', context);
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return _handlePermissionStatus(status, 'Photos', context);
    }
    return false;
  }

  /// Check if device is running Android 13 (API level 33) or higher
  static Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkVersion();
      return sdkInt >= 33; // Android 13 is API level 33
    }
    return false;
  }

  /// Get Android SDK version
  static Future<int> _getAndroidSdkVersion() async {
    try {
      // This is a simple way to get SDK version, but in a real app,
      // you might use a method channel or a package like device_info_plus
      return int.parse(Platform.operatingSystemVersion.split(' ').last);
    } catch (e) {
      debugPrint('Failed to get Android SDK version: $e');
      return 0;
    }
  }

  /// Handle permission status and show dialog if needed
  static bool _handlePermissionStatus(
    PermissionStatus status,
    String permissionName,
    BuildContext context,
  ) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return true;
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
      case PermissionStatus.permanentlyDenied:
        _showPermissionDeniedDialog(permissionName, context);
        return false;
      default:
        return false;
    }
  }

  /// Show a dialog explaining why the permission is needed and how to enable it
  static void _showPermissionDeniedDialog(
    String permissionName,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
            'To use this feature, we need $permissionName permission. '
            'Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
