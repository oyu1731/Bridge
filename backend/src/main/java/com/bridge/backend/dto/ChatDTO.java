package com.bridge.backend.dto;

public class ChatDTO {
    private Integer userId;
    private String content;
    private Integer photoId; // 写真が無い場合は null

    public ChatDTO() {}

    public ChatDTO(Integer userId, String content, Integer photoId) {
        this.userId = userId;
        this.content = content;
        this.photoId = photoId;
    }

    // getter / setter
    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Integer getPhotoId() {
        return photoId;
    }

    public void setPhotoId(Integer photoId) {
        this.photoId = photoId;
    }
}
