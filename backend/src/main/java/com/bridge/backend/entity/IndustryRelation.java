package com.bridge.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "industry_relations")
@Data
public class IndustryRelation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    // 1=希望業界
    private int type;

    // 登録されたユーザーID
    @Column(name = "user_id")
    private Integer userId;

    // industries テーブルの ID
    @Column(name = "target_id")
    private Integer targetId;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    // 手動でgetterとsetterを追加（Lombokが機能しない場合のため）
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public Integer getTargetId() {
        return targetId;
    }

    public void setTargetId(Integer targetId) {
        this.targetId = targetId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
