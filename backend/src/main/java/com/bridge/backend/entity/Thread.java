package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Threadエンティティ
 * このクラスは、データベースの `threads` テーブルに対応するエンティティです。
 * スレッド情報を管理します。
 */
@Entity
@Table(name = "threads")
public class Thread {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // スレッドID (主キー、自動生成)

    @Column(name = "user_id", nullable = false)
    private Integer userId; // ユーザーID

    @Column(name = "title", nullable = false, length = 40)
    private String title; // スレッドタイトル

    @Column(name = "type", nullable = false)
    private Integer type; // スレッドタイプ: 1=公式、2=非公式

    @Column(name = "description", length = 255)
    private String description; // スレッド説明

    @Column(name = "entry_criteria", nullable = false)
    private Integer entryCriteria; // 参加条件: 1=全員、2=学生のみ、3=社会人のみ

    @Column(name = "industry", length = 20)
    private String industry; // 業界

    @Column(name = "last_update_date", nullable = false)
    private LocalDateTime lastUpdateDate; // 最終更新日時

    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted; // 削除済みフラグ

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt; // 作成日時

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public Thread() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id スレッドID
     * @param userId ユーザーID
     * @param title スレッドタイトル
     * @param type スレッドタイプ
     * @param description スレッド説明
     * @param entryCriteria 参加条件
     * @param industry 業界
     * @param lastUpdateDate 最終更新日時
     * @param isDeleted 削除済みフラグ
     * @param createdAt 作成日時
     */
    public Thread(Integer id, Integer userId, String title, Integer type, String description, Integer entryCriteria, String industry, LocalDateTime lastUpdateDate, Boolean isDeleted, LocalDateTime createdAt) {
        this.id = id;
        this.userId = userId;
        this.title = title;
        this.type = type;
        this.description = description;
        this.entryCriteria = entryCriteria;
        this.industry = industry;
        this.lastUpdateDate = lastUpdateDate;
        this.isDeleted = isDeleted;
        this.createdAt = createdAt;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        lastUpdateDate = LocalDateTime.now();
        if (isDeleted == null) {
            isDeleted = false;
        }
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public Integer getType() {
        return type;
    }

    public void setType(Integer type) {
        this.type = type;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Integer getEntryCriteria() {
        return entryCriteria;
    }

    public void setEntryCriteria(Integer entryCriteria) {
        this.entryCriteria = entryCriteria;
    }

    public String getIndustry() {
        return industry;
    }

    public void setIndustry(String industry) {
        this.industry = industry;
    }

    public LocalDateTime getLastUpdateDate() {
        return lastUpdateDate;
    }

    public void setLastUpdateDate(LocalDateTime lastUpdateDate) {
        this.lastUpdateDate = lastUpdateDate;
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public void setIsDeleted(Boolean deleted) {
        isDeleted = deleted;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}