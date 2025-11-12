import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GlobalActions {
  /// ユーザーセッション情報をSharedPreferencesから取得
  Future<Map<String, dynamic>?> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('current_user');

    if (jsonString != null) {
      final Map<String, dynamic> user = jsonDecode(jsonString);
      print('セッションから取得: $user');
      return user; // ✅ Map を返す
    } else {
      print('セッションにユーザー情報はありません');
      return null; // ✅ 見つからない場合は null
    }
  }
}
