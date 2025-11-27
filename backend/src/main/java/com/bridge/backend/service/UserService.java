package com.bridge.backend.service;

import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.IndustryRelation;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.IndustryRelationRepository;
import com.bridge.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private IndustryRelationRepository industryRelationRepository;

    // パスワードハッシュ用のEncoderを作成
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    /**
     * ユーザー作成 + 希望業界の保存（industry_relations）
     */
    public User createUser(UserDto userDto) {

        if (userRepository.existsByEmail(userDto.getEmail())) {
            throw new IllegalArgumentException("このメールアドレスは既に使用されています");
        }

        // ✅ 1. ユーザーを保存
        User user = new User();
        user.setNickname(userDto.getNickname());
        user.setEmail(userDto.getEmail());

        // 🔐 パスワードをハッシュ化して保存
        String hashedPassword = passwordEncoder.encode(userDto.getPassword());
        user.setPassword(hashedPassword);

        user.setPhoneNumber(userDto.getPhoneNumber());
        user.setType(userDto.getType());

        User savedUser = userRepository.save(user);

        Integer userId = savedUser.getId();

        // ✅ 2. 希望業界（type = 1）を industry_relations に登録
        if (userDto.getDesiredIndustries() != null) {
            for (Integer industryId : userDto.getDesiredIndustries()) {

                IndustryRelation relation = new IndustryRelation();
                relation.setType(1);              // 希望業界
                relation.setUserId(userId);       // 登録した user の ID
                relation.setTargetId(industryId);
                relation.setCreatedAt(LocalDateTime.now());

                industryRelationRepository.save(relation);
            }
        }

        return savedUser;
    }
}
