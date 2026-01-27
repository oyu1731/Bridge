import 'package:flutter/foundation.dart';

class ApiConfig {
  // 環境に応じてベースURLを切り替え
  static String get baseUrl {
    // kReleaseMode は Flutter がビルド（flutter build web）された時に自動で true になります
    if (kReleaseMode) {
      return 'https://api.bridge-tesg.com'; // ★本番（独自ドメイン）
    } else {
      return 'http://localhost:8080'; // ★開発（自分のPC）
    }
  }

  static String get baseWsUrl {
    if (kReleaseMode) {
      return 'wss://api.bridge-tesg.com';
    } else {
      return 'ws://localhost:8080';
    }
  }

  // 各APIのエンドポイント（ここに必要なものを追加していく）
  static String get articlesUrl => '$baseUrl/api/articles';
  static String get companiesUrl => '$baseUrl/api/companies';
  static String get photosUrl => '$baseUrl/api/photos';
  static String get notificationsUrl => '$baseUrl/api/notifications'; // ←追加
  static String get reportUrl => '$baseUrl/api/notice/report'; // ←追加
}
