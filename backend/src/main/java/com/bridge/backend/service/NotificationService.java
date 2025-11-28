package com.bridge.backend.service;

import com.bridge.backend.entity.Notification;
import com.bridge.backend.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    /**
     * お知らせ作成（DB保存） + バリデーション
     */
    public Notification createNotification(Notification notification) {
        // バリデーション
        if (notification.getTitle() == null || notification.getTitle().isEmpty()) {
            throw new IllegalArgumentException("件名は必須です");
        }
        if (notification.getContent() == null || notification.getContent().isEmpty()) {
            throw new IllegalArgumentException("内容は必須です");
        }

        Integer type = notification.getType();
        Integer userId = notification.getUserId();
        LocalDateTime reservationTime = notification.getReservationTime();

        // 個人宛のルール
        if (type == 8) {
            if (userId == null) {
                throw new IllegalArgumentException("個人宛の場合はユーザーIDが必要です");
            }
        } else {
            // type 1～7 の場合は userId は null
            notification.setUserId(null);
        }

        // 予約日時チェック
        if (reservationTime != null && reservationTime.isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("予約日時は過去に設定できません");
        }

        // 送信フラグ設定
        if (reservationTime == null) {
            notification.setSendFlagInt(2); // 即時送信
            notification.setSendFlag(LocalDateTime.now());
        } else {
            notification.setSendFlagInt(1); // 予約送信
        }

        return notificationRepository.save(notification);
    }
}
