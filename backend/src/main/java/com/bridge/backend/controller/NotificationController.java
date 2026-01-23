package com.bridge.backend.controller;

import com.bridge.backend.dto.NotificationDto;
import com.bridge.backend.entity.Notification;
import com.bridge.backend.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = {"http://localhost:5000"}, allowCredentials = "true")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    @GetMapping
    public ResponseEntity<List<NotificationDto>> getNotifications() {
        try {
            List<NotificationDto> dtos = notificationService.getNotifications();
            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/search")
    public ResponseEntity<List<NotificationDto>> searchNotifications(
        @RequestParam(required = false) String title,
        @RequestParam(required = false) Integer type,
        @RequestParam(required = false) Integer category,
        @RequestParam(required = false) String sendFlag) {
            List<NotificationDto> result = notificationService.searchNotifications(title, type, category, sendFlag);
            return ResponseEntity.ok(result);
        }

    @PostMapping("/send")
    public ResponseEntity<?> sendNotification(@RequestBody NotificationDto dto) {
        try {
            Notification notification = new Notification();
            notification.setType(dto.getType());
            notification.setTitle(dto.getTitle());
            notification.setContent(dto.getContent());
            notification.setUserId(dto.getUserId());
            notification.setReservationTime(dto.getReservationTime());
            notification.setCategory(dto.getCategory());

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

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteNotifications(@PathVariable Integer id) {
        try {
            boolean deleted = notificationService.deleteNotifications(id);
            if (deleted) {
                return ResponseEntity.noContent().build();
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
