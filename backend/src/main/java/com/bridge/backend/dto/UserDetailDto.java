package com.bridge.backend.dto;

public class UserDetailDto {
    private int id;
    private String nickname;
    private int type;
    private String email;
    private String phoneNumber;
    private String icon; // パス文字列
    private String createdAt;
    private boolean deleted;
    private boolean withdrawn;

    // 新規フィールド
    private String desiredIndustry; // 希望業界（学生用）
    private String belongIndustry;  // 所属業界（社会人用）
    private String companyIndustry; // 企業所属業界（企業用）
    private String industry;

    // 追加: 通報回数
    private int reportCount;

    public UserDetailDto() {}

    public UserDetailDto(int id, String nickname, int type, String email, String phoneNumber, String icon, String createdAt, boolean deleted, boolean withdrawn) {
        this.id = id;
        this.nickname = nickname;
        this.type = type;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.icon = icon;
        this.createdAt = createdAt;
        this.deleted = deleted;
        this.withdrawn = withdrawn;
        this.industry = "";
        this.reportCount = 0;
    }

    // getter/setter
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }

    public int getType() { return type; }
    public void setType(int type) { this.type = type; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public boolean isDeleted() { return deleted; }
    public void setDeleted(boolean deleted) { this.deleted = deleted; }

    public boolean isWithdrawn() { return withdrawn; }
    public void setWithdrawn(boolean withdrawn) { this.withdrawn = withdrawn; }

    // 新規フィールド用 getter/setter
    public String getDesiredIndustry() { return desiredIndustry; }
    public void setDesiredIndustry(String desiredIndustry) { this.desiredIndustry = desiredIndustry; }

    public String getBelongIndustry() { return belongIndustry; }
    public void setBelongIndustry(String belongIndustry) { this.belongIndustry = belongIndustry; }

    public String getCompanyIndustry() { return companyIndustry; }
    public void setCompanyIndustry(String companyIndustry) { this.companyIndustry = companyIndustry; }

    public String getIndustry() { return industry; }
    public void setIndustry(String industry) { this.industry = industry; }

    public int getReportCount() { return reportCount; }
    public void setReportCount(int reportCount) { this.reportCount = reportCount; }
}
