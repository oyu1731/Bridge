package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Noticeエンティティ
 * このクラスは、データベースの `notices` テーブルに対応するエンティティです。
 * 通報情報を管理します。
 */
@Entity
@Table(name = "notices")
public class Notice {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // 通報ID (主キー、自動生成)

    @Column(name = "from_user_id", nullable = false)
    private Integer fromUserId; // 通報元ユーザーID

    @Column(name = "to_user_id", nullable = false)
    private Integer toUserId; // 通報先ユーザーID

    @Column(name = "type", nullable = false)
    private Integer type; // 通報タイプ: 1=スレッド、2=メッセージ

    @Column(name = "thread_id")
    private Integer threadId; // スレッドID (type=1の場合)

    @Column(name = "chat_id")
    private Integer chatId; // チャットID (type=2の場合)

    @Column(name = "created_at")
    private LocalDateTime createdAt; // 作成日時

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public Notice() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id 通報ID
     * @param fromUserId 通報元ユーザーID
     * @param toUserId 通報先ユーザーID
     * @param type 通報タイプ
     * @param threadId スレッドID
     * @param chatId チャットID
     * @param createdAt 作成日時
     */
    public Notice(Integer id, Integer fromUserId, Integer toUserId, Integer type, Integer threadId, Integer chatId, LocalDateTime createdAt) {
        this.id = id;
        this.fromUserId = fromUserId;
        this.toUserId = toUserId;
        this.type = type;
        this.threadId = threadId;
        this.chatId = chatId;
        this.createdAt = createdAt;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getFromUserId() {
        return fromUserId;
    }

    public void setFromUserId(Integer fromUserId) {
        this.fromUserId = fromUserId;
    }

    public Integer getToUserId() {
        return toUserId;
    }

    public void setToUserId(Integer toUserId) {
        this.toUserId = toUserId;
    }

    public Integer getType() {
        return type;
    }

    public void setType(Integer type) {
        this.type = type;
    }

    public Integer getThreadId() {
        return threadId;
    }

    public void setThreadId(Integer threadId) {
        this.threadId = threadId;
    }

    public Integer getChatId() {
        return chatId;
    }

    public void setChatId(Integer chatId) {
        this.chatId = chatId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}