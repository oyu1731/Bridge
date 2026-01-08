package com.bridge.backend.dto;

import java.util.List;

/**
 * ArticleDTO
 * 記事データの転送用オブジェクトです。
 */
public class ArticleDTO {
    private Integer id;
    private Integer companyId;
    private String companyName;
    private String title;
    private String description;
    private Integer totalLikes;
    private Boolean isDeleted;
    private String createdAt;
    private Integer photo1Id;
    private Integer photo2Id;
    private Integer photo3Id;
    private List<String> tags; // タグ名のリスト
    private String industry; // 会社の業界名
    private Boolean isLikedByUser; // 現在のユーザーがいいねしているか

    // デフォルトコンストラクタ
    public ArticleDTO() {
    }

    // 全フィールドのコンストラクタ
    public ArticleDTO(Integer id, Integer companyId, String companyName, String title, 
                     String description, Integer totalLikes, Boolean isDeleted, 
                     String createdAt, Integer photo1Id, Integer photo2Id, Integer photo3Id,
                     List<String> tags, String industry) {
        this.id = id;
        this.companyId = companyId;
        this.companyName = companyName;
        this.title = title;
        this.description = description;
        this.totalLikes = totalLikes;
        this.isDeleted = isDeleted;
        this.createdAt = createdAt;
        this.photo1Id = photo1Id;
        this.photo2Id = photo2Id;
        this.photo3Id = photo3Id;
        this.tags = tags;
        this.industry = industry;
    }

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getCompanyId() {
        return companyId;
    }

    public void setCompanyId(Integer companyId) {
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

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Integer getTotalLikes() {
        return totalLikes;
    }

    public void setTotalLikes(Integer totalLikes) {
        this.totalLikes = totalLikes;
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public void setIsDeleted(Boolean isDeleted) {
        this.isDeleted = isDeleted;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public Integer getPhoto1Id() {
        return photo1Id;
    }

    public void setPhoto1Id(Integer photo1Id) {
        this.photo1Id = photo1Id;
    }

    public Integer getPhoto2Id() {
        return photo2Id;
    }

    public void setPhoto2Id(Integer photo2Id) {
        this.photo2Id = photo2Id;
    }

    public Integer getPhoto3Id() {
        return photo3Id;
    }

    public void setPhoto3Id(Integer photo3Id) {
        this.photo3Id = photo3Id;
    }

    public List<String> getTags() {
        return tags;
    }

    public void setTags(List<String> tags) {
        this.tags = tags;
    }

    public String getIndustry() {
        return industry;
    }

    public void setIndustry(String industry) {
        this.industry = industry;
    }

    public Boolean getIsLikedByUser() {
        return isLikedByUser;
    }

    public void setIsLikedByUser(Boolean isLikedByUser) {
        this.isLikedByUser = isLikedByUser;
    }

    @Override
    public String toString() {
        return "ArticleDTO{" +
                "id=" + id +
                ", companyId=" + companyId +
                ", companyName='" + companyName + '\'' +
                ", title='" + title + '\'' +
                ", description='" + description + '\'' +
                ", totalLikes=" + totalLikes +
                ", isDeleted=" + isDeleted +
                ", createdAt='" + createdAt + '\'' +
                ", photo1Id=" + photo1Id +
                ", photo2Id=" + photo2Id +
                ", photo3Id=" + photo3Id +
                ", tags=" + tags +
                ", industry='" + industry + '\'' +
                '}';
    }
}