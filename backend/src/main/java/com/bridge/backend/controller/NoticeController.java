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
    public ResponseEntity<?> report(@RequestBody Notice notice) {

        // ★ 重複チェック
        boolean alreadyReported =
                noticeRepository.existsByFromUserIdAndChatId(
                        notice.getFromUserId(),
                        notice.getChatId()
                );

        if (alreadyReported) {
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body("このチャットではすでに通報済みです");
        }

        // ★ 通常の保存処理
        notice.setCreatedAt(LocalDateTime.now());
        if (notice.getType() == null) {
            notice.setType(1);
        }

        Notice saved = noticeRepository.save(notice);
        return ResponseEntity.ok(saved);
    }

    @GetMapping("/list")
    public List<Notice> getAllReports() {
        return noticeRepository.findAll();
    }
}
