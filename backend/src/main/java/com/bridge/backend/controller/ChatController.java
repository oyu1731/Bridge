package com.bridge.backend.controller;
// import com.bridge.backend.entity.User;
import com.bridge.backend.entity.Chat;
import com.bridge.backend.repository.ChatRepository;
// import com.bridge.backend.entity.ForumThread;
// import com.bridge.backend.repository.ThreadRepository;
// import com.bridge.backend.repository.UserRepository;
// import com.bridge.backend.repository.ChatRepository;
import com.bridge.backend.service.ChatService;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
// import org.slf4j.Logger;
// import org.slf4j.LoggerFactory;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
// import org.springframework.stereotype.Service;
// import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class ChatController {

    private final ChatService chatService;
    private final ChatRepository chatRepository;

    public ChatController(ChatService chatService, ChatRepository chatRepository) {
        this.chatService = chatService;
        this.chatRepository = chatRepository;
    }

    //全取得
    @GetMapping("/{threadId}")
    public List<Chat> getMessages(@PathVariable Integer threadId) {
        return chatService.getMessagesByThreadId(threadId);
    }

    //is_deletedが0（論理削除されていない）メッセージのみ取得
    @GetMapping("/{threadId}/active")
    public List<Chat> getActiveChats(@PathVariable Integer threadId) {
        return chatService.getActiveChatsByThreadId(threadId);
    }

    //チャットを保存
    @PostMapping("/{threadId}")
    public Chat postMessage(@PathVariable Integer threadId, @RequestBody Chat chat) {
        System.out.println("========== ChatController.postMessage START ==========");
        System.out.println("Request received - threadId: " + threadId);
        System.out.println("Chat payload: userId=" + chat.getUserId() + ", content=" + chat.getContent());
        try {
            Chat result = chatService.postMessage(threadId, chat);
            System.out.println("========== ChatController.postMessage SUCCESS ==========");
            return result;
        } catch (Exception e) {
            System.out.println("❌ Exception in postMessage: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    //チャットのユーザー情報の取得（名前とか）
    @GetMapping("/user/{userId}")
    public Map<String, String> getUser(@PathVariable Integer userId) {
        return chatService.getUserInfo(userId);
    }

    // 管理者用：チャット論理削除
    @PutMapping("/{chatId}/delete")
    @Transactional
    public ResponseEntity<Void> deleteChat(@PathVariable Integer chatId) {
        chatRepository.softDelete(chatId);
        return ResponseEntity.ok().build();
    }
}






// @RestController
// @RequestMapping("/api/chat") // threads とは独立
// //ここはデプロイした後に変わるかもしれない～
// @CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
// public class ChatController {

//     private static final Logger logger = LoggerFactory.getLogger(ChatController.class);

//     private final ChatRepository chatRepository;
//     private final UserRepository userRepository;
//     private final ThreadRepository threadRepository;

//     public ChatController(ChatRepository chatRepository, UserRepository userRepository, ThreadRepository threadRepository) {
//         this.chatRepository = chatRepository;
//         this.userRepository = userRepository;
//         this.threadRepository = threadRepository;
//     }

//     /**
//      * 指定スレッドIDのメッセージ一覧取得
//      */
//     @GetMapping("/{threadId}")
//     public List<Chat> getMessages(@PathVariable("threadId") Integer threadId) {
//         System.out.println("getMessages が呼ばれました: threadId=" + threadId);

//         List<Chat> messages = chatRepository.findByThreadIdOrderByCreatedAtAsc(threadId);
//         System.out.println("DBから取得したメッセージ数: " + messages.size());

//         // メッセージ内容も確認
//         for (Chat chat : messages) {
//             System.out.println("ChatID=" + chat.getId() + ", content=" + chat.getContent());
//         }

//         return messages;
//     }

//     /**
//      * 指定スレッドIDにメッセージ投稿
//      */
//     @PostMapping("/{threadId}")
//     public Chat postMessage(@PathVariable("threadId") Integer threadId, @RequestBody Chat chat) {
//         // コメント情報セット
//         chat.setThreadId(threadId);
//         chat.setCreatedAt(java.time.LocalDateTime.now());
//         Chat saved = chatRepository.save(chat);
//         logger.info("postMessage: threadId={} savedId={}", threadId, saved.getId());

//         // スレッドの最終更新日時を更新
//         ForumThread thread = threadRepository.findById(threadId)
//                                 .orElseThrow(() -> new RuntimeException("スレッドが見つかりません"));
//         thread.setLastUpdateDate(java.time.LocalDateTime.now());
//         threadRepository.save(thread);

//         return saved;
//     }


//     // ユーザーidを指定して情報を取得（本来はUserContollerに書くべきだが競合が怖いので一旦こちらに記述by髙橋）
//     @GetMapping("/user/{userId}")
//     public Map<String, String> getUser(@PathVariable Integer userId) {
//         // userRepository を注入している前提
//         User user = userRepository.findById(userId).orElse(null);

//         Map<String, String> result = new HashMap<>();
//         if (user != null) {
//             result.put("nickname", user.getNickname());
//             result.put("email", user.getEmail()); // 必要なら他情報も追加可能
//         } else {
//             result.put("nickname", "Unknown");
//         }
//         return result;
//     }
// }
