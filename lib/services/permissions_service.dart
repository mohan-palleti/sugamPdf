import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Enum describing the outcome of a permission request.
enum PermissionRequestResult {
  granted,
  denied,
  permanentlyDenied,
  error,
}

class PermissionsService {
  // Public API (no BuildContext)
  static Future<PermissionRequestResult> requestCamera() async {
    final status = await Permission.camera.request();
    return _map(status);
  }

  static Future<PermissionRequestResult> requestImagesAccess() async {
    if (Platform.isAndroid) {
      final sdk = await _androidSdk();
      // For Android 13+ (SDK 33) we must request READ_MEDIA_IMAGES via Permission.photos
      if (sdk >= 33) {
        final status = await Permission.photos.request();
        return _map(status);
      }
      // For Android 12 and below still use legacy external storage (declared with maxSdkVersion)
      final legacy = await Permission.storage.request();
      return _map(legacy);
    } else if (Platform.isIOS) {
      final photos = await Permission.photos.request();
      return _map(photos);
    }
    return PermissionRequestResult.error;
  }

  // Mapping
  static PermissionRequestResult _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return PermissionRequestResult.granted;
    if (status.isPermanentlyDenied || status.isRestricted) return PermissionRequestResult.permanentlyDenied;
    if (status.isDenied) return PermissionRequestResult.denied;
    return PermissionRequestResult.error;
  }

  static Future<int> _androidSdk() async {
    if (!Platform.isAndroid) return 0;
    try {
      final os = Platform.operatingSystemVersion; // e.g. "Android 13 (SDK 33)" or "Android 14 (U)"
      final sdkMatch = RegExp(r'SDK\s+(\d+)').firstMatch(os);
      if (sdkMatch != null) {
        return int.parse(sdkMatch.group(1)!);
      }
      // Fallback: pick the largest integer in the string (likely the SDK)
      final nums = RegExp(r'\d+').allMatches(os).map((m) => int.parse(m.group(0)!)).toList();
      if (nums.isNotEmpty) {
        return nums.reduce((a, b) => a > b ? a : b);
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
