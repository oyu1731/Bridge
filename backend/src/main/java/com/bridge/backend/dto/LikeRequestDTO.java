package com.bridge.backend.dto;

/**
 * LikeRequestDTO
 * いいね操作のリクエストを表すDTOクラスです。
 */
public class LikeRequestDTO {
    
    private Integer userId;
    private boolean liking;
    
    // デフォルトコンストラクタ
    public LikeRequestDTO() {}
    
    // コンストラクタ
    public LikeRequestDTO(Integer userId, boolean liking) {
        this.userId = userId;
        this.liking = liking;
    }
    
    // Getters and Setters
    public Integer getUserId() {
        return userId;
    }
    
    public void setUserId(Integer userId) {
        this.userId = userId;
    }
    
    public boolean isLiking() {
        return liking;
    }
    
    public void setLiking(boolean liking) {
        this.liking = liking;
    }
}