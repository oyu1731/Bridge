package com.bridge.backend.dto;
import lombok.Data;

@Data
public class IndustryRelationsDTO implements java.io.Serializable {
    private Integer id;
    private Integer type;
    private Integer userId;
    private Integer industryId;
    private String industryName;

    // 手動でgetterとsetterを追加（Lombokが機能しない場合のため）
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }
    public Integer getType() {
        return type;
    }

    public void setType(Integer type) {
        this.type = type;
    }
    
    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public Integer getIndustryId() {
        return industryId;
    }

    public void setIndustryId(Integer industryId) {
        this.industryId = industryId;
    }

    public String getIndustryName() {
        return industryName;
    }

    public void setIndustryName(String industryName) {
        this.industryName = industryName;
    }
}