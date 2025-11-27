package com.bridge.backend.repository;

import com.bridge.backend.entity.Article;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Articleリポジトリ
 * 記事データへのアクセスを管理するリポジトリです。
 */
@Repository
public interface ArticleRepository extends JpaRepository<Article, Integer> {
    
    /**
     * 削除されていない記事をタグ情報と一緒に全て取得
     * 
     * @return 削除されていない記事のリスト（タグ情報含む）
     */
    @Query("SELECT DISTINCT a FROM Article a LEFT JOIN FETCH a.tags WHERE a.isDeleted = false ORDER BY a.createdAt DESC")
    List<Article> findAllWithTags();
    
    /**
     * 削除されていない記事を全て取得
     * 
     * @return 削除されていない記事のリスト
     */
    List<Article> findByIsDeletedFalseOrderByCreatedAtDesc();
    
    /**
     * タイトルまたは説明で検索（削除されていないもののみ）
     * 
     * @param keyword 検索キーワード
     * @return 検索条件に一致する記事のリスト
     */
    @Query("SELECT a FROM Article a WHERE a.isDeleted = false AND (a.title LIKE %:keyword% OR a.description LIKE %:keyword%) ORDER BY a.createdAt DESC")
    List<Article> findByKeyword(@Param("keyword") String keyword);
    
    /**
     * 企業IDで記事を検索（削除されていないもののみ）
     * 
     * @param companyId 企業ID
     * @return 該当企業の記事のリスト
     */
    List<Article> findByCompanyIdAndIsDeletedFalseOrderByCreatedAtDesc(Integer companyId);
    
    /**
     * IDと削除フラグで記事をタグ情報と一緒に検索
     * 
     * @param id 記事ID
     * @return 記事（存在しない、または削除済みの場合はnull）
     */
    @Query("SELECT a FROM Article a LEFT JOIN FETCH a.tags WHERE a.id = :id AND a.isDeleted = false")
    Article findByIdAndIsDeletedFalseWithTags(@Param("id") Integer id);
    
    /**
     * IDと削除フラグで記事を検索
     * 
     * @param id 記事ID
     * @return 記事（存在しない、または削除済みの場合はnull）
     */
    Article findByIdAndIsDeletedFalse(Integer id);
}