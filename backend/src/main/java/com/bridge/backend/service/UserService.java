package com.bridge.backend.service;

import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.IndustryRelation;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.IndustryRelationRepository;
import com.bridge.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private IndustryRelationRepository industryRelationRepository;

    /**
     * ユーザー作成 + 希望業界の保存（industry_relations）
     */
    public User createUser(UserDto userDto) {

        // ✅ 1. ユーザーを保存
        User user = new User();
        user.setNickname(userDto.getNickname());
        user.setEmail(userDto.getEmail());
        user.setPassword(userDto.getPassword());
        user.setPhoneNumber(userDto.getPhoneNumber());
        user.setType(userDto.getType());

        User savedUser = userRepository.save(user);

        Long userId = savedUser.getId().longValue();

        // ✅ 2. 希望業界（type = 1）を industry_relations に登録
        if (userDto.getDesiredIndustries() != null) {
            for (Integer industryId : userDto.getDesiredIndustries()) {

                IndustryRelation relation = new IndustryRelation();
                relation.setType(1);              // 希望業界
                relation.setUserId(userId);       // 登録した user の ID
                relation.setTargetId(industryId.longValue());
                relation.setCreatedAt(LocalDateTime.now());

                industryRelationRepository.save(relation);
            }
        }

        return savedUser;
    }
}
