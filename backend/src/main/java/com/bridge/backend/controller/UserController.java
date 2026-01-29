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
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
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
        // typeバリデーション
        Integer type = userDto.getType();
        if (type == null) {
            errors.put("type", "不正な入力値です");
        } else if (type != 1 && type != 2 && type != 3) {
            errors.put("type", "不正な入力値です");
        }

        // user_idバリデーション（idは自動採番のため、ここでは不要。もし外部から指定する場合はここでチェック）
        // target_idバリデーション（desiredIndustriesの各ID）
        if (userDto.getDesiredIndustries() != null) {
            for (Integer industryId : userDto.getDesiredIndustries()) {
                if (industryId == null) {
                    errors.put("target_id", "不正な入力値です");
                    break;
                }
                // DB存在チェック
                if (!industryRepository.existsById(industryId)) {
                    errors.put("target_id", "不正な入力値です");
                    break;
                }
            }
        }

        // user_idのDB存在チェック（もし外部から指定する場合のみ）
        // if (userDto.getId() != null && !userRepository.existsById(userDto.getId())) {
        //     errors.put("user_id", "不正な入力値です");
        // }

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
