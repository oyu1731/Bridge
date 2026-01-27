package com.bridge.backend.service;

import com.bridge.backend.entity.Chat;
import com.bridge.backend.entity.ForumThread;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.ChatRepository;
import com.bridge.backend.repository.ThreadRepository;
import com.bridge.backend.repository.UserRepository;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

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
        //スレッドが存在するか
        ForumThread thread = threadRepository.findById(threadId)
            .orElseThrow(() ->
                new ResponseStatusException(HttpStatus.NOT_FOUND, "スレッドは存在しません")
            );
        //スレッドが論理削除されていないか
        if (Boolean.TRUE.equals(thread.getIsDeleted())) {
            throw new ResponseStatusException(HttpStatus.GONE, "THREAD_DELETED");
        }
        return chatRepository
            .findByThreadIdAndIsDeletedFalseOrderByCreatedAtAsc(threadId);
    }

    // スレッドにメッセージ投稿
    public Chat postMessage(Integer threadId, Chat chat) {
        //単体テストの時にここが発揮される
        System.out.println("========== postMessage START ==========");
        System.out.println("threadId: " + threadId);
        System.out.println("userId: " + chat.getUserId());
        System.out.println("content: " + chat.getContent());
        
        ForumThread thread = threadRepository.findById(threadId)
            .orElseThrow(() -> {
                System.out.println("❌ Thread NOT FOUND: threadId=" + threadId);
                return new ResponseStatusException(HttpStatus.GONE, "THREAD_DELETED");
            });
        
        System.out.println("✅ Thread FOUND: " + thread.getTitle());
        System.out.println("is_deleted: " + thread.getIsDeleted());

        if (chat.getUserId() == null) {
            System.out.println("❌ userId is null");
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "LOGIN_REQUIRED");
        }

        User user = userRepository.findById(chat.getUserId())
            .orElseThrow(() -> {
                System.out.println("❌ User NOT FOUND: userId=" + chat.getUserId());
                return new ResponseStatusException(HttpStatus.NOT_FOUND, "USER_NOT_FOUND");
            });
        
        System.out.println("✅ User FOUND: " + user.getNickname());
        
        chat.setThreadId(threadId);
        chat.setCreatedAt(LocalDateTime.now());
        Chat saved = chatRepository.save(chat);
        
        System.out.println("✅ Chat SAVED: chatId=" + saved.getId());

        //最終更新時間を変更
        thread.setLastUpdateDate(LocalDateTime.now());
        threadRepository.save(thread);
        
        System.out.println("========== postMessage END ==========");
        return saved;
    }

    // ユーザー情報取得
    public Map<String, String> getUserInfo(Integer userId) {
        User user = userRepository.findById(userId).orElse(null);
        Map<String, String> result = new HashMap<>();
        if (user != null) {
            result.put("nickname", user.getNickname());
            //result.put("email", user.getEmail());
            //nullでないならStringにする
            result.put("icon", user.getIcon() != null ? user.getIcon().toString() : null);
            result.put("type", user.getType() != null ? user.getType().toString() : null);
        } else {
            result.put("nickname", "Unknown");
        }
        return result;
    }
}
