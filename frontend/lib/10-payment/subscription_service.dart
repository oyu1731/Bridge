import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bridge/11-common/api_config.dart';

class SubscriptionService {
  /// ユーザーの有効なサブスクリプション情報を取得
  /// 期限が切れている場合は null を返す
  static Future<Map<String, dynamic>?> getActiveSubscription(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/user/$userId'),
      );

      print('[DEBUG_SUB] subscription API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('[DEBUG_SUB] subscription data: $data');

        // endDate を DateTime に変換して期限をチェック
        final endDateStr = data['endDate'];
        if (endDateStr != null) {
          final endDate = DateTime.parse(
            endDateStr.toString().substring(0, 10),
          );
          final now = DateTime.now();

          print('[DEBUG_SUB] endDate: $endDate, now: $now');

          // 期限が有効な場合のみ返す（本日を含む）
          if (endDate.isAfter(now) ||
              (endDate.year == now.year &&
                  endDate.month == now.month &&
                  endDate.day == now.day)) {
            print('[DEBUG_SUB] subscription is ACTIVE');
            return data;
          } else {
            print('[DEBUG_SUB] subscription is EXPIRED');
          }
        }
      } else {
        print('[DEBUG_SUB] subscription API error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('[DEBUG_SUB] サブスクリプション取得エラー: $e');
      return null;
    }
  }

  /// サブスクリプションが有効かどうかを確認
  /// 返り値: true = 有効、false = 期限切れまたはなし
  static Future<bool> isSubscriptionActive(int userId) async {
    final subscription = await getActiveSubscription(userId);
    return subscription != null;
  }

  /// サブスクリプションの期限を取得 (yyyy-MM-dd 形式)
  static Future<String?> getSubscriptionEndDate(int userId) async {
    final subscription = await getActiveSubscription(userId);
    if (subscription != null && subscription['endDate'] != null) {
      return subscription['endDate'].toString().substring(0, 10);
    }
    return null;
  }

  /// ユーザーが企業ユーザーかどうか確認
  /// 返り値: 企業ユーザーの場合 true
  static Future<bool> isCompanyUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('current_user');
      if (jsonString == null) return false;

      final userData = jsonDecode(jsonString);
      // type: 3 = 企業（本システムでは type=3 が企業）
      return userData['type'] == 3;
    } catch (e) {
      print('[DEBUG_SUB] ユーザータイプ確認エラー: $e');
      return false;
    }
  }

  /// 現在ログイン中のユーザーIDを取得
  static Future<int?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('current_user');
      if (jsonString == null) return null;

      final userData = jsonDecode(jsonString);
      return userData['id'] as int?;
    } catch (e) {
      print('ユーザーID取得エラー: $e');
      return null;
    }
  }
}
