package com.bridge.backend.dto;

public class InterviewDTO {
    private Long userId;
    private String planStatus;
    private String questionType;
    private int questionCount;
    private String reviewType;
    private String industry;
    private String scale;
    private String atmosphere;

    // Getters and Setters
    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getPlanStatus() {
        return planStatus;
    }

    public void setPlanStatus(String planStatus) {
        this.planStatus = planStatus;
    }

    public String getQuestionType() {
        return questionType;
    }

    public void setQuestionType(String questionType) {
        this.questionType = questionType;
    }

    public int getQuestionCount() {
        return questionCount;
    }

    public void setQuestionCount(int questionCount) {
        this.questionCount = questionCount;
    }

    public String getReviewType() {
        return reviewType;
    }

    public void setReviewType(String reviewType) {
        this.reviewType = reviewType;
    }

    public String getIndustry() {
        return industry;
    }

    public void setIndustry(String industry) {
        this.industry = industry;
    }

    public String getScale() {
        return scale;
    }

    public void setScale(String scale) {
        this.scale = scale;
    }

    public String getAtmosphere() {
        return atmosphere;
    }

    public void setAtmosphere(String atmosphere) {
        this.atmosphere = atmosphere;
    }

    @Override
    public String toString() {
        return "InterviewDTO{" +
               "userId=" + userId +
               ", planStatus='" + planStatus + '\'' +
               ", questionType='" + questionType + '\'' +
               ", questionCount=" + questionCount +
               ", reviewType='" + reviewType + '\'' +
               ", industry='" + industry + '\'' +
               ", scale='" + scale + '\'' +
               ", atmosphere='" + atmosphere + '\'' +
               '}';
    }
}