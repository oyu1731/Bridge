import 'dart:convert';
import 'package:http/http.dart' as http;
import '44-admin-mail-list.dart'; // NotificationData を使うなら

class AdminNotificationApi {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// 一覧取得
  static Future<List<NotificationData>> fetchAll() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/notifications'),
    );

    if (res.statusCode != 200) {
      throw Exception('一覧取得失敗');
    }

    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => NotificationData.fromJson(e)).toList();
  }

  /// 検索
  static Future<List<NotificationData>> search({
    String? title,
    String? type,
    String? category,
    DateTime? sendDate,
  }) async {
    final params = <String, String>{};

    if (title != null && title.isNotEmpty) params['title'] = title;
    if (type != null) params['type'] = type;
    if (category != null) params['category'] = category;
    if (sendDate != null) {
      params['sendFlag'] =
          '${sendDate.year}-${sendDate.month.toString().padLeft(2, '0')}-${sendDate.day.toString().padLeft(2, '0')}';
    }

    final uri = Uri.parse(
      '$baseUrl/api/notifications/search?${Uri(queryParameters: params).query}',
    );

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('検索失敗');
    }

    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => NotificationData.fromJson(e)).toList();
  }

  /// 削除
  static Future<void> delete(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/notifications/$id'),
    );

    if (res.statusCode != 204) {
      throw Exception('削除失敗');
    }
  }
}
