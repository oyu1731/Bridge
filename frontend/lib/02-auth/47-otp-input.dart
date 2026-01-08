import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../11-common/61-header-simple.dart';
import '48-password-reset.dart';

class OtpInputPage extends StatefulWidget {
  final String email;

  const OtpInputPage({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  _OtpInputPageState createState() => _OtpInputPageState();
}

class _OtpInputPageState extends State<OtpInputPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() {
        _errorMessage = 'ワンタイムパスワードを入力してください';
      });
      return;
    }
    if (otp.length != 6) {
      setState(() {
        _errorMessage = '6桁のワンタイムパスワードを入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/password/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        // OTP検証成功 → パスワード再設定画面へ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordResetPage(
              email: widget.email,
              otp: otp,
            ),
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data['error'] ?? 'ワンタイムパスワードが無効または期限切れです';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '通信エラーが発生しました';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeaderSimple(),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'パスワード再設定',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              Text(
                '入力いただいたメールアドレス宛に、',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF424242),
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '6桁のワンタイムパスワードを送信いたしました。',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF424242),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              Text(
                'ワンタイムパスワード',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF424242),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '6桁のコードを入力',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 24),
              Text(
                '※ ワンタイムパスワードは10分間有効です',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 120,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFFBDBDBD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        '戻る',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              '送信',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
