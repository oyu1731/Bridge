package com.bridge.backend.service;

import com.bridge.backend.dto.ArticleDTO;
import com.bridge.backend.entity.Article;
import com.bridge.backend.entity.Company;
import com.bridge.backend.repository.ArticleRepository;
import com.bridge.backend.repository.CompanyRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Articleサービス
 * 記事のビジネスロジックを担当するサービスです。
 */
@Service
public class ArticleService {

    @Autowired
    private ArticleRepository articleRepository;

    @Autowired
    private CompanyRepository companyRepository;

    /**
     * 全ての記事を取得（削除されていないもの）
     * 
     * @return ArticleDTOのリスト
     */
    public List<ArticleDTO> getAllArticles() {
        List<Article> articles = articleRepository.findByIsDeletedFalseOrderByCreatedAtDesc();
        return articles.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * キーワードで記事を検索
     * 
     * @param keyword 検索キーワード
     * @return ArticleDTOのリスト
     */
    public List<ArticleDTO> searchArticles(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return getAllArticles();
        }
        List<Article> articles = articleRepository.findByKeyword(keyword.trim());
        return articles.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * IDで記事を取得
     * 
     * @param id 記事ID
     * @return ArticleDTO（存在しない場合はnull）
     */
    public ArticleDTO getArticleById(Integer id) {
        Article article = articleRepository.findByIdAndIsDeletedFalse(id);
        return article != null ? convertToDTO(article) : null;
    }

    /**
     * 企業IDで記事を取得
     * 
     * @param companyId 企業ID
     * @return ArticleDTOのリスト
     */
    public List<ArticleDTO> getArticlesByCompanyId(Integer companyId) {
        List<Article> articles = articleRepository.findByCompanyIdAndIsDeletedFalseOrderByCreatedAtDesc(companyId);
        return articles.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 記事を作成
     * 
     * @param articleDTO 作成する記事のDTO
     * @return 作成された記事のDTO
     */
    public ArticleDTO createArticle(ArticleDTO articleDTO) {
        Article article = new Article();
        article.setTitle(articleDTO.getTitle());
        article.setDescription(articleDTO.getDescription());
        article.setCompanyId(articleDTO.getCompanyId());
        article.setIsDeleted(false);
        article.setTotalLikes(0);
        article.setCreatedAt(LocalDateTime.now());
        article.setPhoto1Id(articleDTO.getPhoto1Id());
        article.setPhoto2Id(articleDTO.getPhoto2Id());
        article.setPhoto3Id(articleDTO.getPhoto3Id());

        Article savedArticle = articleRepository.save(article);
        return convertToDTO(savedArticle);
    }

    /**
     * 記事を更新
     * 
     * @param id 更新する記事のID
     * @param articleDTO 更新内容
     * @return 更新された記事のDTO（存在しない場合はnull）
     */
    public ArticleDTO updateArticle(Integer id, ArticleDTO articleDTO) {
        Article existingArticle = articleRepository.findByIdAndIsDeletedFalse(id);
        if (existingArticle == null) {
            return null;
        }

        existingArticle.setTitle(articleDTO.getTitle());
        existingArticle.setDescription(articleDTO.getDescription());
        existingArticle.setPhoto1Id(articleDTO.getPhoto1Id());
        existingArticle.setPhoto2Id(articleDTO.getPhoto2Id());
        existingArticle.setPhoto3Id(articleDTO.getPhoto3Id());

        Article updatedArticle = articleRepository.save(existingArticle);
        return convertToDTO(updatedArticle);
    }

    /**
     * 記事を削除（論理削除）
     * 
     * @param id 削除する記事のID
     * @return 削除成功の場合true
     */
    public boolean deleteArticle(Integer id) {
        Article article = articleRepository.findByIdAndIsDeletedFalse(id);
        if (article == null) {
            return false;
        }

        article.setIsDeleted(true);
        articleRepository.save(article);
        return true;
    }

    /**
     * ArticleエンティティをArticleDTOに変換
     * 
     * @param article Articleエンティティ
     * @return ArticleDTO
     */
    private ArticleDTO convertToDTO(Article article) {
        // 企業名を取得
        String companyName = null;
        if (article.getCompanyId() != null) {
            Company company = companyRepository.findById(article.getCompanyId()).orElse(null);
            if (company != null) {
                companyName = company.getName();
            }
        }

        return new ArticleDTO(
                article.getId(),
                article.getCompanyId(),
                companyName,
                article.getTitle(),
                article.getDescription(),
                article.getTotalLikes(),
                article.getIsDeleted(),
                article.getCreatedAt() != null ? article.getCreatedAt().toString() : null,
                article.getPhoto1Id(),
                article.getPhoto2Id(),
                article.getPhoto3Id()
        );
    }
}