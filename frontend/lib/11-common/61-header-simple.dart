import 'package:flutter/material.dart';

class BridgeHeaderSimple extends StatelessWidget
    implements PreferredSizeWidget {
  const BridgeHeaderSimple({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Bridgeロゴのみ
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'lib/01-images/Bridge-logo.png',
                  height: 50,
                  width: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Row(
                      children: [
                        Icon(Icons.home_outlined, color: Colors.blue, size: 40),
                        const SizedBox(width: 8),
                        Text(
                          'Bridge',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
