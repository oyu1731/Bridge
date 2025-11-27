package com.bridge.backend.controller;

import com.bridge.backend.dto.NoticeDTO;
import com.bridge.backend.service.NoticeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notices")
@CrossOrigin(origins = {"http://localhost:5000"}, allowCredentials = "true")
public class NoticeController {
    
    @Autowired
    private NoticeService noticeService;

    @GetMapping
    public ResponseEntity<List<NoticeDTO>> getNotices() {
        try {
            List<NoticeDTO> notices = noticeService.getNotices();
            return ResponseEntity.ok(notices);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
