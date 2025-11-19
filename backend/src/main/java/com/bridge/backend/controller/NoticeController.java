package com.bridge.backend.controller;

import com.bridge.backend.entity.Notice;
import com.bridge.backend.repository.NoticeRepository;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.List; // ← これが必要

@RestController
@RequestMapping("/api/notice")
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class NoticeController {

    private final NoticeRepository noticeRepository;

    public NoticeController(NoticeRepository noticeRepository) {
        this.noticeRepository = noticeRepository;
    }

    @PostMapping("/report")
    public ResponseEntity<String> report(@RequestBody Notice notice) {
        try {
            // type が null ならスレッド通報に設定
            if (notice.getType() == null) {
                notice.setType(1);
            }

            // type に応じて必須項目をチェック
            if (notice.getType() == 1 && notice.getThreadId() == null) {
                return ResponseEntity.badRequest().body("threadId is required for thread report");
            }

            if (notice.getType() == 2 && (notice.getChatId() == null || notice.getToUserId() == null)) {
                return ResponseEntity.badRequest().body("chatId and toUserId are required for message report");
            }

            notice.setCreatedAt(LocalDateTime.now());
            noticeRepository.save(notice);

            return ResponseEntity.ok("Report submitted successfully");
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to submit report");
        }
    }

    @GetMapping("/list")
    public List<Notice> getAllReports() {
        return noticeRepository.findAll();
    }
}
