package com.bridge.backend.repository;

import com.bridge.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

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

    // パスワード更新のためのメソッド
    Optional<User> findById(Integer id);

}
