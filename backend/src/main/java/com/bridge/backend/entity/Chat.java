package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Chatエンティティ
 * このクラスは、データベースの `chats` テーブルに対応するエンティティです。
 * チャットメッセージ情報を管理します。
 */
@Entity
@Table(name = "chats")
public class Chat {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // チャットID (主キー、自動生成)

    @Column(name = "user_id", nullable = false)
    private Integer userId; // ユーザーID

    @Column(name = "content", nullable = false, length = 255)
    private String content; // チャット内容

    @Column(name = "thread_id", nullable = false)
    private Integer threadId; // スレッドID

    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted; // 削除済みフラグ

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt; // 削除日時

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt; // 作成日時

    @Column(name = "photo_id")
    private Integer photoId; // 写真ID

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public Chat() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id チャットID
     * @param userId ユーザーID
     * @param content チャット内容
     * @param threadId スレッドID
     * @param isDeleted 削除済みフラグ
     * @param deletedAt 削除日時
     * @param createdAt 作成日時
     * @param photoId 写真ID
     */
    public Chat(Integer id, Integer userId, String content, Integer threadId, Boolean isDeleted, LocalDateTime deletedAt, LocalDateTime createdAt, Integer photoId) {
        this.id = id;
        this.userId = userId;
        this.content = content;
        this.threadId = threadId;
        this.isDeleted = isDeleted;
        this.deletedAt = deletedAt;
        this.createdAt = createdAt;
        this.photoId = photoId;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
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

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Integer getThreadId() {
        return threadId;
    }

    public void setThreadId(Integer threadId) {
        this.threadId = threadId;
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public void setIsDeleted(Boolean deleted) {
        isDeleted = deleted;
    }

    public LocalDateTime getDeletedAt() {
        return deletedAt;
    }

    public void setDeletedAt(LocalDateTime deletedAt) {
        this.deletedAt = deletedAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Integer getPhotoId() {
        return photoId;
    }

    public void setPhotoId(Integer photoId) {
        this.photoId = photoId;
    }
}