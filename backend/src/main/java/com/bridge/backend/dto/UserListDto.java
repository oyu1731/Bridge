package com.bridge.backend.dto;

public class UserListDto {
    private int id;
    private String nickname;
    private int type;
    private Integer icon; // nullable: allows API to return null when not set
    private String photoPath;
    private int reportCount;
    private boolean deleted;
    private boolean withdrawn;

    public UserListDto() {}

    public UserListDto(int id, String nickname, int type, Integer icon, String photoPath, int reportCount, boolean deleted, boolean withdrawn) {
        this.id = id;
        this.nickname = nickname;
        this.type = type;
        this.icon = icon;
        this.photoPath = photoPath;
        this.reportCount = reportCount;
        this.deleted = deleted;
        this.withdrawn = withdrawn;
    }

    // 手動でgetterとsetterを追加（Lombokが機能しない場合のため）
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }
    
    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }

    public Integer getIcon() {
        return icon;
    }

    public void setIcon(Integer icon) {
        this.icon = icon;
    }

    public String getPhotoPath() {
        return photoPath;
    }

    public void setPhotoPath(String photoPath) {
        this.photoPath = photoPath;
    }

    public int getReportCount() {
        return reportCount;
    }

    public void setReportCount(int reportCount) {
        this.reportCount = reportCount;
    }

    public boolean isDeleted() {
        return deleted;
    }

    public void setDeleted(boolean deleted) {
        this.deleted = deleted;
    }

    public boolean isWithdrawn() {
        return withdrawn;
    }

    public void setWithdrawn(boolean withdrawn) {
        this.withdrawn = withdrawn;
    }
}
