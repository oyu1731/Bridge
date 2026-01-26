import 'dart:convert';
import 'package:http/http.dart' as http;

class PostcodeJPApi {
  // static const String _endpoint = 'http://localhost:8080/api/postcode';
  static String get _endpoint {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return 'https://api.bridge-tesg.com/api/postcode'; // 本番環境
    } else {
      return 'http://localhost:8080/api/postcode'; // 開発環境
    }
  }

  /// 郵便番号から住所情報を取得（Spring Boot経由）
  static Future<Map<String, dynamic>?> fetchAddress(String postcode) async {
    final uri = Uri.parse('$_endpoint?postcode=$postcode');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('data')) {
        if (data['data'] is List && data['data'].isNotEmpty) {
          return data['data'][0];
        } else if (data['data'] is Map) {
          return data['data'];
        }
      }
      // エラーやヒットなしの場合
      return null;
    }
    return null;
  }
}
