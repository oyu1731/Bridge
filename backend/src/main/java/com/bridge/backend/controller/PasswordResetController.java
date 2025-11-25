package com.bridge.backend.controller;

import com.bridge.backend.service.PasswordResetService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/password")
@CrossOrigin(origins = "*")
public class PasswordResetController {

    @Autowired
    private PasswordResetService passwordResetService;

    /**
     * パスワードリセット要求 (6桁OTP送信)
     */
    @PostMapping("/forgot")
    public ResponseEntity<?> forgot(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "メールアドレスが未入力です"));
        }
        passwordResetService.requestPasswordReset(email);
        // 常に成功を返す(存在するかどうか漏らさない)
        return ResponseEntity.ok(Map.of("status", "ok"));
    }

    /**
     * OTP検証
     */
    @PostMapping("/verify-otp")
    public ResponseEntity<?> verifyOtp(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        String otp = body.get("otp");
        if (email == null || otp == null || email.isBlank() || otp.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "メールアドレスまたはOTPが未入力です"));
        }
        boolean valid = passwordResetService.verifyOtp(email, otp);
        if (!valid) {
            return ResponseEntity.status(400).body(Map.of("error", "OTPが無効または期限切れです"));
        }
        return ResponseEntity.ok(Map.of("status", "valid"));
    }

    /**
     * パスワード更新
     */
    @PostMapping("/reset")
    public ResponseEntity<?> reset(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        String otp = body.get("otp");
        String newPassword = body.get("newPassword");
        if (email == null || otp == null || newPassword == null || 
            email.isBlank() || otp.isBlank() || newPassword.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "必須項目が未入力です"));
        }
        boolean success = passwordResetService.resetPassword(email, otp, newPassword);
        if (!success) {
            return ResponseEntity.status(400).body(Map.of("error", "OTPが無効または期限切れです"));
        }
        return ResponseEntity.ok(Map.of("status", "password-updated"));
    }
}
