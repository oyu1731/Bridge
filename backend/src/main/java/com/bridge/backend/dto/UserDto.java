package com.bridge.backend.dto;

import lombok.Data;
import java.util.List;

@Data
public class UserDto {
    private String nickname;
    private String email;
    private String password;
    private String phoneNumber;
    private int type; // 1 = 学生
    private List<Integer> desiredIndustries; // ← ここをIDリストに変更！
}
