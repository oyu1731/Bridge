package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "companies")
public class Company {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "name", length = 150, nullable = false)
    private String name;
    
    @Column(name = "address", length = 255)
    private String address;
    
    @Column(name = "phone_number", length = 15)
    private String phoneNumber;
    
    @Column(name = "description", columnDefinition = "TEXT")
    private String description;
    
    @Column(name = "is_withdrawn", nullable = false)
    private Boolean isWithdrawn = false;
    
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "photo_id")
    private Long photoId;
    
    // デフォルトコンストラクタ
    public Company() {
    }
    
    // コンストラクタ
    public Company(String name, String address, String phoneNumber, String description) {
        this.name = name;
        this.address = address;
        this.phoneNumber = phoneNumber;
        this.description = description;
        this.isWithdrawn = false;
        this.createdAt = LocalDateTime.now();
    }
    
    // PrePersist - エンティティが初めて保存される前に実行される
    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
        if (this.isWithdrawn == null) {
            this.isWithdrawn = false;
        }
    }
    
    // Getter/Setter
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public String getAddress() {
        return address;
    }
    
    public void setAddress(String address) {
        this.address = address;
    }
    
    public String getPhoneNumber() {
        return phoneNumber;
    }
    
    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public Boolean getIsWithdrawn() {
        return isWithdrawn;
    }
    
    public void setIsWithdrawn(Boolean isWithdrawn) {
        this.isWithdrawn = isWithdrawn;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public Long getPhotoId() {
        return photoId;
    }
    
    public void setPhotoId(Long photoId) {
        this.photoId = photoId;
    }
    
    @Override
    public String toString() {
        return "Company{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", address='" + address + '\'' +
                ", phoneNumber='" + phoneNumber + '\'' +
                ", description='" + description + '\'' +
                ", isWithdrawn=" + isWithdrawn +
                ", createdAt=" + createdAt +
                ", photoId=" + photoId +
                '}';
    }
}