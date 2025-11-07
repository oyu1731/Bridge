package com.bridge.backend.repository;

import com.bridge.backend.entity.Article;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ArticleRepository extends JpaRepository<Article, Long> {
    
    // 削除されていない記事のみを取得（更新日時の降順）
    List<Article> findByIsDeletedFalseOrderByUpdatedAtDesc();
    
    // 特定の企業の記事を取得（削除されていないもののみ）
    List<Article> findByCompanyIdAndIsDeletedFalseOrderByUpdatedAtDesc(Long companyId);
    
    // タイトルでの検索（部分一致、大小文字を区別しない）
    List<Article> findByTitleContainingIgnoreCaseAndIsDeletedFalseOrderByUpdatedAtDesc(String title);
    
    // 著者での検索
    List<Article> findByAuthorContainingIgnoreCaseAndIsDeletedFalseOrderByUpdatedAtDesc(String author);
    
    // タイトルまたは内容での検索
    @Query("SELECT a FROM Article a WHERE (UPPER(a.title) LIKE UPPER(CONCAT('%', :keyword, '%')) OR " +
           "UPPER(a.content) LIKE UPPER(CONCAT('%', :keyword, '%'))) AND a.isDeleted = false " +
           "ORDER BY a.updatedAt DESC")
    List<Article> findByTitleOrContentContaining(@Param("keyword") String keyword);
    
    // 企業IDと記事IDで検索（削除されていない記事のみ）
    Optional<Article> findByIdAndCompanyIdAndIsDeletedFalse(Long id, Long companyId);
    
    // IDで検索（削除されていない記事のみ）
    Optional<Article> findByIdAndIsDeletedFalse(Long id);
    
    // 特定企業の記事数をカウント（削除されていないもののみ）
    int countByCompanyIdAndIsDeletedFalse(Long companyId);
    
    // 最新の記事を指定数取得
    @Query("SELECT a FROM Article a WHERE a.isDeleted = false ORDER BY a.createdAt DESC")
    List<Article> findTopNRecentArticles(@Param("limit") int limit);
    
    // 企業と結合して記事を取得（企業情報も含めて）
    @Query("SELECT a FROM Article a JOIN FETCH a.company c WHERE a.isDeleted = false AND c.isWithdrawn = false ORDER BY a.updatedAt DESC")
    List<Article> findAllWithCompany();
    
    // 特定企業の記事を企業情報と一緒に取得
    @Query("SELECT a FROM Article a JOIN FETCH a.company c WHERE a.companyId = :companyId AND a.isDeleted = false AND c.isWithdrawn = false ORDER BY a.updatedAt DESC")
    List<Article> findByCompanyIdWithCompany(@Param("companyId") Long companyId);
}