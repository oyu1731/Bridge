package com.bridge.backend.dto;

import com.bridge.backend.entity.Company;
import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.LocalDateTime;

public class CompanyDTO {
    private Integer id;
    private String name;
    private String address;
    private String phoneNumber;
    private String email; // ユーザーテーブルからのemail
    private String description;
    private Integer planStatus;
    private Boolean isWithdrawn;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    
    private Integer photoId;
    private String photoPath; // 写真パスを追加
    private String industry; // 業界情報を追加
    
    // デフォルトコンストラクタ
    public CompanyDTO() {
    }
    
    // Entityから変換するコンストラクタ
    public CompanyDTO(Company company) {
        this.id = company.getId();
        this.name = company.getName();
        this.address = company.getAddress();
        this.phoneNumber = company.getPhoneNumber();
        this.description = company.getDescription();
        this.planStatus = company.getPlanStatus();
        this.isWithdrawn = company.getIsWithdrawn();
        this.createdAt = company.getCreatedAt();
        this.photoId = company.getPhotoId();
    }
    
    // 作成用コンストラクタ
    public CompanyDTO(String name, String address, String phoneNumber, String description, Integer planStatus) {
        this.name = name;
        this.address = address;
        this.phoneNumber = phoneNumber;
        this.description = description;
        this.planStatus = planStatus;
        this.isWithdrawn = false;
    }
    
    // EntityをDTOに変換するstaticメソッド
    public static CompanyDTO fromEntity(Company company) {
        return new CompanyDTO(company);
    }
    
    // DTOをEntityに変換するメソッド
    public Company toEntity() {
        Company company = new Company();
        company.setId(this.id);
        company.setName(this.name);
        company.setAddress(this.address);
        company.setPhoneNumber(this.phoneNumber);
        company.setDescription(this.description);
        company.setPlanStatus(this.planStatus != null ? this.planStatus : 1);
        company.setIsWithdrawn(this.isWithdrawn != null ? this.isWithdrawn : false);
        company.setCreatedAt(this.createdAt);
        company.setPhotoId(this.photoId);
        return company;
    }
    
    // Getter/Setter
    public Integer getId() {
        return id;
    }
    
    public void setId(Integer id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public String getAddress() {
        return address;
    }
    
    public void setAddress(String address) {
        this.address = address;
    }
    
    public String getPhoneNumber() {
        return phoneNumber;
    }
    
    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public Integer getPlanStatus() {
        return planStatus;
    }
    
    public void setPlanStatus(Integer planStatus) {
        this.planStatus = planStatus;
    }
    
    public Boolean getIsWithdrawn() {
        return isWithdrawn;
    }
    
    public void setIsWithdrawn(Boolean isWithdrawn) {
        this.isWithdrawn = isWithdrawn;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public Integer getPhotoId() {
        return photoId;
    }
    
    public void setPhotoId(Integer photoId) {
        this.photoId = photoId;
    }
    
    public String getPhotoPath() {
        return photoPath;
    }
    
    public void setPhotoPath(String photoPath) {
        this.photoPath = photoPath;
    }
    
    public String getIndustry() {
        return industry;
    }
    
    public void setIndustry(String industry) {
        this.industry = industry;
    }
    
    public String getEmail() {
        return email;
    }
    
    public void setEmail(String email) {
        this.email = email;
    }
}