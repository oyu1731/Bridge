import 'dart:convert';
import 'package:bridge/11-common/api_config.dart';
import 'package:http/http.dart' as http;
import 'thread_model.dart';
import 'package:bridge/09-admin/admin_reported_thread.dart';

class ThreadApiClient {
  static Future<List<Thread>> getAllThreads() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/threads');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Thread.fromJson(json)).toList();
    } else {
      throw Exception('スレッド取得に失敗しました');
    }
  }

  static Future<List<AdminReportedThread>> getReportedThreads() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/threads/admin/threads/reported',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data
          .map((e) => AdminReportedThread.fromJson(e))
          .toList();
    } else {
      throw Exception('通報スレッド取得失敗');
    }
  }

  static Future<void> deleteThread(String threadId) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/threads/admin/delete/$threadId'),
    );

    if (res.statusCode != 200) {
      throw Exception('スレッド削除失敗');
    }
  }
}

