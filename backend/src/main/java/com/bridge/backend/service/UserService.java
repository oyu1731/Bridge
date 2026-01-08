package com.bridge.backend.service;

import com.bridge.backend.dto.UserListDto;
import com.bridge.backend.dto.UserCommentHistoryDto;
import com.bridge.backend.dto.UserDetailDto;
import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.ForumThread;
import com.bridge.backend.entity.IndustryRelation;
import com.bridge.backend.entity.Photo;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.IndustryRelationRepository;
import com.bridge.backend.repository.ChatRepository;
import com.bridge.backend.repository.IndustriesRepository;
import com.bridge.backend.repository.PhotoRepository;
import com.bridge.backend.repository.ThreadRepository;
import com.bridge.backend.repository.UserRepository;
import com.bridge.backend.repository.NoticeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserService {

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

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    // ユーザー作成
    public User createUser(UserDto userDto) {
        if (userRepository.existsByEmail(userDto.getEmail())) {
            throw new IllegalArgumentException("このメールアドレスは既に使用されています");
        }
        User user = new User();
        user.setNickname(userDto.getNickname());
        user.setEmail(userDto.getEmail());
        user.setPassword(passwordEncoder.encode(userDto.getPassword()));
        user.setPhoneNumber(userDto.getPhoneNumber());
        user.setType(userDto.getType());
        User savedUser = userRepository.save(user);

        // 希望業界登録（学生の場合）
        if (userDto.getDesiredIndustries() != null) {
            for (Integer industryId : userDto.getDesiredIndustries()) {
                IndustryRelation relation = new IndustryRelation();
                relation.setType(1);
                relation.setUserId(savedUser.getId());
                relation.setTargetId(industryId);
                relation.setCreatedAt(LocalDateTime.now());
                industryRelationRepository.save(relation);
            }
        }
        return savedUser;
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
                .map(r -> industriesRepository.findById(r.getTargetId())
                        .map(i -> i.getIndustry())
                        .orElse(""))
                .filter(name -> !name.isEmpty())
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
        return chatRepository.findByUserIdAndIsDeletedFalseOrderByCreatedAtDesc(userId)
            .stream()
            .map(chat -> {
                String title = threadRepository.findById(chat.getThreadId())
                        .map(ForumThread::getTitle)
                        .orElse("不明なスレッド");

                return new UserCommentHistoryDto(
                        title,
                        chat.getContent(),
                        chat.getCreatedAt().toLocalDate().toString()
                );
            }).collect(Collectors.toList());
    }

    @Transactional
    public void deleteUser(Integer id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("ユーザーが存在しません"));

        user.setIsDeleted(true);
        userRepository.save(user);
    }
}
