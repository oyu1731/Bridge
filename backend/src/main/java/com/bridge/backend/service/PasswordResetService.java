package com.bridge.backend.service;

import com.bridge.backend.entity.User;
import com.bridge.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Random;

@Service
public class PasswordResetService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EmailService emailService;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private final Random random = new Random();

    /**
     * パスワードリセット要求（6桁OTP送信）
     */
    public void requestPasswordReset(String email) {
        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty()) {
            // 存在しない場合は黙って成功返し(セキュリティ的配慮)
            return;
        }
        User user = userOpt.get();

        // 6桁OTP生成
        String otp = String.format("%06d", random.nextInt(1000000));
        user.setOtp(otp);
        user.setOtpExpiresAt(LocalDateTime.now().plusMinutes(10)); // 10分有効
        userRepository.save(user);

        // OTP送信
        emailService.sendOtpMail(email, otp);
        System.out.println("[PasswordReset] OTP sent to: " + email);
    }

    /**
     * OTP検証
     */
    public boolean verifyOtp(String email, String otp) {
        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty()) return false;

        User user = userOpt.get();
        if (user.getOtp() == null || user.getOtpExpiresAt() == null) {
            return false;
        }
        if (!user.getOtp().equals(otp)) {
            return false;
        }
        if (user.getOtpExpiresAt().isBefore(LocalDateTime.now())) {
            return false; // 期限切れ
        }
        return true;
    }

    /**
     * パスワード更新（OTP検証済み前提）
     */
    public boolean resetPassword(String email, String otp, String newPassword) {
        if (!verifyOtp(email, otp)) {
            return false;
        }

        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty()) return false;

        User user = userOpt.get();
        String hashed = passwordEncoder.encode(newPassword);
        user.setPassword(hashed);
        // OTP削除（再利用防止）
        user.setOtp(null);
        user.setOtpExpiresAt(null);
        userRepository.save(user);

        System.out.println("[PasswordReset] Password updated for: " + email);
        return true;
    }
}
