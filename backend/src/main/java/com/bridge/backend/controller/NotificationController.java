package com.bridge.backend.controller;

import com.bridge.backend.dto.NotificationDto;
import com.bridge.backend.entity.Notification;
import com.bridge.backend.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = {"http://localhost:5000"}, allowCredentials = "true")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    @PostMapping("/send")
    public ResponseEntity<?> sendNotification(@RequestBody NotificationDto dto) {
        try {
            Notification notification = new Notification();
            notification.setType(dto.getType());
            notification.setTitle(dto.getTitle());
            notification.setContent(dto.getContent());
            notification.setUserId(dto.getUserId());
            notification.setReservationTime(dto.getReservationTime());

            Notification saved = notificationService.createNotification(notification);
            return ResponseEntity.ok(saved);
        } catch (IllegalArgumentException e) {
            // バリデーション違反
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("サーバーエラー");
        }
    }
}
