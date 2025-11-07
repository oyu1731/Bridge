package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Subscriptionエンティティ
 * このクラスは、データベースの `subscriptions` テーブルに対応するエンティティです。
 * ユーザーのサブスクリプション情報を管理します。
 */
@Entity
@Table(name = "subscriptions")
public class Subscription {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // サブスクリプションID (主キー、自動生成)

    @Column(name = "user_id", nullable = false)
    private Integer userId; // ユーザーID

    @Column(name = "plan_name", nullable = false, length = 50)
    private String planName; // プラン名 (例: '無料', 'プレミアム')

    @Column(name = "start_date", nullable = false)
    private LocalDateTime startDate; // サブスクリプション開始日

    @Column(name = "end_date", nullable = false)
    private LocalDateTime endDate; // サブスクリプション終了日 (予定も含む)

    @Column(name = "is_plan_status", nullable = false)
    private Boolean isPlanStatus; // プランステータス: true=加入中、false=中断中

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt; // 作成日時

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public Subscription() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id サブスクリプションID
     * @param userId ユーザーID
     * @param planName プラン名
     * @param startDate 開始日
     * @param endDate 終了日
     * @param isPlanStatus プランステータス
     * @param createdAt 作成日時
     */
    public Subscription(Integer id, Integer userId, String planName, LocalDateTime startDate, LocalDateTime endDate, Boolean isPlanStatus, LocalDateTime createdAt) {
        this.id = id;
        this.userId = userId;
        this.planName = planName;
        this.startDate = startDate;
        this.endDate = endDate;
        this.isPlanStatus = isPlanStatus;
        this.createdAt = createdAt;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (planName == null || planName.isEmpty()) {
            planName = "無料";
        }
        if (isPlanStatus == null) {
            isPlanStatus = true;
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

    public String getPlanName() {
        return planName;
    }

    public void setPlanName(String planName) {
        this.planName = planName;
    }

    public LocalDateTime getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDateTime startDate) {
        this.startDate = startDate;
    }

    public LocalDateTime getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDateTime endDate) {
        this.endDate = endDate;
    }

    public Boolean getIsPlanStatus() {
        return isPlanStatus;
    }

    public void setIsPlanStatus(Boolean planStatus) {
        isPlanStatus = planStatus;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}