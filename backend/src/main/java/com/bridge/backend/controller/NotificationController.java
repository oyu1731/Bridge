package com.bridge.backend.controller;

import com.bridge.backend.dto.NotificationDto;
import com.bridge.backend.entity.Notification;
import com.bridge.backend.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = "*")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    @PostMapping("/send")
    public Notification sendNotification(@RequestBody NotificationDto dto) {
        Notification notification = new Notification();
        notification.setType(dto.getType());
        notification.setTitle(dto.getTitle());
        notification.setContent(dto.getContent());
        notification.setUserId(dto.getUserId());

        // 予約送信日時（nullなら即時扱い）
        notification.setReservationTime(dto.getReservationTime());

        // 送信フラグ: 1=予約, 2=送信完了（フロントから送信タイミングで判定）
        if (dto.getReservationTime() == null) {
            notification.setSendFlagInt(2); // 即時送信
            notification.setSendFlag(java.time.LocalDateTime.now());
        } else {
            notification.setSendFlagInt(1); // 予約
        }

        return notificationService.createNotification(notification);
    }
}
