package com.bridge.backend.service;

import com.bridge.backend.dto.UserListDto;
import com.bridge.backend.dto.UserCommentHistoryDto;
import com.bridge.backend.dto.UserDetailDto;
import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.ForumThread;
import java.util.Optional;
// DTO
import com.bridge.backend.dto.UserDto;
// Entities
import com.bridge.backend.entity.Company;
import com.bridge.backend.entity.Subscription;
import com.bridge.backend.entity.IndustryRelation;
import com.bridge.backend.entity.Photo;
import com.bridge.backend.entity.User;
// Repositories
import com.bridge.backend.repository.SubscriptionRepository;
import com.bridge.backend.repository.IndustryRelationRepository;
import com.bridge.backend.repository.ChatRepository;
import com.bridge.backend.repository.IndustriesRepository;
import com.bridge.backend.repository.PhotoRepository;
import com.bridge.backend.repository.ThreadRepository;
import com.bridge.backend.repository.UserRepository;
import com.bridge.backend.repository.NoticeRepository;

import jakarta.transaction.Transactional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import com.bridge.backend.entity.Industry;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@Service
public class UserService {

    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private IndustryRelationRepository industryRelationRepository;

    @Autowired
    private PhotoRepository photoRepository;

    @Autowired
    private IndustriesRepository industriesRepository;

    @Autowired
    private NoticeRepository noticeRepository;

    @Autowired
    private ChatRepository chatRepository;

    @Autowired
    private ThreadRepository threadRepository;

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
        
        // 【追加】初期値を設定: トークン、アイコン、報告数、削除フラグ
        user.setToken(50); // 新規ユーザーの初期トークンを50に設定
        user.setIcon(1);
        user.setReportCount(0);
        user.setAnnouncementDeletion(1);
        
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
    public UserDto getUserById(Integer id) {
        Optional<User> user = userRepository.findById(id);
        if (user.isPresent()) {
            User existingUser = user.get();
            UserDto userDto = new UserDto();
            userDto.setId(existingUser.getId());
            userDto.setNickname(existingUser.getNickname());
            userDto.setEmail(existingUser.getEmail());
            userDto.setPhoneNumber(existingUser.getPhoneNumber());
            userDto.setType(existingUser.getType());
            userDto.setIcon(existingUser.getIcon());
            userDto.setSocietyHistory(existingUser.getSocietyHistory());
            
            // 【重要修正】token, planStatus, isWithdrawn のマッピングを追加
            // tokenはDBの値（9780）がそのまま使われる
            userDto.setToken(existingUser.getToken());
            userDto.setPlanStatus(existingUser.getPlanStatus());
            userDto.setIsWithdrawn(existingUser.getIsWithdrawn());

            // 希望業界IDのリストを取得し、DTOに設定
            List<Integer> desiredIndustries = industryRelationRepository.findByUserId(existingUser.getId()).stream()
                .map(relation -> relation.getIndustry().getId())
                .collect(Collectors.toList());
            userDto.setDesiredIndustries(desiredIndustries);


            if (existingUser.getType() == 3 && existingUser.getCompanyId() != null) {
                userDto.setCompanyId(existingUser.getCompanyId());
                Optional<Company> company = companyRepository.findById(existingUser.getCompanyId());
                if (company.isPresent()) {
                    Company existingCompany = company.get();
                    userDto.setCompanyName(existingCompany.getName());
                    userDto.setCompanyAddress(existingCompany.getAddress());
                    userDto.setCompanyPhoneNumber(existingCompany.getPhoneNumber());
                    userDto.setCompanyDescription(existingCompany.getDescription());
                    userDto.setCompanyPhotoId(existingCompany.getPhotoId());
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
        
        // 再度DBから最新の情報を取得して返す
        return getUserById(user.getId());
    }

    // アイコン更新
    @Transactional
    public UserDto updateUserIcon(Integer userId, Integer photoId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setIcon(photoId);
        userRepository.save(user);
        return getUserById(userId);
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
     * ユーザーのトークン数を減らす
     * @param userId ユーザーID
     * @param tokensToDeduct 減らすトークン数
     * @return 更新後のUserオブジェクト
     */
    public User deductUserTokens(Integer userId, int tokensToDeduct) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found with ID: " + userId));

        // DBから取得したトークンがnullの場合の安全策
        Integer currentTokens = user.getToken() != null ? user.getToken() : 0;

        if (currentTokens < tokensToDeduct) {
            throw new IllegalArgumentException("Not enough tokens for user with ID: " + userId);
        }

        user.setToken(currentTokens - tokensToDeduct);
        return userRepository.save(user);
    }

    // ユーザー一覧取得
    public List<UserListDto> getUsers() {
        return userRepository.findByIsWithdrawnFalseAndIsDeletedFalse().stream().map(user -> {
            String photoPath = "";
            if (user.getIcon() != null) {
                photoPath = photoRepository.findById(user.getIcon())
                        .map(Photo::getPhotoPath)
                        .orElse("");
            }
            int reportCount = noticeRepository.countByToUserId(user.getId());
            return new UserListDto(
                    user.getId(),
                    user.getNickname(),
                    user.getType(),
                    user.getIcon() != null ? user.getIcon() : 0,
                    photoPath,
                    reportCount
            );
        }).collect(Collectors.toList());
    }

    // ユーザー検索
    public List<UserListDto> searchUsers(String keyword, Integer type) {
        if ((keyword == null || keyword.isBlank()) && type == null) {
            return getUsers();
        }
        List<User> users;
        if (keyword != null && !keyword.isBlank() && type != null) {
            users = userRepository.findByNicknameContainingAndTypeAndIsWithdrawnFalseAndIsDeletedFalse(keyword, type);
        } else if (keyword != null && !keyword.isBlank()) {
            users = userRepository.findByNicknameContainingAndIsWithdrawnFalseAndIsDeletedFalse(keyword);
        } else {
            users = userRepository.findByTypeAndIsWithdrawnFalseAndIsDeletedFalse(type);
        }

        return users.stream().map(user -> {
            String photoPath = "";
            if (user.getIcon() != null) {
                photoPath = photoRepository.findById(user.getIcon())
                        .map(Photo::getPhotoPath)
                        .orElse("");
            }
            int reportCount = noticeRepository.countByToUserId(user.getId());
            return new UserListDto(
                    user.getId(),
                    user.getNickname(),
                    user.getType(),
                    user.getIcon() != null ? user.getIcon() : 0,
                    photoPath,
                    reportCount
            );
        }).collect(Collectors.toList());
    }

    // ユーザー詳細取得（通報回数込み）
    public UserDetailDto getUserDetail(Integer id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("ユーザーが存在しません"));

        // アイコンパス取得
        String iconPath = "";
        if (user.getIcon() != null) {
            iconPath = photoRepository.findById(user.getIcon())
                    .map(Photo::getPhotoPath)
                    .orElse("");
        }

        // ユーザータイプに応じてIndustryRelation.typeを決定
        int relationType = switch (user.getType()) {
            case 1 -> 1; // 学生 → 希望業界
            case 2 -> 2; // 社会人 → 所属業界
            case 3 -> 3; // 企業 → 企業業界
            default -> 0;
        };

        // 業界情報取得
        List<IndustryRelation> relations = industryRelationRepository.findByUserId(user.getId());
        String industryDisplay = relations.stream()
                .filter(r -> r.getType() == relationType)
                .map(i -> i.getIndustry().getIndustry())
                .collect(Collectors.joining(", "));

        // 通報回数取得
        long reportCount = noticeRepository.countByToUserId(user.getId());

        // DTO作成
        UserDetailDto dto = new UserDetailDto(
                user.getId(),
                user.getNickname(),
                user.getType(),
                user.getEmail(),
                user.getPhoneNumber(),
                iconPath,
                user.getCreatedAt() != null ? user.getCreatedAt().toString() : ""
        );
        dto.setIndustry(industryDisplay);
        dto.setReportCount((int) reportCount);

        return dto;
    }

    public List<UserCommentHistoryDto> getUserCommentHistory(Integer userId) {
        return chatRepository.findByUserIdOrderByCreatedAtDesc(userId)
            .stream()
            .map(chat -> {
                String title = threadRepository.findById(chat.getThreadId())
                        .map(ForumThread::getTitle)
                        .orElse("不明なスレッド");

                return new UserCommentHistoryDto(
                        title,
                        chat.getContent(),
                        chat.getCreatedAt().toLocalDate().toString(),
                        chat.getIsDeleted() != null && chat.getIsDeleted()
                );
            }).collect(Collectors.toList());
    }

    @Transactional
    public void deleteAdmin(Integer id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("ユーザーが存在しません"));

        user.setIsDeleted(true);
        userRepository.save(user);
    }
}
