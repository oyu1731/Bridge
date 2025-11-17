package com.bridge.backend.service;

import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.IndustryRelation;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.IndustryRelationRepository;
import com.bridge.backend.repository.UserRepository;
import jakarta.persistence.Column;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import com.bridge.backend.entity.Industry;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDateTime;

@Service
public class UserService {

    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

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
        
        logger.info("createUser called: email={} societyHistory={}", userDto.getEmail(), userDto.getSocietyHistory());
        if (userDto.getSocietyHistory() != null) {
            user.setSocietyHistory(userDto.getSocietyHistory());
        }

        User savedUser = userRepository.save(user);
        logger.info("User saved: id={} societyHistory={}", savedUser.getId(), savedUser.getSocietyHistory());

        Integer userId = savedUser.getId();

        // ✅ 2. 業界を industry_relations に登録
        if (userDto.getDesiredIndustries() != null) {
            int relationType = 1; // デフォルトは希望業界
            if (userDto.getType() == 2) {
                relationType = 2; // 社会人の場合、所属業界
            } else if (userDto.getType() == 3) {
                relationType = 3; // 企業の場合、企業所属業界
            }
            for (Integer industryId : userDto.getDesiredIndustries()) {
                IndustryRelation relation = new IndustryRelation();
                relation.setUser(savedUser);
                Industry industry = new Industry();
                industry.setId(industryId);
                relation.setIndustry(industry);
                relation.setType(relationType);
                industryRelationRepository.save(relation);
            }
        }

        return savedUser;
    }
}
