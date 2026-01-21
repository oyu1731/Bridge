import 'dart:convert';
import 'package:http/http.dart' as http;
import 'thread_model.dart';
import 'thread_api_config.dart';

class ThreadApiClient {
  static Future<List<Thread>> getAllThreads() async {
    final url = Uri.parse(ThreadApiConfig.threadsUrl);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Thread.fromJson(json)).toList();
    } else {
      throw Exception('スレッド取得に失敗しました');
    }
  }
}

