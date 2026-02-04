package com.bridge.backend.controller;

import com.bridge.backend.dto.UserListDto;
import com.bridge.backend.dto.UserCommentHistoryDto;
import com.bridge.backend.dto.UserDetailDto;
import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.User;
import com.bridge.backend.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
//@CrossOrigin(origins = "*")
//@CrossOrigin(allowedOriginPatterns = "*", allowCredentials = "true") ←バージョンが古くて使えないワイルドカード
//ここはデプロイした後に変わるかもしれないンゴ～
// @CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class UserController {
    
    @Autowired
    private UserService userService;

    @Autowired
    private com.bridge.backend.repository.IndustryRepository industryRepository;

    @GetMapping(value = "/list", produces = "application/json; charset=UTF-8")
    public ResponseEntity<List<UserListDto>> getUsers() {
        try {
            List<UserListDto> users = userService.getUsers();
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping(value = "/search", produces = "application/json; charset=UTF-8")
    public ResponseEntity<List<UserListDto>> searchUsers(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer type
    ) {
        return ResponseEntity.ok(userService.searchUsers(keyword, type));
    }
    
    @GetMapping("/{id}/comments")
    public List<UserCommentHistoryDto> getUserCommentHistory(@PathVariable Integer id) {
        return userService.getUserCommentHistory(id);
    }

    @PostMapping(produces = "application/json; charset=UTF-8")
    public ResponseEntity<?> createUser(@RequestBody UserDto userDto) {
        Map<String, Object> response = new java.util.HashMap<>();
        Map<String, String> errors = new java.util.HashMap<>();
        response.put("input", userDto);

        // --- 企業ユーザー(type=3)専用バリデーション ---
        if (userDto.getType() != null && userDto.getType() == 3) {
            // phone_number型・重複
            if (userDto.getPhoneNumber() == null || !(userDto.getPhoneNumber() instanceof String)) {
                errors.put("phone_number", "入力されていない項目か不正な入力値があります");
            } else {
                String phoneNumberStr = (String) userDto.getPhoneNumber();
                if (userService.existsByPhoneNumber(phoneNumberStr)) {
                    errors.put("phone_number", "すでに登録されている項目があります");
                }
            }
            // nickname型
            if (userDto.getNickname() == null || !(userDto.getNickname() instanceof String)) {
                errors.put("nickname", "入力されていない項目か不正な入力値があります");
            }
            // company_name型・長さ
            if (userDto.getCompanyName() == null || !(userDto.getCompanyName() instanceof String)) {
                errors.put("company_name", "入力されていない項目か不正な入力値があります");
            } else {
                String companyNameStr = (String) userDto.getCompanyName();
                if (companyNameStr.length() > 100) {
                    errors.put("company_name", "文字数が長すぎます");
                }
            }
            // password型・長さ
            if (userDto.getPassword() == null || !(userDto.getPassword() instanceof String)) {
                errors.put("password", "入力されていない項目か不正な入力値があります");
            } else {
                String passwordStr = (String) userDto.getPassword();
                if (passwordStr.length() > 255) {
                    errors.put("password", "文字数が長すぎます");
                }
            }
            // email型
            if (userDto.getEmail() == null || !(userDto.getEmail() instanceof String)) {
                errors.put("email", "入力されていない項目か不正な入力値があります");
            }
            // address型
            if (userDto.getCompanyAddress() == null || !(userDto.getCompanyAddress() instanceof String)) {
                errors.put("address", "入力されていない項目か不正な入力値があります");
            }
        } else {
            // --- 一般ユーザー用バリデーション（従来通り） ---
            // phone_number型・重複チェック
            if (userDto.getPhoneNumber() == null || !(userDto.getPhoneNumber() instanceof String)) {
                errors.put("phone_number", "入力されていない項目か不正な入力値があります");
            } else {
                String phoneNumberStr = (String) userDto.getPhoneNumber();
                if (userService.existsByPhoneNumber(phoneNumberStr)) {
                    errors.put("phone_number", "すでに登録されている項目があります");
                }
            }
            // nickname型・長さ
            if (userDto.getNickname() == null || !(userDto.getNickname() instanceof String)) {
                errors.put("nickname", "入力されていない項目か不正な入力値があります");
            } else {
                String nicknameStr = (String) userDto.getNickname();
                if (nicknameStr.length() > 100) {
                    errors.put("nickname", "文字数が長すぎます");
                }
            }
            // type型
            if (userDto.getType() == null) {
                errors.put("type", "入力されていない項目か不正な入力値があります");
            }
            // password型・長さ
            if (userDto.getPassword() == null || !(userDto.getPassword() instanceof String)) {
                errors.put("password", "入力されていない項目か不正な入力値があります");
            } else {
                String passwordStr = (String) userDto.getPassword();
                if (passwordStr.length() > 255) {
                    errors.put("password", "文字数が長すぎます");
                }
            }
            // email型
            if (userDto.getEmail() == null || !(userDto.getEmail() instanceof String)) {
                errors.put("email", "入力されていない項目か不正な入力値があります");
            }
        }

        if (!errors.isEmpty()) {
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        }
        try {
            ObjectMapper mapper = new ObjectMapper();
            System.out.println("受け取ったJSON: " + mapper.writeValueAsString(userDto));
            User created = userService.createUser(userDto);
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            e.printStackTrace();
            response.put("errors", Map.of("system", "Internal Server Error"));
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PutMapping("/{id}/delete")
    public ResponseEntity<Void> deleteAdmin(@PathVariable Integer id) {
        userService.deleteAdmin(id);
        return ResponseEntity.ok().build();
    }

    /**
     * IDに基づいてユーザー情報を取得するエンドポイント
     * 例: GET /api/users/1
     * @param id ユーザーID (LongまたはIntegerを使用している場合に合わせて調整)
     * @return UserDtoオブジェクト (存在しない場合は404 Not Found)
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getUserById(@PathVariable("id") String idStr) {
        Map<String, Object> response = new java.util.HashMap<>();
        Map<String, String> errors = new java.util.HashMap<>();
        response.put("input", idStr);
        Integer id = null;
        try {
            id = Integer.valueOf(idStr);
        } catch (NumberFormatException e) {
            errors.put("user_id", "不正な入力値です");
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        }
        try {
            UserDto userDto = userService.getUserById(id);
            if (userDto != null) {
                return ResponseEntity.ok(userDto);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
            }
        } catch (Exception e) {
            e.printStackTrace();
            errors.put("system", "Internal Server Error");
            response.put("errors", errors);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @GetMapping("/{id}/detail")
    public ResponseEntity<UserDetailDto> getUserDetail(@PathVariable Integer id) {
        return ResponseEntity.ok(userService.getUserDetail(id));
    }

    /**
     * ユーザーのトークン数を減らすエンドポイント
     * 例: PUT /api/users/{id}/deduct-tokens
     * @param id ユーザーID
     * @param tokensToDeduct 減らすトークン数
     * @return 更新後のUserオブジェクト
     */
    @PutMapping("/{id}/deduct-tokens")
    public ResponseEntity<?> deductTokens(@PathVariable("id") String idStr, @RequestParam int tokensToDeduct) {
        Map<String, Object> response = new java.util.HashMap<>();
        Map<String, String> errors = new java.util.HashMap<>();
        response.put("input", idStr);
        Integer id = null;
        try {
            id = Integer.valueOf(idStr);
        } catch (NumberFormatException e) {
            errors.put("message", "入力されていない項目か不正な入力値があります");
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        }
        try {
            User user = userService.deductUserTokens(id, tokensToDeduct);
            if (user == null) {
                errors.put("message", "ユーザーの登録情報がありません");
                response.put("errors", errors);
                response.put("data", null);
                return ResponseEntity.ok(response);
            }
            response.put("data", user);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            if (e.getMessage() != null && e.getMessage().contains("User not found")) {
                errors.put("message", "ユーザーの登録情報がありません");
                response.put("errors", errors);
                response.put("data", null);
                return ResponseEntity.ok(response);
            }
            e.printStackTrace();
            errors.put("message", "Internal Server Error");
            response.put("errors", errors);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PutMapping("/{id}/profile")
    public ResponseEntity<?> updateProfile(
            @PathVariable String id,
            @RequestBody Map<String, Object> body) {
        Map<String, Object> response = new java.util.HashMap<>();
        Map<String, String> errors = new java.util.HashMap<>();
        response.put("input", body);

        // id型チェック
        Integer userId = null;
        try {
            userId = Integer.valueOf(id);
        } catch (Exception e) {
            errors.put("message", "入力されていない項目か不正な入力値があります");
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        }

        // nickname型
        Object nicknameObj = body.get("nickname");
        if (!(nicknameObj instanceof String)) {
            errors.put("message", "入力されていない項目か不正な入力値があります");
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        }
        // email型
        Object emailObj = body.get("email");
        if (!(emailObj instanceof String)) {
            errors.put("message", "入力されていない項目か不正な入力値があります");
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        }
        // phone_number型
        Object phoneObj = body.get("phone_number");
        if (!(phoneObj instanceof String)) {
            errors.put("message", "入力されていない項目か不正な入力値があります");
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        }
        // industry_ids型
        Object industryIdsObj = body.get("industry_ids");
        if (!(industryIdsObj instanceof java.util.List)) {
            errors.put("message", "入力されていない項目か不正な入力値があります");
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        } else {
            for (Object o : (java.util.List<?>)industryIdsObj) {
                if (!(o instanceof Integer)) {
                    errors.put("message", "入力されていない項目か不正な入力値があります");
                    response.put("errors", errors);
                    return ResponseEntity.badRequest().body(response);
                }
            }
        }
        // image_path型
        Object imagePathObj = body.get("image_path");
        if (imagePathObj != null && !(imagePathObj instanceof String)) {
            errors.put("message", "入力されていない項目か不正な入力値があります");
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        }

        // email/phone_number重複チェック
        try {
            if (userService.existsByEmail((String)emailObj, userId)) {
                errors.put("message", "すでに登録されているアカウントがあるのでこの情報は使えません");
                response.put("errors", errors);
                return ResponseEntity.badRequest().body(response);
            }
            if (userService.existsByPhoneNumber((String)phoneObj, userId)) {
                errors.put("message", "すでに登録されているアカウントがあるのでこの情報は使えません");
                response.put("errors", errors);
                return ResponseEntity.badRequest().body(response);
            }
        } catch (Exception e) {
            errors.put("message", "Internal Server Error");
            response.put("errors", errors);
            return ResponseEntity.status(500).body(response);
        }

        // DB更新
        try {
            UserDto updatedUser = userService.updateUserProfile(userId, body);
            return ResponseEntity.ok(updatedUser);
        } catch (RuntimeException e) {
            if (e.getMessage() != null && e.getMessage().contains("User not found")) {
                errors.put("message", "ユーザーの登録情報がありません");
                response.put("errors", errors);
                return ResponseEntity.badRequest().body(response);
            }
            errors.put("message", "Internal Server Error");
            response.put("errors", errors);
            return ResponseEntity.status(500).body(response);
        }
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
    public ResponseEntity<?> deleteUser(@PathVariable("id") String idStr, HttpSession session) {
        Map<String, Object> response = new java.util.HashMap<>();
        Map<String, String> errors = new java.util.HashMap<>();
        response.put("input", idStr);
        Integer id = null;
        try {
            id = Integer.valueOf(idStr);
        } catch (NumberFormatException e) {
            errors.put("message", "入力されていない項目か不正な入力値があります");
            response.put("errors", errors);
            return ResponseEntity.badRequest().body(response);
        }
        try {
            // ===== ユーザー削除 =====
            userService.deleteUser(id);
            // ===== セッション削除 =====
            session.invalidate();
            response.put("data", "User deleted successfully and session invalidated");
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            if (e.getMessage() != null && e.getMessage().contains("User not found")) {
                errors.put("message", "ユーザーの登録情報がありません");
                response.put("errors", errors);
                response.put("data", null);
                return ResponseEntity.ok(response);
            }
            e.printStackTrace();
            errors.put("message", "Internal Server Error");
            response.put("errors", errors);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
    @PutMapping("/{id}/icon")
    public ResponseEntity<UserDto> updateIcon(
            @PathVariable Integer id,
            @RequestBody Map<String, Integer> body) {
        Integer photoId = body.get("photoId");
        if (photoId == null) {
            return ResponseEntity.badRequest().build();
        }
        UserDto updated = userService.updateUserIcon(id, photoId);
        return ResponseEntity.ok(updated);
    }

    /**
     * ログイン中のアカウントのサブスク確認・更新
     * サブスクテーブルからアカウントタイプを確認し、
     * 切れていた場合はusersテーブルを更新するエンドポイント
     */
    @PostMapping("/{id}/check-subscription")
    public ResponseEntity<Map<String, Object>> checkAndUpdateSubscriptionStatus(@PathVariable Integer id) {
        try {
            Map<String, Object> result = userService.checkAndUpdateSubscriptionStatus(id);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * ユーザーの現在のプランステータスのみを取得する
     * GET /api/users/{id}/plan-status
     */
    @GetMapping("/{id}/plan-status")
    public ResponseEntity<Map<String, String>> getUserPlanStatus(@PathVariable Integer id) {
        try {
            // UserServiceに作成するメソッドを呼び出す
            String planStatus = userService.getPlanStatusById(id);
            
            if (planStatus != null) {
                return ResponseEntity.ok(Map.of("planStatus", planStatus));
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
}