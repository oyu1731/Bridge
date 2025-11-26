package com.bridge.backend.dto;

import java.io.Serializable;
import java.time.LocalDateTime;

public class SubscriptionDto implements Serializable {
    private Integer id;
    private Integer userId;
    private String planName;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private Boolean isPlanStatus;
    private LocalDateTime createdAt;

    // getter / setter
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
    public void setIsPlanStatus(Boolean isPlanStatus) {
        this.isPlanStatus = isPlanStatus;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
