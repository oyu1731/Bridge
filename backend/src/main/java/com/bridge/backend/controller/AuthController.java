package com.bridge.backend.controller;

import java.util.HashMap;

import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.UserRepository;
import com.bridge.backend.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpSession;
// import javax.servlet.http.HttpSession;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
//@CrossOrigin(origins = "*")
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/signin")
    public ResponseEntity<?> signin(@RequestBody Map<String, Object> body, HttpSession session) {
        Map<String, Object> response = new HashMap<>();
        Map<String, String> errors = new HashMap<>();
        Object emailObj = body.get("email");
        Object passwordObj = body.get("password");
        response.put("input", Map.of("email", emailObj, "password", passwordObj));

        // email型チェック
        if (!(emailObj instanceof String) || ((String) emailObj).trim().isEmpty()) {
            errors.put("email", "入力されていない項目か不正な入力値があります");
        }
        if (!(passwordObj instanceof String) || ((String) passwordObj).isEmpty()) {
            errors.put("password", "入力されていない項目か不正な入力値があります");
        }
        if (!errors.isEmpty()) {
            response.put("errors", errors);
            response.put("message", "入力されていない項目か不正な入力値があります");
            return ResponseEntity.badRequest().body(response);
        }
        String email = (String) emailObj;
        String password = (String) passwordObj;

        try {
            UserDto userDto = authService.signin(email, password);
            User user = userRepository.findByEmail(email).orElse(null);
            if (user == null) {
                errors.put("auth", "ユーザーの登録情報がありません");
                response.put("errors", errors);
                response.put("message", "ユーザーの登録情報がありません");
                response.put("input", Map.of("email", emailObj, "password", passwordObj));
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
            }
            _saveUserToSession(session, user);
            System.out.println("✅ サインイン: userId=" + user.getId() + ", email=" + email);

            // 必要な情報のみをcamelCaseで返却
            Map<String, Object> result = new HashMap<>();
            result.put("id", user.getId());
            result.put("type", user.getType());
            result.put("companyId", user.getCompanyId());
            result.put("planStatus", user.getPlanStatus());
            result.put("nickname", user.getNickname());
            result.put("email", user.getEmail());
            // 必要に応じて他の安全な情報も追加可

            return ResponseEntity.ok(result);
        } catch (IllegalArgumentException e) {
            String exceptionMessage = e.getMessage() == null ? "" : e.getMessage();
            if (exceptionMessage.contains("登録") || exceptionMessage.contains("見つかりません") || exceptionMessage.contains("退会")) {
                errors.put("auth", "ユーザーの登録情報がありません");
                response.put("errors", errors);
                response.put("message", "ユーザーの登録情報がありません");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
            }
            errors.put("auth", "メールアドレスかパスワードが違います");
            response.put("errors", errors);
            response.put("message", "メールアドレスかパスワードが違います");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        } catch (Exception e) {
            errors.put("system", "Internal Server Error");
            response.put("errors", errors);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    // ========================================
    // 💾 決済完了後のセッション保存用エンドポイント（ユーザーIDから取得・保存）
    // ========================================
    @PostMapping("/login-by-id/{userId}")
    public ResponseEntity<?> loginById(@PathVariable Integer userId, HttpSession session) {
        try {
            // AuthServiceから指定IDのユーザー情報を取得（サインイン時と同じ形式）
            UserDto userDto = authService.getUserById(userId);

            // ✅ セッションにユーザー情報を保存
            session.setAttribute("userId", userDto.getId());
            session.setAttribute("email", userDto.getEmail());
            session.setAttribute("nickname", userDto.getNickname());
            session.setAttribute("type", userDto.getType());
            session.setAttribute("planStatus", userDto.getPlanStatus());
            session.setAttribute("token", userDto.getToken());
            session.setAttribute("companyId", userDto.getCompanyId());

            System.out.println("✅ ID指定セッション保存: userId=" + userId);

            // クライアント向けには必要な情報のみをcamelCaseで返す
            Map<String, Object> result = new HashMap<>();
            result.put("id", userDto.getId());
            result.put("type", userDto.getType());
            result.put("companyId", userDto.getCompanyId());
            result.put("planStatus", userDto.getPlanStatus());
            result.put("nickname", userDto.getNickname());
            result.put("email", userDto.getEmail());
            return ResponseEntity.ok(result);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    // ========================================
    // 🔧 セッション保存ヘルパーメソッド
    // ========================================
    private void _saveUserToSession(HttpSession session, User user) {
        session.setAttribute("userId", user.getId());
        session.setAttribute("email", user.getEmail());
        session.setAttribute("nickname", user.getNickname());
        session.setAttribute("type", user.getType());
        session.setAttribute("companyId", user.getCompanyId());
        session.setAttribute("isAdmin", user.getType() == 4); // type=4が管理者
    }}