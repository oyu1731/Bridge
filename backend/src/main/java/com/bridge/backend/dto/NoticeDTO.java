package com.bridge.backend.dto;

import java.time.LocalDateTime;

public class NoticeDTO {
    private Integer id;
    private Integer fromUserId;
    private Integer toUserId;
    private Integer threadId;
    private Integer chatId;
    private LocalDateTime createdAt;

    private String title;
    private String content;

    // デフォルトコンストラクタ
    public NoticeDTO() {
    }

    // 全フィールドのコンストラクタ
    public NoticeDTO(Integer id, Integer fromUserId, Integer toUserId, Integer threadId, Integer chatId, LocalDateTime createdAt, String title, String content) {
        this.id = id;
        this.fromUserId = fromUserId;
        this.toUserId = toUserId;
        this.threadId = threadId;
        this.chatId = chatId;
        this.createdAt = createdAt;
        this.title = title;
        this.content = content;
    }

    

    // --- ゲッターとセッター ---
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }
    
    public Integer getFromUserId() {
        return fromUserId;
    }

    public void setFromUserId(Integer fromUserId) {
        this.fromUserId = fromUserId;
    }

    public Integer getToUserId() {
        return toUserId;
    }

    public void setToUserId(Integer toUserId) {
        this.toUserId = toUserId;
    }

    public Integer getThreadId() {
        return threadId;
    }

    public void setThreadId(Integer threadId) {
        this.threadId = threadId;
    }

    public Integer getChatId() {
        return chatId;
    }

    public void setChatId(Integer chatId) {
        this.chatId = chatId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }
}
