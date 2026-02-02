import 'package:flutter/foundation.dart';

class ThreadApiConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://api.bridge-tesg.com'; // ★本番（独自ドメイン）
    } else {
      return 'http://localhost:5000'; // ★開発（自分のPC）
    }
  }

  static String get threadsUrl => '$baseUrl/api/threads';
}
