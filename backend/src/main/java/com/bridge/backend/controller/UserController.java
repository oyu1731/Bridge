package com.bridge.backend.controller;

import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.User;
import com.bridge.backend.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
//@CrossOrigin(origins = "*")
//@CrossOrigin(allowedOriginPatterns = "*", allowCredentials = "true") ←バージョンが古くて使えないワイルドカード
//ここはデプロイした後に変わるかもしれないンゴ～
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class UserController {
    
    @Autowired
    private UserService userService;

    @PostMapping
    public User createUser(@RequestBody UserDto userDto) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            System.out.println("受け取ったJSON: " + mapper.writeValueAsString(userDto));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return userService.createUser(userDto);
    }

    /**
     * IDに基づいてユーザー情報を取得するエンドポイント
     * 例: GET /api/users/1
     * @param id ユーザーID (LongまたはIntegerを使用している場合に合わせて調整)
     * @return UserDtoオブジェクト (存在しない場合は404 Not Found)
     */
    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUserById(@PathVariable("id") Integer id) {
        // --- デバッグ用ログ追加 ---
        System.out.println("[API] ユーザー情報取得リクエストを受信。ID: " + id);
        try {
            UserDto userDto = userService.getUserById(id);
            if (userDto != null) {
                System.out.println("[API] ユーザーID: " + id + " の情報を正常に取得しました。");
                return new ResponseEntity<>(userDto, HttpStatus.OK);
            } else {
                System.out.println("[API] ユーザーID: " + id + " は見つかりませんでした (404)。");
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            System.err.println("[API] ユーザーID: " + id + " の取得中にサーバーエラーが発生しました: " + e.getMessage());
            e.printStackTrace();
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * ユーザーのトークン数を減らすエンドポイント
     * 例: PUT /api/users/{id}/deduct-tokens
     * @param id ユーザーID
     * @param tokensToDeduct 減らすトークン数
     * @return 更新後のUserオブジェクト
     */
    @PutMapping("/{id}/deduct-tokens")
    public User deductTokens(@PathVariable Integer id, @RequestParam int tokensToDeduct) {
        return userService.deductUserTokens(id, tokensToDeduct);
    }

    @PutMapping("/{id}/profile")
    public ResponseEntity<UserDto> updateProfile(
            @PathVariable Integer id,
            @RequestBody UserDto userDto) {
        UserDto updatedUser = userService.updateUserProfile(id, userDto);
        return ResponseEntity.ok(updatedUser);
    }

    @PutMapping("/{id}/industries")
    public ResponseEntity<?> updateUserIndustries(
            @PathVariable Integer id,
            @RequestBody java.util.List<Integer> industryIds) {
        
        userService.updateUserIndustries(id, industryIds);
        return ResponseEntity.ok("Industries updated successfully");
    }

    @PutMapping("/{id}/password")
    public ResponseEntity<?> updatePassword(
            @PathVariable Integer id,
            @RequestBody Map<String, String> passwordMap) {
        try {
            String currentPassword = passwordMap.get("currentPassword");
            String newPassword = passwordMap.get("newPassword");
            userService.updatePassword(id, currentPassword, newPassword);
            return ResponseEntity.ok("Password updated successfully");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable Integer id, HttpSession session) {
        try {
            // ===== ユーザー削除 =====
            userService.deleteUser(id);

            // ===== セッション削除 =====
            session.invalidate();

            return ResponseEntity.ok("User deleted successfully and session invalidated");
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }
}