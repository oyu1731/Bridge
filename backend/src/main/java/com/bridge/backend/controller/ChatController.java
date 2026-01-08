package com.bridge.backend.controller;
import com.bridge.backend.entity.User;
import com.bridge.backend.entity.Chat;
import com.bridge.backend.entity.ForumThread;
import com.bridge.backend.repository.ThreadRepository;
import com.bridge.backend.repository.UserRepository;
import com.bridge.backend.repository.ChatRepository;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.List;
import java.util.Map;
import java.util.HashMap;





@RestController
@RequestMapping("/api/chat") // threads とは独立
//ここはデプロイした後に変わるかもしれないンゴ～
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class ChatController {

    private static final Logger logger = LoggerFactory.getLogger(ChatController.class);

    private final ChatRepository chatRepository;
    private final UserRepository userRepository;
    private final ThreadRepository threadRepository;

    public ChatController(ChatRepository chatRepository, UserRepository userRepository, ThreadRepository threadRepository) {
        this.chatRepository = chatRepository;
        this.userRepository = userRepository;
        this.threadRepository = threadRepository;
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
        // コメント情報セット
        chat.setThreadId(threadId);
        chat.setCreatedAt(java.time.LocalDateTime.now());
        Chat saved = chatRepository.save(chat);
        logger.info("postMessage: threadId={} savedId={}", threadId, saved.getId());

        // スレッドの最終更新日時を更新
        ForumThread thread = threadRepository.findById(threadId)
                                .orElseThrow(() -> new RuntimeException("スレッドが見つかりません"));
        thread.setLastUpdateDate(java.time.LocalDateTime.now());
        threadRepository.save(thread);

        return saved;
    }


    // ユーザーidを指定して情報を取得（本来はUserContollerに書くべきだが競合が怖いので一旦こちらに記述by髙橋）
    @GetMapping("/user/{userId}")
    public Map<String, String> getUser(@PathVariable Integer userId) {
        // userRepository を注入している前提
        User user = userRepository.findById(userId).orElse(null);

        Map<String, String> result = new HashMap<>();
        if (user != null) {
            result.put("nickname", user.getNickname());
            result.put("email", user.getEmail()); // 必要なら他情報も追加可能
        } else {
            result.put("nickname", "Unknown");
        }
        return result;
    }
}
