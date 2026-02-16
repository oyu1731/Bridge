package com.bridge.backend.repository;

import com.bridge.backend.entity.ArticleLike;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * ArticleLikeRepository
 * 記事いいねのデータアクセスを担当するリポジトリです。
 */
@Repository
public interface ArticleLikeRepository extends JpaRepository<ArticleLike, Integer> {
    
    /**
     * 記事IDとユーザーIDでいいねが存在するかチェック
     */
    boolean existsByArticleIdAndUserId(Integer articleId, Integer userId);
    
    /**
     * 記事IDとユーザーIDでいいねを検索
     */
    Optional<ArticleLike> findByArticleIdAndUserId(Integer articleId, Integer userId);
    
    /**
     * 記事IDでいいね数をカウント
     */
    long countByArticleId(Integer articleId);

    /**
     * ユーザーがいいねした記事IDをいいね日時の降順で取得
     */
    @Query("SELECT al.articleId FROM ArticleLike al WHERE al.userId = :userId ORDER BY al.createdAt DESC")
    List<Integer> findArticleIdsByUserIdOrderByCreatedAtDesc(@Param("userId") Integer userId);
}
