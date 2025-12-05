package com.bridge.backend.controller;

import com.bridge.backend.entity.Subscription;
import com.bridge.backend.dto.SubscriptionResponseDto; // DTOをインポート
import com.bridge.backend.service.SubscriptionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/subscriptions")
public class SubscriptionController {

    private final SubscriptionService subscriptionService;

    @Autowired
    public SubscriptionController(SubscriptionService subscriptionService) {
        this.subscriptionService = subscriptionService;
    }

    /**
     * ユーザーIDから有効なサブスクリプション情報を取得する。
     * 500エラー（LocalDateTimeのシリアライズ問題）を避けるため、DTOに変換して返却する。
     * @param userId ユーザーID
     * @return SubscriptionResponseDto（JSON）または404
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getActiveSubscription(@PathVariable Integer userId) {
        // ServiceからSubscriptionエンティティを取得
        Optional<Subscription> subscriptionOpt = subscriptionService.getActiveSubscriptionByUserId(userId);

        if (subscriptionOpt.isPresent()) {
            // エンティティをDTOに変換
            SubscriptionResponseDto dto = new SubscriptionResponseDto(subscriptionOpt.get());
            // DTOを返却
            return ResponseEntity.ok(dto);
        } else {
            // 有効なサブスクリプションがない場合は404を返却（無料プランと判断）
            return ResponseEntity.status(404).body("Active subscription not found for user ID: " + userId);
        }
    }

    // 他のPostMappingなどはそのまま残す
    // ...
}