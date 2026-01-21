package com.bridge.backend.controller;

import com.bridge.backend.dto.AdminNoticeLogDto;
import com.bridge.backend.dto.NoticeDTO;
import com.bridge.backend.service.NoticeService;
import com.bridge.backend.entity.Notice;
import com.bridge.backend.repository.NoticeRepository;

import org.springframework.beans.factory.annotation.Autowired;
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

    @Autowired
    private NoticeService noticeService;

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

    @GetMapping
    public ResponseEntity<List<java.util.Map<String, Object>>> getNotices() {
        try {
            List<NoticeDTO> notices = noticeService.getNotices();

            List<java.util.Map<String, Object>> result = notices.stream().map(n -> {
                java.util.Map<String, Object> m = new java.util.HashMap<>();
                m.put("id", n.getId() != null ? n.getId().toString() : null);
                m.put("fromUserId", n.getFromUserId() != null ? n.getFromUserId().toString() : null);
                m.put("toUserId", n.getToUserId() != null ? n.getToUserId().toString() : null);
                m.put("threadId", n.getThreadId() != null ? n.getThreadId().toString() : null);
                m.put("chatId", n.getChatId() != null ? n.getChatId().toString() : null);
                m.put("createdAt", n.getCreatedAt() != null ? n.getCreatedAt().toString() : null);
                m.put("title", n.getTitle());
                m.put("content", n.getContent());
                return m;
            }).toList();

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/logs")
    public List<AdminNoticeLogDto> getLogs(){
        return noticeService.getLogs();
    }

    @PutMapping("/admin/delete/{noticeId}")
    public ResponseEntity<?> adminDelete(@PathVariable Integer noticeId){
        noticeService.adminDeleteByNotice(noticeId);
        return ResponseEntity.ok().build();
    }

}
