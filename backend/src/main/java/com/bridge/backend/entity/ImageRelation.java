package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "image_relations")
public class ImageRelation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "target_type", length = 20, nullable = false)
    private String targetType; // "COMPANY" または "ARTICLE"
    
    @Column(name = "target_id", nullable = false)
    private Long targetId;
    
    @Column(name = "image_path", length = 500, nullable = false)
    private String imagePath;
    
    @Column(name = "image_name", length = 255, nullable = false)
    private String imageName;
    
    @Column(name = "image_size")
    private Long imageSize; // バイト単位
    
    @Column(name = "mime_type", length = 50)
    private String mimeType; // image/jpeg, image/png など
    
    @Column(name = "display_order", nullable = false)
    private Integer displayOrder = 1;
    
    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted = false;
    
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    
    // デフォルトコンストラクタ
    public ImageRelation() {
    }
    
    // コンストラクタ
    public ImageRelation(String targetType, Long targetId, String imagePath, String imageName) {
        this.targetType = targetType;
        this.targetId = targetId;
        this.imagePath = imagePath;
        this.imageName = imageName;
        this.displayOrder = 1;
        this.isDeleted = false;
        this.createdAt = LocalDateTime.now();
    }
    
    // PrePersist - エンティティが初めて保存される前に実行される
    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
        if (this.isDeleted == null) {
            this.isDeleted = false;
        }
        if (this.displayOrder == null) {
            this.displayOrder = 1;
        }
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
    
    @Override
    public String toString() {
        return "ImageRelation{" +
                "id=" + id +
                ", targetType='" + targetType + '\'' +
                ", targetId=" + targetId +
                ", imagePath='" + imagePath + '\'' +
                ", imageName='" + imageName + '\'' +
                ", imageSize=" + imageSize +
                ", mimeType='" + mimeType + '\'' +
                ", displayOrder=" + displayOrder +
                ", isDeleted=" + isDeleted +
                ", createdAt=" + createdAt +
                '}';
    }
}