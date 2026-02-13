package com.bridge.backend.controller;

import com.bridge.backend.entity.Subscription;
import com.bridge.backend.repository.UserRepository;
import com.bridge.backend.dto.SubscriptionResponseDto;
import com.bridge.backend.service.SubscriptionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/subscriptions")
public class SubscriptionController {

    private final SubscriptionService subscriptionService;
    private final UserRepository userRepository;

    @Autowired
    public SubscriptionController(SubscriptionService subscriptionService, UserRepository userRepository) {
        this.subscriptionService = subscriptionService;
        this.userRepository = userRepository;
    }

    /**
     * 1. リアルタイムのプラン名取得
     */
    @GetMapping("/status/{userId}")
    public ResponseEntity<?> getSubscriptionStatus(@PathVariable(required = false) String userId) {
        Integer id = validateUserId(userId);
        if (id == null) {
            return ResponseEntity.badRequest().body("不正な入力値です");
        }

        try {
            return userRepository.findById(id)
                    .map(user -> {
                        String status = user.getPlanStatus();
                        return ResponseEntity.ok(status != null ? status : "無料");
                    })
                    .orElse(ResponseEntity.status(404).body("User Not Found"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("500 Internal Server Error");
        }
    }

    /**
     * 2. 有効なサブスクリプション詳細情報の取得
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getActiveSubscription(@PathVariable(required = false) String userId) {
        // 1. バリデーション（数値型チェック、null、空文字チェック）
        Integer id = validateUserId(userId);
        if (id == null) {
            return ResponseEntity.badRequest().body("不正な入力値です");
        }

        try {
            Optional<Subscription> subscriptionOpt = subscriptionService.getActiveSubscriptionByUserId(id);

            if (subscriptionOpt.isPresent()) {
                SubscriptionResponseDto dto = new SubscriptionResponseDto(subscriptionOpt.get());
                return ResponseEntity.ok(dto);
            } else {
                // 設計書の失敗時要件に合わせたメッセージ
                return ResponseEntity.status(404).body("現在サブスクは継続されていません");
            }
        } catch (Exception e) {
            // DB接続エラーなど
            return ResponseEntity.status(500).body("500 Internal Server Error");
        }
    }

    /**
     * IDバリデーション用共通メソッド
     */
    private Integer validateUserId(String userId) {
        if (userId == null || userId.trim().isEmpty()) {
            return null;
        }
        try {
            return Integer.parseInt(userId);
        } catch (NumberFormatException e) {
            return null;
        }
    }
}