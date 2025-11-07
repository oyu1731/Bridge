package com.bridge.backend.service;

import com.bridge.backend.dto.ArticleDTO;
import com.bridge.backend.entity.Article;
import com.bridge.backend.entity.Company;
import com.bridge.backend.entity.ImageRelation;
import com.bridge.backend.repository.ArticleRepository;
import com.bridge.backend.repository.CompanyRepository;
import com.bridge.backend.repository.ImageRelationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Transactional
public class ArticleService {
    
    @Autowired
    private ArticleRepository articleRepository;
    
    @Autowired
    private CompanyRepository companyRepository;
    
    @Autowired
    private ImageRelationRepository imageRelationRepository;
    
    @Value("${app.image.base-url:http://localhost:8080/api/images}")
    private String imageBaseUrl;
    
    /**
     * すべての記事を取得（削除されていない記事のみ）
     */
    @Transactional(readOnly = true)
    public List<ArticleDTO> getAllArticles() {
        List<Article> articles = articleRepository.findAllWithCompany();
        return articles.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * 特定企業の記事を取得
     */
    @Transactional(readOnly = true)
    public List<ArticleDTO> getArticlesByCompany(Long companyId) {
        List<Article> articles = articleRepository.findByCompanyIdWithCompany(companyId);
        return articles.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * キーワードで記事を検索
     */
    @Transactional(readOnly = true)
    public List<ArticleDTO> searchArticles(String keyword) {
        List<Article> articles;
        
        if (keyword == null || keyword.trim().isEmpty()) {
            articles = articleRepository.findByIsDeletedFalseOrderByUpdatedAtDesc();
        } else {
            articles = articleRepository.findByTitleOrContentContaining(keyword.trim());
        }
        
        return articles.stream()
                .map(this::convertToDTOWithCompanyName)
                .collect(Collectors.toList());
    }
    
    /**
     * IDで記事を取得
     */
    @Transactional(readOnly = true)
    public Optional<ArticleDTO> getArticleById(Long id) {
        Optional<Article> article = articleRepository.findByIdAndIsDeletedFalse(id);
        return article.map(this::convertToDTO);
    }
    
    /**
     * 特定企業の特定記事を取得
     */
    @Transactional(readOnly = true)
    public Optional<ArticleDTO> getArticleByCompanyAndId(Long companyId, Long articleId) {
        Optional<Article> article = articleRepository.findByIdAndCompanyIdAndIsDeletedFalse(articleId, companyId);
        return article.map(this::convertToDTO);
    }
    
    /**
     * 記事を新規作成
     */
    public ArticleDTO createArticle(ArticleDTO articleDTO) {
        // 企業の存在確認
        Optional<Company> company = companyRepository.findByIdAndIsWithdrawnFalse(articleDTO.getCompanyId());
        if (!company.isPresent()) {
            throw new IllegalArgumentException("指定された企業が存在しないか、退会済みです。");
        }
        
        Article article = articleDTO.toEntity();
        Article savedArticle = articleRepository.save(article);
        return convertToDTO(savedArticle);
    }
    
    /**
     * 記事を更新
     */
    public Optional<ArticleDTO> updateArticle(Long id, ArticleDTO articleDTO) {
        Optional<Article> existingArticle = articleRepository.findByIdAndIsDeletedFalse(id);
        
        if (existingArticle.isPresent()) {
            Article article = existingArticle.get();
            
            // 更新可能なフィールドのみ更新
            if (articleDTO.getTitle() != null) {
                article.setTitle(articleDTO.getTitle());
            }
            if (articleDTO.getContent() != null) {
                article.setContent(articleDTO.getContent());
            }
            if (articleDTO.getAuthor() != null) {
                article.setAuthor(articleDTO.getAuthor());
            }
            
            Article savedArticle = articleRepository.save(article);
            return Optional.of(convertToDTO(savedArticle));
        }
        
        return Optional.empty();
    }
    
    /**
     * 記事を論理削除
     */
    public boolean deleteArticle(Long id) {
        Optional<Article> existingArticle = articleRepository.findByIdAndIsDeletedFalse(id);
        
        if (existingArticle.isPresent()) {
            Article article = existingArticle.get();
            article.setIsDeleted(true);
            articleRepository.save(article);
            return true;
        }
        
        return false;
    }
    
    /**
     * 特定企業の記事を論理削除
     */
    public boolean deleteArticleByCompany(Long companyId, Long articleId) {
        Optional<Article> existingArticle = articleRepository.findByIdAndCompanyIdAndIsDeletedFalse(articleId, companyId);
        
        if (existingArticle.isPresent()) {
            Article article = existingArticle.get();
            article.setIsDeleted(true);
            articleRepository.save(article);
            return true;
        }
        
        return false;
    }
    
    /**
     * 最新の記事を指定数取得
     */
    @Transactional(readOnly = true)
    public List<ArticleDTO> getRecentArticles(int limit) {
        List<Article> articles = articleRepository.findTopNRecentArticles(limit);
        return articles.stream()
                .map(this::convertToDTOWithCompanyName)
                .collect(Collectors.toList());
    }
    
    /**
     * 特定企業の記事数を取得
     */
    @Transactional(readOnly = true)
    public int getArticleCountByCompany(Long companyId) {
        return articleRepository.countByCompanyIdAndIsDeletedFalse(companyId);
    }
    
    /**
     * EntityをDTOに変換（画像URL付き）
     */
    private ArticleDTO convertToDTO(Article article) {
        ArticleDTO dto = ArticleDTO.fromEntity(article);
        
        // 関連画像を取得してURLを設定
        List<ImageRelation> images = imageRelationRepository.findArticleImages(article.getId());
        List<String> imageUrls = images.stream()
                .map(image -> imageBaseUrl + "/" + image.getImagePath())
                .collect(Collectors.toList());
        dto.setImageUrls(imageUrls);
        
        return dto;
    }
    
    /**
     * EntityをDTOに変換（企業名も含む）
     */
    private ArticleDTO convertToDTOWithCompanyName(Article article) {
        ArticleDTO dto = convertToDTO(article);
        
        // 企業名を取得して設定
        Optional<Company> company = companyRepository.findByIdAndIsWithdrawnFalse(article.getCompanyId());
        company.ifPresent(comp -> dto.setCompanyName(comp.getName()));
        
        return dto;
    }
}