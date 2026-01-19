package com.bridge.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class UserCommentHistoryDto {

    private String threadTitle;
    private String content;
    private String createdAt;

    @JsonProperty("isDeleted")
    private Boolean isDeleted;

    public UserCommentHistoryDto(String threadTitle, String content, String createdAt, boolean isDeleted) {
        this.threadTitle = threadTitle;
        this.content = content;
        this.createdAt = createdAt;
        this.isDeleted = isDeleted;
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

    public Boolean getIsDeleted() {
        return isDeleted;
    }
}
