package com.bridge.backend.dto;

import java.util.Map;

public class AnswerDTO {
    private String question;
    private String answer;
    private Map<String, String> companyInfo;
    private String questionType; // 面接タイプを追加

    public AnswerDTO() {
    }

    public AnswerDTO(String question, String answer, Map<String, String> companyInfo, String questionType) {
        this.question = question;
        this.answer = answer;
        this.companyInfo = companyInfo;
        this.questionType = questionType;
    }

    public String getQuestion() {
        return question;
    }

    public void setQuestion(String question) {
        this.question = question;
    }

    public String getAnswer() {
        return answer;
    }

    public void setAnswer(String answer) {
        this.answer = answer;
    }

    public Map<String, String> getCompanyInfo() {
        return companyInfo;
    }

    public void setCompanyInfo(Map<String, String> companyInfo) {
        this.companyInfo = companyInfo;
    }

    public String getQuestionType() {
        return questionType;
    }

    public void setQuestionType(String questionType) {
        this.questionType = questionType;
    }

    @Override
    public String toString() {
        return "AnswerDTO{" +
               "question='" + question + '\'' +
               ", answer='" + answer + '\'' +
               ", companyInfo=" + companyInfo +
               ", questionType='" + questionType + '\'' +
               '}';
    }
}