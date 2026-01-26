import 'package:flutter/material.dart';
import 'package:bridge/10-payment/55-plan-status.dart';

/// サブスクリプション期限切れダイアログ
/// このダイアログはプラン確認画面への遷移ボタンのみを表示し、
/// 他の操作をできなくします（barrierDismissible = false）
class SubscriptionExpirationDialog extends StatelessWidget {
  final String endDate;
  final String userType;

  const SubscriptionExpirationDialog({
    Key? key,
    required this.endDate,
    required this.userType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 戻るボタンで閉じないようにする
      child: AlertDialog(
        title: const Text(
          'プラン期限が切れています',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    const TextSpan(text: 'ご利用のプラン期限は '),
                    TextSpan(
                      text: endDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const TextSpan(text: ' で切れています。\n\n'),
                    const TextSpan(text: 'サービスを継続利用するには、プランを更新する必要があります。\n\n'),
                    const TextSpan(
                      text: 'プラン確認画面からご契約ください。',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '期限切れ中は一部機能が制限されています',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // キャンセルボタンではなく、プラン確認ボタンのみ表示
          ElevatedButton(
            onPressed: () {
              // プラン確認画面に遷移
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PlanStatusScreen(userType: userType),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'プラン確認画面へ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 非同期で期限切れダイアログを表示
  /// context: BuildContext
  /// endDate: 期限切れ日時 (yyyy-MM-dd)
  /// userType: ユーザータイプ ('企業' など)
  static void showExpirationDialog(
    BuildContext context, {
    required String endDate,
    required String userType,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // ダイアログ外をタップして閉じられない
      builder:
          (context) => SubscriptionExpirationDialog(
            endDate: endDate,
            userType: userType,
          ),
    );
  }
}
