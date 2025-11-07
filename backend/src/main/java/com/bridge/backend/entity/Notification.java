package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Notificationエンティティ
 * このクラスは、データベースの `notifications` テーブルに対応するエンティティです。
 * お知らせ情報を管理します。
 */
@Entity
@Table(name = "notifications")
public class Notification {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // お知らせID (主キー、自動生成)

    @Column(name = "type", nullable = false)
    private Integer type; // お知らせタイプ: 1=学生, 2=社会人, 3=企業, 4=学生×社会人, 5=学生×企業, 6=社会人×企業, 7=全員, 8=特定のユーザー

    @Column(name = "title", nullable = false, length = 50)
    private String title; // タイトル

    @Column(name = "content", nullable = false, length = 2000)
    private String content; // 内容

    @Column(name = "user_id")
    private Integer userId; // 特定のユーザーID (type=8の場合)

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt; // 作成日時

    @Column(name = "reservation_time")
    private LocalDateTime reservationTime; // 予約送信日時

    @Column(name = "send_flag")
    private LocalDateTime sendFlag; // 送信フラグが2になった時の日付

    @Column(name = "send_flag_int", nullable = false)
    private Integer sendFlagInt; // 送信フラグ: 1=予約, 2=送信完了

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public Notification() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id お知らせID
     * @param type お知らせタイプ
     * @param title タイトル
     * @param content 内容
     * @param userId 特定のユーザーID
     * @param createdAt 作成日時
     * @param reservationTime 予約送信日時
     * @param sendFlag 送信フラグが2になった時の日付
     * @param sendFlagInt 送信フラグ
     */
    public Notification(Integer id, Integer type, String title, String content, Integer userId, LocalDateTime createdAt, LocalDateTime reservationTime, LocalDateTime sendFlag, Integer sendFlagInt) {
        this.id = id;
        this.type = type;
        this.title = title;
        this.content = content;
        this.userId = userId;
        this.createdAt = createdAt;
        this.reservationTime = reservationTime;
        this.sendFlag = sendFlag;
        this.sendFlagInt = sendFlagInt;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (sendFlagInt == null) {
            sendFlagInt = 1; // デフォルトは予約
        }
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getType() {
        return type;
    }

    public void setType(Integer type) {
        this.type = type;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getReservationTime() {
        return reservationTime;
    }

    public void setReservationTime(LocalDateTime reservationTime) {
        this.reservationTime = reservationTime;
    }

    public LocalDateTime getSendFlag() {
        return sendFlag;
    }

    public void setSendFlag(LocalDateTime sendFlag) {
        this.sendFlag = sendFlag;
    }

    public Integer getSendFlagInt() {
        return sendFlagInt;
    }

    public void setSendFlagInt(Integer sendFlagInt) {
        this.sendFlagInt = sendFlagInt;
    }
}