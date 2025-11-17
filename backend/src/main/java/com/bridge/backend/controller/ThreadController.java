package com.bridge.backend.controller;

import com.bridge.backend.entity.ForumThread;
import com.bridge.backend.repository.ThreadRepository;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.JsonProcessingException;


import java.util.List;

@RestController
@RequestMapping("/api/threads")
//@CrossOrigin(origins = "*") // FlutterからのCORS対応
//@CrossOrigin(allowedOriginPatterns = "*", allowCredentials = "true") ←バージョンが古くて使えないワイルドカード
//ここはデプロイした後に変わるかもしれないンゴ～
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class ThreadController {

    private static final Logger logger = LoggerFactory.getLogger(ThreadController.class);
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final ThreadRepository threadRepository;

    public ThreadController(ThreadRepository threadRepository) {
        this.threadRepository = threadRepository;
    }

    @GetMapping(produces = "application/json;charset=UTF-8")
    public List<ForumThread> getThreads() {
        List<com.bridge.backend.entity.ForumThread> threads = threadRepository.findByIsDeletedFalse();

        // ログ出力（取得確認用）
        try {
            logger.info("取得したThreadデータ(JSON): {}", objectMapper.writeValueAsString(threads));
        } catch (JsonProcessingException e) {
            logger.error("ThreadデータのJSON変換中にエラーが発生しました", e);
        }

        // 各スレッド情報の確認ログ
        for (ForumThread thread : threads) {
            logger.info("Thread ID={} | Title={} | Type={} | Deleted={}",
                    thread.getId(),
                    thread.getTitle(),
                    thread.getType(),
                    thread.getIsDeleted());
        }

        return threads;
    }
}