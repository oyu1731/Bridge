package com.bridge.backend.dto;

import java.util.List;

public class UserDto {
    private Integer id;
    private String nickname;
    private String email;
    private String password;
    private String phoneNumber;
    private Integer type; // 1=学生, 2=社会人, 3=企業
    private String planStatus; // "無料" など
    private Boolean isWithdrawn;
    private Integer societyHistory;
    private List<Integer> desiredIndustries;
    private Integer icon; // プロフィールアイコン写真ID (photos.id)
    private Integer token; // トークン数
    

    // 企業ユーザー用フィールド
    private Integer companyId;
    private String companyName;
    private String companyAddress;
    private String companyPhoneNumber;
    private String companyDescription;
    private Integer companyPhotoId;

    // ===== Getter / Setter =====
    public Integer getId() {
        return id;
    }
    public void setId(Integer id) {
        this.id = id;
    }
    
    public String getNickname() {
        return nickname;
    }
    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public String getEmail() {
        return email;
    }
    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }
    public void setPassword(String password) {
        this.password = password;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }
    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public Integer getType() {
        return type;
    }
    public void setType(Integer type) {
        this.type = type;
    }

    public String getPlanStatus() {
        return planStatus;
    }
    public void setPlanStatus(String planStatus) {
        this.planStatus = planStatus;
    }

    public Boolean getIsWithdrawn() {
        return isWithdrawn;
    }
    public void setIsWithdrawn(Boolean isWithdrawn) {
        this.isWithdrawn = isWithdrawn;
    }

    public Integer getSocietyHistory() {
        return societyHistory;
    }
    public void setSocietyHistory(Integer societyHistory) {
        this.societyHistory = societyHistory;
    }

    public List<Integer> getDesiredIndustries() {
        return desiredIndustries;
    }
    public void setDesiredIndustries(List<Integer> desiredIndustries) {
        this.desiredIndustries = desiredIndustries;
    }

    public Integer getToken() {
        return token;
    }
    public void setToken(Integer token) {
        this.token = token;
    }
    public Integer getIcon() {
        return icon;
    }

    public void setIcon(Integer icon) {
        this.icon = icon;
    }

    // 企業用フィールド

    public Integer getCompanyId() {
        return companyId;
    }
    public void setCompanyId(Integer companyId) {
        this.companyId = companyId;
    }

    public String getCompanyName() {
        return companyName;
    }
    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getCompanyAddress() {
        return companyAddress;
    }
    public void setCompanyAddress(String companyAddress) {
        this.companyAddress = companyAddress;
    }

    public String getCompanyPhoneNumber() {
        return companyPhoneNumber;
    }
    public void setCompanyPhoneNumber(String companyPhoneNumber) {
        this.companyPhoneNumber = companyPhoneNumber;
    }

    public String getCompanyDescription() {
        return companyDescription;
    }
    public void setCompanyDescription(String companyDescription) {
        this.companyDescription = companyDescription;
    }

    public Integer getCompanyPhotoId() {
        return companyPhotoId;
    }
    public void setCompanyPhotoId(Integer companyPhotoId) {
        this.companyPhotoId = companyPhotoId;
    }
}
