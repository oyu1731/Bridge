import 'package:flutter/material.dart';
import 'dart:async';

// ===============================
// 決済完了画面（軽量版）
// ===============================
class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({Key? key}) : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );

    _checkController.forward();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _showConfetti = true);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _showConfetti = false);
      });
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Widget _buildConfettiLite() {
    if (!_showConfetti) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.6,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: List.generate(
              40,
              (i) => Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.primaries[i % Colors.primaries.length],
                  shape: i.isEven ? BoxShape.circle : BoxShape.rectangle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.teal.shade50, Colors.white],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: 1,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.teal.shade400,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _checkAnimation,
                          child: const SizedBox(width: 80, height: 80),
                          builder: (_, child) {
                            return CustomPaint(
                              painter: CheckmarkPainter(
                                progress: _checkAnimation.value,
                                color: Colors.white,
                                strokeWidth: 7,
                              ),
                              child: child,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        children: [
                          Text(
                            '決済が完了しました！',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ご登録いただきありがとうございます。\nプレミアムプランのすべての機能がご利用いただけます。',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home),
                          SizedBox(width: 8),
                          Text('ホームに戻る', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildConfettiLite(),
          ],
        ),
      ),
    );
  }
}

// ===============================
// 決済キャンセル画面（軽量版）
// ===============================
class PaymentCancelScreen extends StatelessWidget {
  const PaymentCancelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.red.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.red.shade400],
                    ),
                  ),
                  child: const Icon(Icons.close, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 40),
                Text(
                  '決済がキャンセルされました',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'お支払いは完了していません。\n再度お試しください。',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('ホームに戻る', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================
// チェックマークPainter（そのまま）
// ===============================
class CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CheckmarkPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(
      size.width * (0.2 + 0.2 * progress),
      size.height * (0.5 + 0.1 * progress),
    );
    path.lineTo(
      size.width * (0.3 + 0.5 * progress),
      size.height * (0.6 - 0.3 * progress),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
