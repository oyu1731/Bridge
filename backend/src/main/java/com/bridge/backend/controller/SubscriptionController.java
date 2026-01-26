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
@CrossOrigin(origins = "*")
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
     * 型を Integer userId に変更してリポジトリと一致させます
     */
    @GetMapping("/status/{userId}")
    public ResponseEntity<String> getSubscriptionStatus(@PathVariable Integer userId) {
        // UserRepository.findById(Integer) に合わせて Integer を渡す
        return userRepository.findById(userId)
                .map(user -> {
                    String status = user.getPlanStatus();
                    return ResponseEntity.ok(status != null ? status : "無料");
                })
                .orElse(ResponseEntity.status(404).body("User Not Found"));
    }

    /**
     * 2. 有効なサブスクリプション詳細情報の取得
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getActiveSubscription(@PathVariable Integer userId) {
        Optional<Subscription> subscriptionOpt = subscriptionService.getActiveSubscriptionByUserId(userId);

        if (subscriptionOpt.isPresent()) {
            SubscriptionResponseDto dto = new SubscriptionResponseDto(subscriptionOpt.get());
            return ResponseEntity.ok(dto);
        } else {
            return ResponseEntity.status(404).body("Active subscription not found");
        }
    }
}