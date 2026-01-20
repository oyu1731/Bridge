package com.bridge.backend.repository;

import com.bridge.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.List;

// User エンティティを操作するための Repository
public interface UserRepository extends JpaRepository<User, Integer> {
    
    /**
     * 企業IDに基づいてユーザーを検索
     */
    Optional<User> findByCompanyId(Integer companyId);
    
    // メールアドレスでユーザーを検索（認証で使用）
    Optional<User> findByEmail(String email);
    
    // メールアドレス重複チェック
    boolean existsByEmail(String email);

    // 検索用
    List<User> findByNicknameContaining(String keyword);
    List<User> findByType(Integer type);
    List<User> findByNicknameContainingAndType(String keyword, Integer type);

    List<User> findByIsWithdrawnFalseAndIsDeletedFalse();

    List<User> findByNicknameContainingAndTypeAndIsWithdrawnFalseAndIsDeletedFalse(String keyword, Integer type);

    List<User> findByNicknameContainingAndIsWithdrawnFalseAndIsDeletedFalse(String keyword);

    List<User> findByTypeAndIsWithdrawnFalseAndIsDeletedFalse(Integer type);
    // パスワード更新のためのメソッド
    Optional<User> findById(Integer id);

}
