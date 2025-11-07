package com.bridge.backend.dto;

import com.bridge.backend.entity.ImageRelation;
import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.LocalDateTime;

public class ImageRelationDTO {
    private Long id;
    private String targetType;
    private Long targetId;
    private String imagePath;
    private String imageName;
    private Long imageSize;
    private String mimeType;
    private Integer displayOrder;
    private Boolean isDeleted;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    
    private String imageUrl; // フルURL（APIのベースURLと組み合わせて生成）
    
    // デフォルトコンストラクタ
    public ImageRelationDTO() {
    }
    
    // Entityから変換するコンストラクタ
    public ImageRelationDTO(ImageRelation imageRelation) {
        this.id = imageRelation.getId();
        this.targetType = imageRelation.getTargetType();
        this.targetId = imageRelation.getTargetId();
        this.imagePath = imageRelation.getImagePath();
        this.imageName = imageRelation.getImageName();
        this.imageSize = imageRelation.getImageSize();
        this.mimeType = imageRelation.getMimeType();
        this.displayOrder = imageRelation.getDisplayOrder();
        this.isDeleted = imageRelation.getIsDeleted();
        this.createdAt = imageRelation.getCreatedAt();
    }
    
    // 作成用コンストラクタ
    public ImageRelationDTO(String targetType, Long targetId, String imagePath, String imageName) {
        this.targetType = targetType;
        this.targetId = targetId;
        this.imagePath = imagePath;
        this.imageName = imageName;
        this.displayOrder = 1;
        this.isDeleted = false;
    }
    
    // EntityをDTOに変換するstaticメソッド
    public static ImageRelationDTO fromEntity(ImageRelation imageRelation) {
        return new ImageRelationDTO(imageRelation);
    }
    
    // EntityをDTOに変換（フルURL付き）
    public static ImageRelationDTO fromEntityWithUrl(ImageRelation imageRelation, String baseUrl) {
        ImageRelationDTO dto = new ImageRelationDTO(imageRelation);
        dto.setImageUrl(baseUrl + "/" + imageRelation.getImagePath());
        return dto;
    }
    
    // DTOをEntityに変換するメソッド
    public ImageRelation toEntity() {
        ImageRelation imageRelation = new ImageRelation();
        imageRelation.setId(this.id);
        imageRelation.setTargetType(this.targetType);
        imageRelation.setTargetId(this.targetId);
        imageRelation.setImagePath(this.imagePath);
        imageRelation.setImageName(this.imageName);
        imageRelation.setImageSize(this.imageSize);
        imageRelation.setMimeType(this.mimeType);
        imageRelation.setDisplayOrder(this.displayOrder != null ? this.displayOrder : 1);
        imageRelation.setIsDeleted(this.isDeleted != null ? this.isDeleted : false);
        imageRelation.setCreatedAt(this.createdAt);
        return imageRelation;
    }
    
    // Getter/Setter
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getTargetType() {
        return targetType;
    }
    
    public void setTargetType(String targetType) {
        this.targetType = targetType;
    }
    
    public Long getTargetId() {
        return targetId;
    }
    
    public void setTargetId(Long targetId) {
        this.targetId = targetId;
    }
    
    public String getImagePath() {
        return imagePath;
    }
    
    public void setImagePath(String imagePath) {
        this.imagePath = imagePath;
    }
    
    public String getImageName() {
        return imageName;
    }
    
    public void setImageName(String imageName) {
        this.imageName = imageName;
    }
    
    public Long getImageSize() {
        return imageSize;
    }
    
    public void setImageSize(Long imageSize) {
        this.imageSize = imageSize;
    }
    
    public String getMimeType() {
        return mimeType;
    }
    
    public void setMimeType(String mimeType) {
        this.mimeType = mimeType;
    }
    
    public Integer getDisplayOrder() {
        return displayOrder;
    }
    
    public void setDisplayOrder(Integer displayOrder) {
        this.displayOrder = displayOrder;
    }
    
    public Boolean getIsDeleted() {
        return isDeleted;
    }
    
    public void setIsDeleted(Boolean isDeleted) {
        this.isDeleted = isDeleted;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public String getImageUrl() {
        return imageUrl;
    }
    
    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
}