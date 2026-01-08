package com.bridge.backend.dto;

public class UserCommentHistoryDto {

    private String threadTitle;
    private String content;
    private String createdAt;

    public UserCommentHistoryDto(String threadTitle, String content, String createdAt) {
        this.threadTitle = threadTitle;
        this.content = content;
        this.createdAt = createdAt;
    }

    public String getThreadTitle() {
        return threadTitle;
    }

    public String getContent() {
        return content;
    }

    public String getCreatedAt() {
        return createdAt;
    }
}
