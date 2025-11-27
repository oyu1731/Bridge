package com.bridge.backend.controller;

import com.bridge.backend.entity.Chat;
import com.bridge.backend.repository.ChatRepository;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;





@RestController
@RequestMapping("/api/chat") // threads とは独立
//ここはデプロイした後に変わるかもしれないンゴ～
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class ChatController {

    private static final Logger logger = LoggerFactory.getLogger(ChatController.class);

    private final ChatRepository chatRepository;

    public ChatController(ChatRepository chatRepository) {
        this.chatRepository = chatRepository;
    }

    /**
     * 指定スレッドIDのメッセージ一覧取得
     */
    @GetMapping("/{threadId}")
    public List<Chat> getMessages(@PathVariable("threadId") Integer threadId) {
        System.out.println("getMessages が呼ばれました: threadId=" + threadId);

        List<Chat> messages = chatRepository.findByThreadIdOrderByCreatedAtAsc(threadId);
        System.out.println("DBから取得したメッセージ数: " + messages.size());

        // メッセージ内容も確認
        for (Chat chat : messages) {
            System.out.println("ChatID=" + chat.getId() + ", content=" + chat.getContent());
        }

        return messages;
    }

    /**
     * 指定スレッドIDにメッセージ投稿
     */
    @PostMapping("/{threadId}")
    public Chat postMessage(@PathVariable("threadId") Integer threadId, @RequestBody Chat chat) {
        chat.setThreadId(threadId);
        chat.setCreatedAt(java.time.LocalDateTime.now());
        Chat saved = chatRepository.save(chat);
        logger.info("postMessage: threadId={} savedId={}", threadId, saved.getId());
        return saved;
    }
}
