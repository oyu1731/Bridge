import 'package:flutter/material.dart';
import '22-interview-practice.dart';
import 'package:bridge/11-common/58-header.dart';

class AiTrainingListPage extends StatelessWidget {
  const AiTrainingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // メインメッセージ
            const Text(
              "AIと一緒にスキルを磨こう",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "～あなたの成長をサポートする学習モード～",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // 横並びボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ✅ 電話 → InterviewPractice に遷移
                _buildTrainingButton(
                  context,
                  icon: Icons.phone_in_talk,
                  label: "電話",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InterviewPractice(),
                      ),
                    );
                  },
                ),

                _buildTrainingButton(
                  context,
                  icon: Icons.record_voice_over,
                  label: "面接",
                  onTap: () {
                    Navigator.pushNamed(context, '/interview-training');
                  },
                ),
                _buildTrainingButton(
                  context,
                  icon: Icons.email_outlined,
                  label: "メール",
                  onTap: () {
                    Navigator.pushNamed(context, '/mail-training');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 円形ボタン（アイコン）
  Widget _buildTrainingButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 50, color: Colors.blueAccent),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
