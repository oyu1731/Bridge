package com.bridge.backend.dto;

/**
 * IndustryDTO
 * 業界データの転送用オブジェクトです。
 */
public class IndustryDTO {
    private Integer id;
    private String industry;

    // デフォルトコンストラクタ
    public IndustryDTO() {
    }

    // 全フィールドのコンストラクタ
    public IndustryDTO(Integer id, String industry) {
        this.id = id;
        this.industry = industry;
    }

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getIndustry() {
        return industry;
    }

    public void setIndustry(String industry) {
        this.industry = industry;
    }

    @Override
    public String toString() {
        return "IndustryDTO{" +
                "id=" + id +
                ", industry='" + industry + '\'' +
                '}';
    }
}