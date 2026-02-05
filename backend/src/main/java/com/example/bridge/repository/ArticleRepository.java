package com.example.bridge.repository;

import com.example.bridge.entity.Article;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 記事リポジトリ
 */
@Repository
public interface ArticleRepository extends JpaRepository<Article, Integer> {
    List<Article> findByCompanyId(Integer companyId);
    List<Article> findByUserId(Integer userId);
}
