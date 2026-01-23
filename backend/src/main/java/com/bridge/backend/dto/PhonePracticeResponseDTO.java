package com.bridge.backend.dto;

import java.time.Instant;

public class PhonePracticeResponseDTO {
    private String sessionId;
    private String message;
    private String memo;
    private String scenario;
    private Instant timestamp;
    private int turnCount;
    private boolean isConversationEnd;
    private String endReason;
    private PhonePracticeEvaluationDTO evaluation;

    // Getters and Setters
    public String getSessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getMemo() {
        return memo;
    }

    public void setMemo(String memo) {
        this.memo = memo;
    }

    public String getScenario() {
        return scenario;
    }

    public void setScenario(String scenario) {
        this.scenario = scenario;
    }

    public Instant getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Instant timestamp) {
        this.timestamp = timestamp;
    }

    public int getTurnCount() {
        return turnCount;
    }

    public void setTurnCount(int turnCount) {
        this.turnCount = turnCount;
    }

    public boolean getIsConversationEnd() {
        return isConversationEnd;
    }

    public void setIsConversationEnd(boolean conversationEnd) {
        isConversationEnd = conversationEnd;
    }

    public String getEndReason() {
        return endReason;
    }

    public void setEndReason(String endReason) {
        this.endReason = endReason;
    }

    public PhonePracticeEvaluationDTO getEvaluation() {
        return evaluation;
    }

    public void setEvaluation(PhonePracticeEvaluationDTO evaluation) {
        this.evaluation = evaluation;
    }
}