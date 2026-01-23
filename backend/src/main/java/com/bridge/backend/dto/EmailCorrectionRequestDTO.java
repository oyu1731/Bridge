package com.bridge.backend.dto;

public class EmailCorrectionRequestDTO {
    private String originalEmail;

    public String getOriginalEmail() {
        return originalEmail;
    }

    public void setOriginalEmail(String originalEmail) {
        this.originalEmail = originalEmail;
    }

    @Override
    public String toString() {
        return "EmailCorrectionRequestDTO{" +
               "originalEmail='" + originalEmail + '\'' +
               '}';
    }
}