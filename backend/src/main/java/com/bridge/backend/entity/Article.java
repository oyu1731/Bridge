package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Articleエンティティ
 * このクラスは、データベースの `articles` テーブルに対応するエンティティです。
 * 記事情報を管理します。
 */
@Entity
@Table(name = "articles")
public class Article {
        // 業界リスト（複数業界対応）
        @ElementCollection(fetch = FetchType.LAZY)
        @CollectionTable(name = "article_industries", joinColumns = @JoinColumn(name = "article_id"))
        @Column(name = "industry")
        private List<String> industries;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // 記事ID (主キー、自動生成)

    @Column(name = "title", nullable = false, length = 40)
    private String title; // 記事タイトル

    @Column(name = "description", nullable = false, length = 2000)
    private String description; // 記事説明

    @Column(name = "company_id", nullable = false)
    private Integer companyId; // 企業ID

    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted; // 削除済みフラグ

    @Column(name = "total_likes", nullable = false)
    private Integer totalLikes; // 総いいね数

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt; // 作成日時

    @Column(name = "photo1_id")
    private Integer photo1Id; // 写真1ID

    @Column(name = "photo2_id")
    private Integer photo2Id; // 写真2ID

    @Column(name = "photo3_id")
    private Integer photo3Id; // 写真3ID

    // 多対多の関係：記事とタグ（articles_tag中間テーブル経由）
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "articles_tag",
        joinColumns = @JoinColumn(name = "article_id"),
        inverseJoinColumns = @JoinColumn(name = "tag_id")
    )
    private List<Tag> tags;

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public Article() {
        this.industries = null;
    }

    /**
     * 引数付きコンストラクタ
     * @param id 記事ID
     * @param title 記事タイトル
     * @param description 記事説明
     * @param companyId 企業ID
     * @param isDeleted 削除済みフラグ
     * @param totalLikes 総いいね数
     * @param createdAt 作成日時
     * @param photo1Id 写真1ID
     * @param photo2Id 写真2ID
     * @param photo3Id 写真3ID
     */
    public Article(Integer id, String title, String description, Integer companyId, Boolean isDeleted, Integer totalLikes, LocalDateTime createdAt, Integer photo1Id, Integer photo2Id, Integer photo3Id) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.companyId = companyId;
        this.isDeleted = isDeleted;
        this.totalLikes = totalLikes;
        this.createdAt = createdAt;
        this.photo1Id = photo1Id;
        this.photo2Id = photo2Id;
        this.photo3Id = photo3Id;
        this.industries = null;
    }

    public List<String> getIndustries() {
        return industries;
    }

    public void setIndustries(List<String> industries) {
        this.industries = industries;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (isDeleted == null) {
            isDeleted = false;
        }
        if (totalLikes == null) {
            totalLikes = 0;
        }
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
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

    public Integer getCompanyId() {
        return companyId;
    }

    public void setCompanyId(Integer companyId) {
        this.companyId = companyId;
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public void setIsDeleted(Boolean deleted) {
        isDeleted = deleted;
    }

    public Integer getTotalLikes() {
        return totalLikes;
    }

    public void setTotalLikes(Integer totalLikes) {
        this.totalLikes = totalLikes;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
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

    public List<Tag> getTags() {
        return tags;
    }

    public void setTags(List<Tag> tags) {
        this.tags = tags;
    }
}