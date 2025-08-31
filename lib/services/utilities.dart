import 'dart:io';
import 'package:flutter/foundation.dart';

/// Simple filename sanitization to avoid illegal path characters and length issues.
String sanitizeFileName(String input, {String fallback = 'document', int maxLength = 50}) {
  var cleaned = input.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  if (cleaned.isEmpty) cleaned = fallback;
  if (cleaned.length > maxLength) cleaned = cleaned.substring(0, maxLength);
  return cleaned;
}

/// Lightweight logger wrapper (can be swapped later for a proper logging package).
void appLog(String message, {Object? error, StackTrace? stackTrace}) {
  if (kDebugMode) {
    // ignore: avoid_print
    print('[APP] $message${error != null ? ' | error=$error' : ''}');
    if (error != null && stackTrace != null) {
      // ignore: avoid_print
      print(stackTrace);
    }
  }
}

/// Returns a safe directory for storing app generated PDFs / metadata.
Future<Directory> getOrCreateAppDataDir(Directory base) async {
  final dir = Directory('${base.path}/sugam_pdf');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}
