package com.bridge.backend.service;

import com.bridge.backend.entity.Chat;
import com.bridge.backend.entity.ForumThread;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.ChatRepository;
import com.bridge.backend.repository.ThreadRepository;
import com.bridge.backend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

@Service
public class ChatService {

    private final ChatRepository chatRepository;
    private final ThreadRepository threadRepository;
    private final UserRepository userRepository; // 追加

    // UserRepository をコンストラクタで受け取る
    public ChatService(ChatRepository chatRepository, ThreadRepository threadRepository, UserRepository userRepository) {
        this.chatRepository = chatRepository;
        this.threadRepository = threadRepository;
        this.userRepository = userRepository; // 初期化
    }

    // スレッドIDでメッセージ取得
    public List<Chat> getMessagesByThreadId(Integer threadId) {
        return chatRepository.findByThreadIdOrderByCreatedAtAsc(threadId);
    }

    //id_deletedが0のメッセージを取得
    public List<Chat> getActiveChatsByThreadId(Integer threadId) {
        return chatRepository.findByThreadIdAndIsDeletedFalseOrderByCreatedAtAsc(threadId);
    }

    // スレッドにメッセージ投稿
    public Chat postMessage(Integer threadId, Chat chat) {
        chat.setThreadId(threadId);
        chat.setCreatedAt(LocalDateTime.now());
        Chat saved = chatRepository.save(chat);

        // スレッドの最終更新日時を更新
        ForumThread thread = threadRepository.findById(threadId)
                .orElseThrow(() -> new RuntimeException("スレッドが見つかりません"));
        thread.setLastUpdateDate(LocalDateTime.now());
        threadRepository.save(thread);

        return saved;
    }

    // ユーザー情報取得
    public Map<String, String> getUserInfo(Integer userId) {
        User user = userRepository.findById(userId).orElse(null);
        Map<String, String> result = new HashMap<>();
        if (user != null) {
            result.put("nickname", user.getNickname());
            result.put("email", user.getEmail());
        } else {
            result.put("nickname", "Unknown");
        }
        return result;
    }
}
