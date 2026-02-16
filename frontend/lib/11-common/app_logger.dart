import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(Object? message) {
    if (!kDebugMode) return;
    debugPrint(message?.toString() ?? 'null');
  }

  static void e(Object? message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;

    final base = message?.toString() ?? 'null';
    if (error != null) {
      debugPrint('$base $error');
    } else {
      debugPrint(base);
    }

    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
