package com.bridge.backend.dto;

import java.time.Instant;
import java.util.List;
import java.util.Map;

public class PhonePracticeEvaluationDTO {
    private String sessionId;
    private int totalScore;
    private String summary;
    private List<String> keyStrengths;
    private List<String> criticalImprovements;
    private List<String> nextSteps;
    private Map<String, Object> detailedEvaluation;
    private int comprehensionScore; // 理解力
    private String comprehensionFeedback; // 理解力に関するフィードバック
    private int businessMannerScore; // ビジネスマナー
    private String businessMannerFeedback; // ビジネスマナーに関するフィードバック
    private int politenessScore; // 敬語
    private String politenessFeedback; // 敬語に関するフィードバック
    private int flowOfResponseScore; // 対応の流れ
    private String flowOfResponseFeedback; // 対応の流れに関するフィードバック
    private int scenarioAchievementScore; // シナリオ達成度
    private String scenarioAchievementFeedback; // シナリオ達成度に関するフィードバック
    private Instant evaluatedAt;

    // Getters and Setters
    public String getSessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }

    public int getTotalScore() {
        return totalScore;
    }

    public void setTotalScore(int totalScore) {
        this.totalScore = totalScore;
    }

    public String getSummary() {
        return summary;
    }

    public void setSummary(String summary) {
        this.summary = summary;
    }

    public List<String> getKeyStrengths() {
        return keyStrengths;
    }

    public void setKeyStrengths(List<String> keyStrengths) {
        this.keyStrengths = keyStrengths;
    }

    public List<String> getCriticalImprovements() {
        return criticalImprovements;
    }

    public void setCriticalImprovements(List<String> criticalImprovements) {
        this.criticalImprovements = criticalImprovements;
    }

    public List<String> getNextSteps() {
        return nextSteps;
    }

    public void setNextSteps(List<String> nextSteps) {
        this.nextSteps = nextSteps;
    }

    public Map<String, Object> getDetailedEvaluation() {
        return detailedEvaluation;
    }

    public void setDetailedEvaluation(Map<String, Object> detailedEvaluation) {
        this.detailedEvaluation = detailedEvaluation;
    }

    public int getComprehensionScore() {
        return comprehensionScore;
    }

    public void setComprehensionScore(int comprehensionScore) {
        this.comprehensionScore = comprehensionScore;
    }

    public String getComprehensionFeedback() {
        return comprehensionFeedback;
    }

    public void setComprehensionFeedback(String comprehensionFeedback) {
        this.comprehensionFeedback = comprehensionFeedback;
    }

    public int getBusinessMannerScore() {
        return businessMannerScore;
    }

    public void setBusinessMannerScore(int businessMannerScore) {
        this.businessMannerScore = businessMannerScore;
    }

    public String getBusinessMannerFeedback() {
        return businessMannerFeedback;
    }

    public void setBusinessMannerFeedback(String businessMannerFeedback) {
        this.businessMannerFeedback = businessMannerFeedback;
    }

    public int getPolitenessScore() {
        return politenessScore;
    }

    public void setPolitenessScore(int politenessScore) {
        this.politenessScore = politenessScore;
    }

    public String getPolitenessFeedback() {
        return politenessFeedback;
    }

    public void setPolitenessFeedback(String politenessFeedback) {
        this.politenessFeedback = politenessFeedback;
    }

    public int getFlowOfResponseScore() {
        return flowOfResponseScore;
    }

    public void setFlowOfResponseScore(int flowOfResponseScore) {
        this.flowOfResponseScore = flowOfResponseScore;
    }

    public String getFlowOfResponseFeedback() {
        return flowOfResponseFeedback;
    }

    public void setFlowOfResponseFeedback(String flowOfResponseFeedback) {
        this.flowOfResponseFeedback = flowOfResponseFeedback;
    }

    public int getScenarioAchievementScore() {
        return scenarioAchievementScore;
    }

    public void setScenarioAchievementScore(int scenarioAchievementScore) {
        this.scenarioAchievementScore = scenarioAchievementScore;
    }

    public String getScenarioAchievementFeedback() {
        return scenarioAchievementFeedback;
    }

    public void setScenarioAchievementFeedback(String scenarioAchievementFeedback) {
        this.scenarioAchievementFeedback = scenarioAchievementFeedback;
    }

    public Instant getEvaluatedAt() {
        return evaluatedAt;
    }

    public void setEvaluatedAt(Instant evaluatedAt) {
        this.evaluatedAt = evaluatedAt;
    }
}