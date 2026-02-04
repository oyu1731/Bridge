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
    public ResponseEntity<?> signin(@RequestBody Map<String, String> body, HttpSession session) {
        String email = body.get("email");
        String password = body.get("password");

        try {
            UserDto userDto = authService.signin(email, password);
            User user = userRepository.findByEmail(email).orElse(null);

            // ✅ セッションにユーザー情報を保存
            if (user != null) {
                _saveUserToSession(session, user);
                System.out.println("✅ サインイン: userId=" + user.getId() + ", email=" + email);
            }

            return ResponseEntity.ok(user);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", e.getMessage()));
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

            System.out.println("✅ ID指定セッション保存: userId=" + userId);

            // クライアント向けにはUserDtoを返す
            return ResponseEntity.ok(userDto);
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