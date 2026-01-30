import 'package:flutter/foundation.dart';

class ThreadApiConfig {
  // static const String baseUrl = 'http://localhost:8080';
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://api.bridge-tesg.com'; // ★本番（独自ドメイン）
    } else {
      return 'https://api.bridge-tesg.com'; // ★開発（自分のPC）
    }
  }

  static String get threadsUrl => '$baseUrl/api/threads';
}
