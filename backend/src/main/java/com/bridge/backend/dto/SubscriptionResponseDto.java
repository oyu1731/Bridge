package com.bridge.backend.dto;

import com.bridge.backend.entity.Subscription;
import java.time.format.DateTimeFormatter;

/**
 * Subscription エンティティのデータをフロントエンドに安全に転送するためのDTO。
 * LocalDateTimeをISO 8601形式の文字列に変換することで、JSONシリアライズ時の500エラーを回避します。
 */
public class SubscriptionResponseDto {
    private Integer id;
    private Integer userId;
    private String planName;
    private String startDate; // String型に変換
    private String endDate;   // String型に変換
    private Boolean isPlanStatus;

    // LocalDateTimeを "yyyy-MM-dd'T'HH:mm:ss" 形式の文字列に変換するフォーマッター
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    public SubscriptionResponseDto() {
    }

    // Subscriptionエンティティを受け取り、DTOに変換するコンストラクタ
    public SubscriptionResponseDto(Subscription subscription) {
        this.id = subscription.getId();
        this.userId = subscription.getUserId();
        this.planName = subscription.getPlanName();
        // LocalDateTimeをStringにフォーマット
        this.startDate = subscription.getStartDate() != null ? subscription.getStartDate().format(FORMATTER) : null;
        this.endDate = subscription.getEndDate() != null ? subscription.getEndDate().format(FORMATTER) : null;
        this.isPlanStatus = subscription.getIsPlanStatus();
    }

    // Getters
    public Integer getId() { return id; }
    public Integer getUserId() { return userId; }
    public String getPlanName() { return planName; }
    public String getStartDate() { return startDate; }
    public String getEndDate() { return endDate; }
    public Boolean getIsPlanStatus() { return isPlanStatus; }

    // Setters (省略可だが、汎用性のために残す)
    public void setId(Integer id) { this.id = id; }
    public void setUserId(Integer userId) { this.userId = userId; }
    public void setPlanName(String planName) { this.planName = planName; }
    public void setStartDate(String startDate) { this.startDate = startDate; }
    public void setEndDate(String endDate) { this.endDate = endDate; }
    public void setIsPlanStatus(Boolean isPlanStatus) { this.isPlanStatus = isPlanStatus; }
}