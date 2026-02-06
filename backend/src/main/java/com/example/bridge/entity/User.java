package com.example.bridge.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * ユーザーエンティティ
 */
@Entity
@Table(name = "users")
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    @Column(name = "nickname")
    private String nickname;
    
    @Column(name = "email", nullable = false, unique = true)
    private String email;
    
    @Column(name = "password")
    private String password;
    
    @Column(name = "phone_number")
    private String phoneNumber;
    
    @Column(name = "type", nullable = false)
    private Integer type;  // 1=学生, 2=社会人, 3=企業, 4=管理者
    
    @Column(name = "plan_status")
    private String planStatus;
    
    @Column(name = "is_withdrawn", nullable = false)
    private Boolean isWithdrawn;
    
    @Column(name = "society_history")
    private Integer societyHistory;
    
    @Column(name = "icon")
    private String icon;
    
    @Column(name = "company_id")
    private Integer companyId;  // 企業ユーザーの場合にセット
    
    @Column(name = "announcement_deletion")
    private Integer announcementDeletion;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    // Constructors
    public User() {}
    
    public User(String nickname, String email, String password, Integer type) {
        this.nickname = nickname;
        this.email = email;
        this.password = password;
        this.type = type;
        this.isWithdrawn = false;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }
    
    // Getters and Setters
    public Integer getId() {
        return id;
    }
    
    public void setId(Integer id) {
        this.id = id;
    }
    
    public String getNickname() {
        return nickname;
    }
    
    public void setNickname(String nickname) {
        this.nickname = nickname;
    }
    
    public String getEmail() {
        return email;
    }
    
    public void setEmail(String email) {
        this.email = email;
    }
    
    public String getPassword() {
        return password;
    }
    
    public void setPassword(String password) {
        this.password = password;
    }
    
    public String getPhoneNumber() {
        return phoneNumber;
    }
    
    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }
    
    public Integer getType() {
        return type;
    }
    
    public void setType(Integer type) {
        this.type = type;
    }
    
    public String getPlanStatus() {
        return planStatus;
    }
    
    public void setPlanStatus(String planStatus) {
        this.planStatus = planStatus;
    }
    
    public Boolean getIsWithdrawn() {
        return isWithdrawn;
    }
    
    public void setIsWithdrawn(Boolean isWithdrawn) {
        this.isWithdrawn = isWithdrawn;
    }
    
    public Integer getSocietyHistory() {
        return societyHistory;
    }
    
    public void setSocietyHistory(Integer societyHistory) {
        this.societyHistory = societyHistory;
    }
    
    public String getIcon() {
        return icon;
    }
    
    public void setIcon(String icon) {
        this.icon = icon;
    }
    
    public Integer getCompanyId() {
        return companyId;
    }
    
    public void setCompanyId(Integer companyId) {
        this.companyId = companyId;
    }
    
    public Integer getAnnouncementDeletion() {
        return announcementDeletion;
    }
    
    public void setAnnouncementDeletion(Integer announcementDeletion) {
        this.announcementDeletion = announcementDeletion;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
