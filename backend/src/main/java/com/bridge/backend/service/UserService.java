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
import java.util.Map;
import java.util.HashMap;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@Service
public class UserService {
    public boolean existsByPhoneNumber(String phoneNumber) {
        return userRepository.findAll().stream().anyMatch(u -> phoneNumber.equals(u.getPhoneNumber()));
    }
    // userIdを除外して重複チェック
    public boolean existsByPhoneNumber(String phoneNumber, Integer excludeUserId) {
        return userRepository.findAll().stream()
            .anyMatch(u -> phoneNumber.equals(u.getPhoneNumber()) && (excludeUserId == null || !u.getId().equals(excludeUserId)));
    }
    public boolean existsByEmail(String email, Integer excludeUserId) {
        return userRepository.findAll().stream()
            .anyMatch(u -> email.equals(u.getEmail()) && (excludeUserId == null || !u.getId().equals(excludeUserId)));
    }

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
        
        // 🏢 企業ユーザーの場合は「企業プレミアム」、それ以外は「無料」
        if (userDto.getType() == 3) {
            user.setPlanStatus("企業プレミアム");
            System.out.println("✅ 企業ユーザー作成: planStatus='企業プレミアム'");
        } else {
            user.setPlanStatus("無料");
            System.out.println("✅ 一般ユーザー作成: planStatus='無料'");
        }
        
        user.setIsWithdrawn(false);
        user.setCreatedAt(LocalDateTime.now());
        
        // 【追加】初期値を設定: トークン、アイコン、報告数、削除フラグ
        user.setToken(50); // 新規ユーザーの初期トークンを50に設定
        user.setIcon(null);
        user.setReportCount(0);
        user.setAnnouncementDeletion(1);
        
        if (userDto.getSocietyHistory() != null) {
            user.setSocietyHistory(userDto.getSocietyHistory());
        }

        User savedUser = userRepository.save(user);

        // 安全対策: 何らかの理由でDBにデフォルト値が入ってしまうことを防ぐ
        if (savedUser.getIcon() != null) {
            logger.info("Saved user has non-null icon ({}). Resetting to null. userId={}", savedUser.getIcon(), savedUser.getId());
            savedUser.setIcon(null);
            savedUser = userRepository.save(savedUser);
        }

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
            
            user.setPlanStatus("プレミアム");

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
    public UserDto updateUserProfile(Integer userId,UserDto dto, Map<String, Object> body) {
        // ===== バリデーション =====
        if (dto.getNickname() == null || dto.getNickname().trim().isEmpty()) {
            throw new IllegalArgumentException("ニックネームを入力してください");
        }
        if (dto.getEmail() == null || dto.getEmail().trim().isEmpty()) {
            throw new IllegalArgumentException("メールアドレスを入力してください");
        }
        if (dto.getPhoneNumber() == null || dto.getPhoneNumber().trim().isEmpty()) {
            throw new IllegalArgumentException("電話番号を入力してください");
        }
        if (userRepository.findById(userId).orElseThrow().getType() == 2) {
            if (dto.getSocietyHistory() == null) {
                throw new IllegalArgumentException("社会人歴を入力してください");
            }
        }
        // 企業の場合、追加のバリデーション
        if (userRepository.findById(userId).orElseThrow().getType() == 3) {
            if (dto.getCompanyAddress() == null || dto.getCompanyAddress().trim().isEmpty()) {
                throw new IllegalArgumentException("住所を入力してください");
            }
            if (dto.getCompanyDescription() == null || dto.getCompanyDescription().trim().isEmpty()) {
                throw new IllegalArgumentException("詳細を入力してください");
            }
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // usersテーブル更新
        user.setNickname((String) body.get("nickname"));
        user.setEmail((String) body.get("email"));
        user.setPhoneNumber((String) body.get("phone_number"));
        // societyHistoryは任意
        if (body.get("society_history") != null) {
            user.setSocietyHistory((Integer) body.get("society_history"));
        } else {
            user.setSocietyHistory(null);
        }

        // industry_relations更新（全削除→再登録）
        industryRelationRepository.deleteByUserId(userId);
        Object industryIdsObj = body.get("industry_ids");
        if (industryIdsObj instanceof java.util.List<?>) {
            int relationType = switch (user.getType()) {
                case 2 -> 2;
                case 3 -> 3;
                default -> 1;
            };
            for (Object o : (java.util.List<?>)industryIdsObj) {
                Integer industryId = (Integer) o;
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

        // image_path（任意）
        if (body.get("image_path") != null) {
            // ここでUserエンティティにimage_pathフィールドがあればセット
            // user.setImagePath((String) body.get("image_path"));
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
                    user.getIcon(),
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
                    user.getIcon(),
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

                String content = chat.getContent();
                boolean hasPhoto = chat.getPhotoId() != null;

                String displayContent;
                if ((content == null || content.isBlank()) && hasPhoto) {
                    displayContent = "（画像のみ）"; // ← 文言は後で調整OK
                } else if (hasPhoto) {
                    displayContent = content + "（画像あり）";
                } else {
                    displayContent = content;
                }

                return new UserCommentHistoryDto(
                    title,
                    displayContent,
                    chat.getCreatedAt().toLocalDate().toString(),
                    Boolean.TRUE.equals(chat.getIsDeleted())
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

    /**
     * ログイン中のアカウントのサブスク確認・更新
     * 最新のサブスクリプションをチェックし、
     * 有効期限が切れていた場合はusersテーブルのplanStatusを"無料"に更新
     */
    @Transactional
    public Map<String, Object> checkAndUpdateSubscriptionStatus(Integer userId) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // 1. ユーザーが存在するか確認
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("ユーザーが見つかりません"));

            // 2. 最新のサブスクリプションを取得
            Optional<Subscription> latestSubscription = subscriptionRepository.findTopByUserIdOrderByEndDateDesc(userId);

            // 3. サブスクが存在しない場合は"無料"
            if (latestSubscription.isEmpty()) {
                user.setPlanStatus("無料");
                userRepository.save(user);
                    result.put("status", "no_subscription"); // 明示的なキャストを追加
                    result.put("planStatus", "無料"); // 明示的なキャストを追加
                    result.put("message", "サブスクリプションが見つかりません。プランを無料に更新しました。"); // 明示的なキャストを追加
                return result;
            }

            // 4. サブスクの有効期限を確認
            Subscription subscription = latestSubscription.get();
            LocalDateTime now = LocalDateTime.now();
            LocalDateTime endDate = subscription.getEndDate();

            // Defensive: endDate が null の場合は無効扱いにして無料に更新
            if (endDate == null) {
                logger.warn("Subscription endDate is null for subscriptionId={}, userId={}. Marking as free.", subscription.getId(), userId);
                user.setPlanStatus("無料");
                userRepository.save(user);
                result.put("status", "invalid_subscription");
                result.put("planStatus", "無料");
                result.put("message", "サブスクリプションの終了日が不明なため、無料に更新しました。");
                return result;
            }

            // 5. 有効期限が切れている場合
            if (endDate.isBefore(now)) {
                user.setPlanStatus("無料");
                userRepository.save(user);
                
                // 🏢 企業ユーザー（type=3）の場合、companiesテーブルのplan_statusも更新
                if (user.getType() == 3 && user.getCompanyId() != null) {
                    companyRepository.findById(user.getCompanyId()).ifPresent(company -> {
                        company.setPlanStatus(2); // 2 = 中断中（無料）
                        companyRepository.save(company);
                        logger.info("Updated company plan status to free for companyId: {}", user.getCompanyId());
                    });
                }
                
                result.put("status", "expired");
                result.put("planStatus", "無料");
                result.put("message", "サブスクリプションが期限切れです。プランを無料に更新しました。");
                result.put("expiredDate", endDate);
                logger.info("Subscription expired for userId: {}, updated to free plan", userId);
            } else {
                // 6. まだ有効な場合
                result.put("status", "active");
                result.put("planStatus", subscription.getPlanName());
                result.put("message", "サブスクリプションは有効です。");
                result.put("endDate", endDate);
            }

            return result;

        } catch (Exception e) {
            logger.error("Error checking subscription for userId: {}", userId, e);
            throw new RuntimeException("サブスクリプション確認エラー: " + e.getMessage());
        }
    }
    public String getPlanStatusById(Integer id) {
        User user = userRepository.findById(id).orElse(null);
        if (user == null) {
            return null;
        }

        // 🏢 企業ユーザー（type=3）の場合、companiesテーブルから確認
        if (user.getType() == 3 && user.getCompanyId() != null) {
            // companyRepositoryを使ってplan_statusを取得
            // Plan Status: 1=加入中（プレミアム）、2=中断中（無料）
            return companyRepository.findById(user.getCompanyId())
                    .map(company -> {
                        if (company.getPlanStatus() == 1) {
                            return "プレミアム";
                        } else {
                            return "無料";
                        }
                    })
                    .orElse(user.getPlanStatus());
        }

        // 👤 個人ユーザーの場合、usersテーブルのplanStatusを返す
        return user.getPlanStatus();
    }
}

