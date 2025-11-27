package com.bridge.backend.dto;

/**
 * PhotoDTO
 * 写真情報を転送するためのデータ転送オブジェクト
 */
public class PhotoDTO {
    private Integer id;
    private String photoPath;
    private Integer userId;

    public PhotoDTO() {
    }

    public PhotoDTO(Integer id, String photoPath, Integer userId) {
        this.id = id;
        this.photoPath = photoPath;
        this.userId = userId;
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getPhotoPath() {
        return photoPath;
    }

    public void setPhotoPath(String photoPath) {
        this.photoPath = photoPath;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }
}
