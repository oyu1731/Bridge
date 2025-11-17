package com.bridge.backend.repository;

import com.bridge.backend.entity.ArticleTag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * ArticleTagリポジトリ
 * 記事とタグの関連付けデータへのアクセスを管理するリポジトリです。
 */
@Repository
public interface ArticleTagRepository extends JpaRepository<ArticleTag, Integer> {
    
    /**
     * 記事IDに関連付けられた全てのタグを取得
     * 
     * @param articleId 記事ID
     * @return 記事に関連付けられたタグのリスト
     */
    List<ArticleTag> findByArticleId(Integer articleId);
    
    /**
     * 記事IDに関連付けられた全てのタグを削除
     * 
     * @param articleId 記事ID
     */
    void deleteByArticleId(Integer articleId);
}
