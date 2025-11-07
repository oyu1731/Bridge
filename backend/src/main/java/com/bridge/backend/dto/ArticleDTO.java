package com.bridge.backend.dto;

import com.bridge.backend.entity.Article;
import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.LocalDateTime;
import java.util.List;

public class ArticleDTO {
    private Long id;
    private Long companyId;
    private String companyName; // 企業名（結合情報）
    private String title;
    private String content;
    private String author;
    private Boolean isDeleted;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime updatedAt;
    
    private List<String> imageUrls; // 記事に関連する画像のURL一覧
    
    // デフォルトコンストラクタ
    public ArticleDTO() {
    }
    
    // Entityから変換するコンストラクタ
    public ArticleDTO(Article article) {
        this.id = article.getId();
        this.companyId = article.getCompanyId();
        this.title = article.getTitle();
        this.content = article.getContent();
        this.author = article.getAuthor();
        this.isDeleted = article.getIsDeleted();
        this.createdAt = article.getCreatedAt();
        this.updatedAt = article.getUpdatedAt();
        
        // Company情報がある場合は企業名も設定
        if (article.getCompany() != null) {
            this.companyName = article.getCompany().getName();
        }
    }
    
    // 作成用コンストラクタ
    public ArticleDTO(Long companyId, String title, String content, String author) {
        this.companyId = companyId;
        this.title = title;
        this.content = content;
        this.author = author;
        this.isDeleted = false;
    }
    
    // EntityをDTOに変換するstaticメソッド
    public static ArticleDTO fromEntity(Article article) {
        return new ArticleDTO(article);
    }
    
    // EntityをDTOに変換（企業名付き）
    public static ArticleDTO fromEntityWithCompany(Article article, String companyName) {
        ArticleDTO dto = new ArticleDTO(article);
        dto.setCompanyName(companyName);
        return dto;
    }
    
    // DTOをEntityに変換するメソッド
    public Article toEntity() {
        Article article = new Article();
        article.setId(this.id);
        article.setCompanyId(this.companyId);
        article.setTitle(this.title);
        article.setContent(this.content);
        article.setAuthor(this.author);
        article.setIsDeleted(this.isDeleted != null ? this.isDeleted : false);
        article.setCreatedAt(this.createdAt);
        article.setUpdatedAt(this.updatedAt);
        return article;
    }
    
    // Getter/Setter
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Long getCompanyId() {
        return companyId;
    }
    
    public void setCompanyId(Long companyId) {
        this.companyId = companyId;
    }
    
    public String getCompanyName() {
        return companyName;
    }
    
    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }
    
    public String getTitle() {
        return title;
    }
    
    public void setTitle(String title) {
        this.title = title;
    }
    
    public String getContent() {
        return content;
    }
    
    public void setContent(String content) {
        this.content = content;
    }
    
    public String getAuthor() {
        return author;
    }
    
    public void setAuthor(String author) {
        this.author = author;
    }
    
    public Boolean getIsDeleted() {
        return isDeleted;
    }
    
    public void setIsDeleted(Boolean isDeleted) {
        this.isDeleted = isDeleted;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    public List<String> getImageUrls() {
        return imageUrls;
    }
    
    public void setImageUrls(List<String> imageUrls) {
        this.imageUrls = imageUrls;
    }
}