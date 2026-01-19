package com.bridge.backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired(required = false) // プロパティ未設定時はnullになり得る
    private JavaMailSender mailSender;

    public void sendOtpMail(String to, String otp) {
        if (mailSender == null) {
            System.out.println("[EmailService] JavaMailSender未設定のためメール送信をスキップ: OTP=" + otp);
            return;
        }
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(to);
            message.setFrom(System.getenv().getOrDefault("MAIL_USER", "no-reply@bridge.local"));
            message.setSubject("Bridge パスワード再設定のご案内");
            message.setText("【Bridge】パスワード再設定用のワンタイムパスワードをお送りします。\n\n"
                    + "ワンタイムパスワード: " + otp + "\n\n"
                    + "このコードは10分間有効です。\n"
                    + "アプリのOTP入力画面でこのコードを入力してください。");
            mailSender.send(message);
            System.out.println("[EmailService] OTP送信成功: to=" + to);
        } catch (Exception ex) {
            System.out.println("[EmailService] 送信失敗: " + ex.getClass().getName() + " - " + ex.getMessage());
            ex.printStackTrace();
        }
    }
}
