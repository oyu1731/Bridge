package com.bridge.backend.dto;

public class PhonePracticeRequestDTO {
    private Long userId;
    private String userName;
    private String companyName;
    private String genre;
    private String callAtmosphere;
    private String difficulty;
    private String reviewType;
    private String scenario; // 追加
    private String memo;     // 追加

    // getter / setter
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }
    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }
    public String getGenre() { return genre; }
    public void setGenre(String genre) { this.genre = genre; }
    public String getCallAtmosphere() { return callAtmosphere; }
    public void setCallAtmosphere(String callAtmosphere) { this.callAtmosphere = callAtmosphere; }
    public String getDifficulty() { return difficulty; }
    public void setDifficulty(String difficulty) { this.difficulty = difficulty; }
    public String getReviewType() { return reviewType; }
    public void setReviewType(String reviewType) { this.reviewType = reviewType; }
    public String getScenario() { return scenario; } // 追加
    public void setScenario(String scenario) { this.scenario = scenario; } // 追加
    public String getMemo() { return memo; }     // 追加
    public void setMemo(String memo) { this.memo = memo; }     // 追加
}