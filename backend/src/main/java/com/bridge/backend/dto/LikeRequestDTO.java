package com.bridge.backend.dto;

/**
 * LikeRequestDTO
 * いいね操作のリクエストを表すDTOクラスです。
 */
public class LikeRequestDTO {
    
    private boolean liking;
    
    // デフォルトコンストラクタ
    public LikeRequestDTO() {}
    
    // コンストラクタ
    public LikeRequestDTO(boolean liking) {
        this.liking = liking;
    }
    
    // Getters and Setters
    public boolean isLiking() {
        return liking;
    }
    
    public void setLiking(boolean liking) {
        this.liking = liking;
    }
}