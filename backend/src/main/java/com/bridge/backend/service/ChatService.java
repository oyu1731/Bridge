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
import org.springframework.transaction.annotation.Transactional;

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
            throw new ResponseStatusException(HttpStatus.GONE, "スレッドはすでに削除されています");
        }
        return chatRepository
            .findByThreadIdAndIsDeletedFalseOrderByCreatedAtAsc(threadId);
    }

    // スレッドにメッセージ投稿
    public Chat postMessage(Integer threadId, Chat chat) {
        //単体テストの時にここが発揮される
        ForumThread thread = threadRepository.findById(threadId)
            .orElseThrow(() ->
                new ResponseStatusException(HttpStatus.GONE, "入力されていない項目か不正な入力値があります")
            );
        if (Boolean.TRUE.equals(thread.getIsDeleted())) {
            throw new ResponseStatusException(
                HttpStatus.GONE,
                "このスレッドは現在表示できません"
            );
        }
        if (chat.getUserId() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "入力されていない項目か不正な入力値があります");
        }
        boolean noContent =
        chat.getContent() == null || chat.getContent().trim().isEmpty();
        boolean noPhoto = chat.getPhotoId() == null;
        if (noContent && noPhoto) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "テキストを入力するか写真を貼ってください"
            );
        }
        if (chat.getContent() == null) {
            chat.setContent("");
        }
        chat.setThreadId(threadId);
        chat.setCreatedAt(LocalDateTime.now());
        Chat saved = chatRepository.save(chat);

        //最終更新時間を変更
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
            //result.put("email", user.getEmail());
            //nullでないならStringにする
            result.put("icon", user.getIcon() != null ? user.getIcon().toString() : null);
            result.put("type", user.getType() != null ? user.getType().toString() : null);
        } else {
            result.put("nickname", "Unknown");
        }
        return result;
    }

    /**
     * スレッド内のチャットを物理削除
     */
    @Transactional
    public void deleteChatsByThreadId(Integer threadId) {
        chatRepository.deleteByThreadId(threadId);
    }
}
