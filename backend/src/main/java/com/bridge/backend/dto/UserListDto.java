package com.bridge.backend.dto;

public class UserListDto {
    private int id;
    private String nickname;
    private int type;
    private int icon;
    private String photoPath;
    private int reportCount;

    public UserListDto() {}

    public UserListDto(int id, String nickname, int type, int icon, String photoPath, int reportCount) {
        this.id = id;
        this.nickname = nickname;
        this.type = type;
        this.icon = icon;
        this.photoPath = photoPath;
        this.reportCount = reportCount;
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

    public int getIcon() {
        return icon;
    }

    public void setIcon(int icon) {
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
}
