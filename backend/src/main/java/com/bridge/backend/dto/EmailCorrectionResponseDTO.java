package com.bridge.backend.dto;

public class EmailCorrectionResponseDTO {
    private String correctedEmail;
    private String correctionDetails;

    public EmailCorrectionResponseDTO() {
        // デフォルトコンストラクタ
    }

    public EmailCorrectionResponseDTO(String correctedEmail, String correctionDetails) {
        this.correctedEmail = correctedEmail;
        this.correctionDetails = correctionDetails;
    }

    public String getCorrectedEmail() {
        return correctedEmail;
    }

    public void setCorrectedEmail(String correctedEmail) {
        this.correctedEmail = correctedEmail;
    }

    public String getCorrectionDetails() {
        return correctionDetails;
    }

    public void setCorrectionDetails(String correctionDetails) {
        this.correctionDetails = correctionDetails;
    }

    @Override
    public String toString() {
        return "EmailCorrectionResponseDTO{" +
               "correctedEmail='" + correctedEmail + '\'' +
               ", correctionDetails='" + correctionDetails + '\'' +
               '}';
    }
}