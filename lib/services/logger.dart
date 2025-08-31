import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[LOG] $message${error != null ? ' | error=$error' : ''}');
      if (error != null && stackTrace != null) {
        // ignore: avoid_print
        print(stackTrace);
      }
    }
  }
}
