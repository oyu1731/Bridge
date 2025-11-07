package com.bridge.backend.dto;

import com.bridge.backend.entity.Company;
import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.LocalDateTime;
import java.util.List;

public class CompanyDTO {
    private Long id;
    private String name;
    private String address;
    private String phoneNumber;
    private String description;
    private Boolean isWithdrawn;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    
    private Long photoId;
    private List<String> imageUrls; // 企業に関連する画像のURL一覧
    
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
        this.isWithdrawn = company.getIsWithdrawn();
        this.createdAt = company.getCreatedAt();
        this.photoId = company.getPhotoId();
    }
    
    // 作成用コンストラクタ
    public CompanyDTO(String name, String address, String phoneNumber, String description) {
        this.name = name;
        this.address = address;
        this.phoneNumber = phoneNumber;
        this.description = description;
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
        company.setIsWithdrawn(this.isWithdrawn != null ? this.isWithdrawn : false);
        company.setCreatedAt(this.createdAt);
        company.setPhotoId(this.photoId);
        return company;
    }
    
    // Getter/Setter
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
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
    
    public Long getPhotoId() {
        return photoId;
    }
    
    public void setPhotoId(Long photoId) {
        this.photoId = photoId;
    }
    
    public List<String> getImageUrls() {
        return imageUrls;
    }
    
    public void setImageUrls(List<String> imageUrls) {
        this.imageUrls = imageUrls;
    }
}