package com.example.bridge.dto;

/**
 * 企業ユーザー登録リクエストDTO
 */
public class CompanySignUpRequest {
    private String companyName;
    private String companyAddress;
    private String companyPhoneNumber;
    private String companyDescription;
    private String companyPhotoId;
    
    private String userEmail;
    private String userPassword;
    private String userNickname;
    private String userPhoneNumber;
    
    // Constructors
    public CompanySignUpRequest() {}
    
    // Getters and Setters
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
    
    public String getCompanyPhotoId() {
        return companyPhotoId;
    }
    
    public void setCompanyPhotoId(String companyPhotoId) {
        this.companyPhotoId = companyPhotoId;
    }
    
    public String getUserEmail() {
        return userEmail;
    }
    
    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }
    
    public String getUserPassword() {
        return userPassword;
    }
    
    public void setUserPassword(String userPassword) {
        this.userPassword = userPassword;
    }
    
    public String getUserNickname() {
        return userNickname;
    }
    
    public void setUserNickname(String userNickname) {
        this.userNickname = userNickname;
    }
    
    public String getUserPhoneNumber() {
        return userPhoneNumber;
    }
    
    public void setUserPhoneNumber(String userPhoneNumber) {
        this.userPhoneNumber = userPhoneNumber;
    }
}
