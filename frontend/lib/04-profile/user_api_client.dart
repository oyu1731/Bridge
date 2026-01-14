import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../06-company/api_config.dart';

class UserApiClient {
  static String get baseUrl => ApiConfig.baseUrl + '/api/users';

  static Future<Map<String, dynamic>?> updateIcon(int userId, int photoId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$userId/icon'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'photoId': photoId}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // セッション更新
      final prefs = await SharedPreferences.getInstance();
      final currentUserJson = prefs.getString('current_user');
      if (currentUserJson != null) {
        final currentUser = jsonDecode(currentUserJson);
        currentUser['icon'] = data['icon'];
        await prefs.setString('current_user', jsonEncode(currentUser));
      }
      return data;
    } else {
      throw Exception('Failed to update icon: ${response.statusCode}');
    }
  }
}