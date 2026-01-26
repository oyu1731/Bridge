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

  static Future<List<Thread>> getReportedThreads() async {
    final url = Uri.parse(
      '${ThreadApiConfig.threadsUrl}/admin/threads/reported',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Thread.fromJson(e)).toList();
    } else {
      throw Exception('通報スレッド取得失敗');
    }
  }

  static Future<void> deleteThread(String threadId) async {
    final res = await http.put(
      Uri.parse('${ThreadApiConfig.threadsUrl}/admin/delete/$threadId'),
    );

    if (res.statusCode != 200) {
      throw Exception('スレッド削除失敗');
    }
  }
}

