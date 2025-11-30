package com.bridge.backend.service;

import java.util.Optional;
// DTO
import com.bridge.backend.dto.UserDto;
// Entities
import com.bridge.backend.entity.Company;
import com.bridge.backend.entity.Subscription;
import com.bridge.backend.entity.IndustryRelation;
import com.bridge.backend.entity.User;
// Repositories
import com.bridge.backend.repository.SubscriptionRepository;
import com.bridge.backend.repository.IndustryRelationRepository;
import com.bridge.backend.repository.UserRepository;

import jakarta.transaction.Transactional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import com.bridge.backend.entity.Industry;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.time.LocalDateTime;
import java.util.List;



@Service
public class UserService {

    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private IndustryRelationRepository industryRelationRepository;

    @Autowired
    private SubscriptionRepository subscriptionRepository;

    @Autowired
    private com.bridge.backend.repository.CompanyRepository companyRepository;

    @Autowired
    private com.bridge.backend.repository.IndustryRepository industryRepository;

    // パスワードハッシュ用
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    /**
     * ユーザー作成 + 希望業界の保存（industry_relations）
     */
    @Transactional
    public User createUser(UserDto userDto) {
        logger.info("Received userDto type={}", userDto.getType());

        if (userRepository.existsByEmail(userDto.getEmail())) {
            throw new IllegalArgumentException("このメールアドレスは既に使用されています");
        }

        // 1. ユーザー保存
        User user = new User();
        user.setNickname(userDto.getNickname());
        user.setEmail(userDto.getEmail());
        user.setPassword(passwordEncoder.encode(userDto.getPassword()));
        user.setPhoneNumber(userDto.getPhoneNumber());
        user.setType(userDto.getType());
        user.setPlanStatus("無料"); // usersテーブルは文字列
        user.setIsWithdrawn(false);
        user.setCreatedAt(LocalDateTime.now());

        if (userDto.getSocietyHistory() != null) {
            user.setSocietyHistory(userDto.getSocietyHistory());
        }

        User savedUser = userRepository.save(user);

        // 2. 業界関係保存
        if (userDto.getDesiredIndustries() != null) {
            int relationType = switch (userDto.getType()) {
                case 2 -> 2; // 社会人
                case 3 -> 3; // 企業
                default -> 1; // 学生
            };
            for (Integer industryId : userDto.getDesiredIndustries()) {
                IndustryRelation relation = new IndustryRelation();
                relation.setUser(savedUser);
                Industry industry = new Industry();
                industry.setId(industryId);
                relation.setIndustry(industry);
                relation.setType(relationType);
                relation.setCreatedAt(LocalDateTime.now());
                industryRelationRepository.save(relation);
            }
        }
        logger.info("createUser called: email={} type={} societyHistory={}",
             userDto.getEmail(), userDto.getType(), userDto.getSocietyHistory());


        // 3. 企業ユーザーの場合のみ企業情報 + サブスクリプション保存
        if (userDto.getType() == 3) {
            logger.info("createUser called: email={} type={}", userDto.getEmail(), userDto.getType());

            Company company = new Company();
            company.setName(userDto.getCompanyName());
            company.setAddress(userDto.getCompanyAddress());
            company.setPhoneNumber(userDto.getCompanyPhoneNumber());
            company.setDescription(userDto.getCompanyDescription());
            company.setPlanStatus(1);
            company.setIsWithdrawn(false);
            company.setCreatedAt(LocalDateTime.now());

            Company savedCompany = companyRepository.save(company);
            logger.info("Company saved: companyId={}", savedCompany.getId());

            savedUser.setCompanyId(savedCompany.getId());
            userRepository.save(savedUser);
            logger.info("User updated with companyId: userId={} companyId={}", savedUser.getId(), savedCompany.getId());

            logger.info("Start subscription save for userId={}", savedUser.getId());
            Subscription subscription = new Subscription();
            subscription.setUserId(savedUser.getId());
            subscription.setPlanName("プレミアム");//文字化け中かも
            subscription.setStartDate(LocalDateTime.now());
            subscription.setEndDate(LocalDateTime.now().plusYears(1));
            subscription.setIsPlanStatus(true);
            subscription.setCreatedAt(LocalDateTime.now());
            subscriptionRepository.save(subscription);
            logger.info("Subscription saved for userId={}", savedUser.getId());
        }


        System.out.println("type=" + userDto.getType());
        return savedUser;
    }

    // セッションユーザー情報取得
    public UserDto getUserById(Long id) {
        Optional<User> user = userRepository.findById(id.intValue());
        if (user.isPresent()) {
            User existingUser = user.get();
            UserDto userDto = new UserDto();
            userDto.setId(existingUser.getId());
            userDto.setNickname(existingUser.getNickname());
            userDto.setEmail(existingUser.getEmail());
            userDto.setPhoneNumber(existingUser.getPhoneNumber());
            userDto.setType(existingUser.getType());
            userDto.setSocietyHistory(existingUser.getSocietyHistory());
            userDto.setPlanStatus(existingUser.getPlanStatus()); // planStatusをUserDtoに設定
            userDto.setToken(existingUser.getToken());
            if (existingUser.getType() == 3 && existingUser.getCompanyId() != null) {
                Optional<Company> company = companyRepository.findById(existingUser.getCompanyId());
                if (company.isPresent()) {
                    Company existingCompany = company.get();
                    userDto.setCompanyName(existingCompany.getName());
                    userDto.setCompanyAddress(existingCompany.getAddress());
                    userDto.setCompanyPhoneNumber(existingCompany.getPhoneNumber());
                    userDto.setCompanyDescription(existingCompany.getDescription());
                }
            }
            return userDto;
        }
        return null;
    }

    // プロフィール編集
    @Transactional
    public UserDto updateUserProfile(Integer userId, UserDto dto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // ===== メールアドレス重複チェック =====
        Optional<User> existingUserWithEmail = userRepository.findByEmail(dto.getEmail());
        if (existingUserWithEmail.isPresent() && !existingUserWithEmail.get().getId().equals(userId)) {
            throw new IllegalArgumentException("そのメールアドレスは使用できません");
        }
        
        // ===== usersテーブル更新 =====
        user.setNickname(dto.getNickname());
        user.setEmail(dto.getEmail());
        user.setPhoneNumber(dto.getPhoneNumber());
        if (dto.getSocietyHistory() != null) {
            user.setSocietyHistory(dto.getSocietyHistory());
        } else {
            user.setSocietyHistory(null);
        }

        // ===== industry_relations更新（全削除→再登録） =====
        industryRelationRepository.deleteByUserId(userId);
        if (dto.getDesiredIndustries() != null) {
            int relationType = switch (user.getType()) {
                case 2 -> 2;
                case 3 -> 3;
                default -> 1;
            };
            for (Integer industryId : dto.getDesiredIndustries()) {
                Industry industry = industryRepository.findById(industryId)
                    .orElseThrow(() -> new RuntimeException("Industry not found: " + industryId));
                IndustryRelation relation = new IndustryRelation();
                relation.setUser(user);
                relation.setIndustry(industry);
                relation.setType(relationType);
                relation.setCreatedAt(LocalDateTime.now());
                industryRelationRepository.save(relation);
            }
        }

        // ===== companiesテーブル更新（企業アカウントのみ） =====
        if (user.getType() == 3 && user.getCompanyId() != null) {
            Company company = companyRepository.findById(user.getCompanyId())
                    .orElseThrow(() -> new RuntimeException("Company record not found for companyId: " + user.getCompanyId()));
            company.setAddress(dto.getCompanyAddress());
            company.setDescription(dto.getCompanyDescription());
            companyRepository.save(company);
        }

        userRepository.save(user);
        return getUserById(user.getId().longValue());
    }

    // 希望業界の更新
    @Transactional
    public void updateUserIndustries(Integer userId, List<Integer> industryIds) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 既存の業界リレーションを削除
        industryRelationRepository.deleteByUserId(userId);

        // 新しい業界リレーションを追加
        if (industryIds != null) {
            int relationType = switch (user.getType()) {
                case 2 -> 2; // 社会人
                case 3 -> 3; // 企業
                default -> 1; // 学生
            };
            for (Integer industryId : industryIds) {
                Industry industry = industryRepository.findById(industryId)
                        .orElseThrow(() -> new RuntimeException("Industry not found: " + industryId));
                IndustryRelation relation = new IndustryRelation();
                relation.setUser(user);
                relation.setIndustry(industry);
                relation.setType(relationType);
                relation.setCreatedAt(LocalDateTime.now());
                industryRelationRepository.save(relation);
            }
        }
    }
        
    // パスワード更新
    @Transactional
    public void updatePassword(Integer userId, String currentPassword, String newPassword) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));

        if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
            throw new IllegalArgumentException("現在のパスワードが一致しません");
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    // 退会処理
    @Transactional
    public void deleteUser(Integer userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));
        user.setIsWithdrawn(true);
        userRepository.save(user);
    }

    /**
     * IDに基づいてユーザー情報を取得
     * @param userId ユーザーID
     * @return Userオブジェクト (存在しない場合はnull)
     */
    public User getUserById(Integer userId) {
        return userRepository.findById(userId).orElse(null);
    }

    /**
     * ユーザーのトークン数を減らす
     * @param userId ユーザーID
     * @param tokensToDeduct 減らすトークン数
     * @return 更新後のUserオブジェクト
     */
    public User deductUserTokens(Integer userId, int tokensToDeduct) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found with ID: " + userId));

        if (user.getToken() < tokensToDeduct) {
            throw new IllegalArgumentException("Not enough tokens for user with ID: " + userId);
        }

        user.setToken(user.getToken() - tokensToDeduct);
        return userRepository.save(user);
    }
}
