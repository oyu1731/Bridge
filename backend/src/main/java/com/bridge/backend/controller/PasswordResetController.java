package com.bridge.backend.controller;

import com.bridge.backend.service.PasswordResetService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/password")
//@CrossOrigin(origins = "*")
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
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
    public ResponseEntity<?> reset(@RequestBody Map<String, Object> body) {
        Object emailObj = body.get("email");
        Object otpObj = body.get("otp");
        Object newPasswordObj = body.get("newPassword");
        Map<String, Object> response = new HashMap<>();
        Map<String, String> errors = new HashMap<>();
        response.put("input", Map.of("email", emailObj, "otp", otpObj, "newPassword", newPasswordObj));

        // 型チェック
        if (!(emailObj instanceof String) || !(newPasswordObj instanceof String)) {
            errors.put("message", "メールアドレスかパスワードが違います");
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        }
        String email = (String) emailObj;
        String otp = otpObj != null ? otpObj.toString() : null;
        String newPassword = (String) newPasswordObj;
        if (email == null || otp == null || newPassword == null || 
            email.isBlank() || otp.isBlank() || newPassword.isBlank()) {
            errors.put("message", "必須項目が未入力です");
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        }
        try {
            Boolean userFound = passwordResetService.userExistsByEmail(email);
            if (!userFound) {
                errors.put("message", "ユーザーの登録情報がありません");
                response.put("errors", errors);
                return ResponseEntity.status(400).body(response);
            }
            boolean success = passwordResetService.resetPassword(email, otp, newPassword);
            if (!success) {
                errors.put("message", "OTPが無効または期限切れです");
                response.put("errors", errors);
                return ResponseEntity.status(400).body(response);
            }
            response.put("status", "password-updated");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            errors.put("message", "Internal Server Error");
            response.put("errors", errors);
            return ResponseEntity.status(500).body(response);
        }
    }
}
