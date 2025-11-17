package com.bridge.backend.dto;

import lombok.Data;
import java.util.List;

@Data
public class UserDto implements java.io.Serializable {
    private Integer id;
    private String nickname;
    private String email;
    private String password;
    private String phoneNumber;
    private int type; // 1 = 学生
    private List<Integer> desiredIndustries; // ← ここをIDリストに変更！
    private Integer societyHistory;

    // 手動でgetterとsetterを追加（Lombokが機能しない場合のため）
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

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }

    public List<Integer> getDesiredIndustries() {
        return desiredIndustries;
    }

    public void setDesiredIndustries(List<Integer> desiredIndustries) {
        this.desiredIndustries = desiredIndustries;
    }

    public Integer getSocietyHistory() {
        return societyHistory;
    }

    public void setSocietyHistory(Integer societyHistory) {
        this.societyHistory = societyHistory;
    }
}
