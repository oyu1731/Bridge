package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * ArticleTagエンティティ
 * このクラスは、データベースの `articles_tag` テーブルに対応するエンティティです。
 * 記事とタグの関連付けを管理します。
 */
@Entity
@Table(name = "articles_tag")
public class ArticleTag {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // 記事タグ関連ID (主キー、自動生成)

    @Column(name = "article_id", nullable = false)
    private Integer articleId; // 記事ID

    @Column(name = "tag_id", nullable = false)
    private Integer tagId; // タグID

    @Column(name = "creation_date")
    private LocalDateTime creationDate; // 作成日時

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public ArticleTag() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id 記事タグ関連ID
     * @param articleId 記事ID
     * @param tagId タグID
     * @param creationDate 作成日時
     */
    public ArticleTag(Integer id, Integer articleId, Integer tagId, LocalDateTime creationDate) {
        this.id = id;
        this.articleId = articleId;
        this.tagId = tagId;
        this.creationDate = creationDate;
    }

    @PrePersist
    protected void onCreate() {
        creationDate = LocalDateTime.now();
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getArticleId() {
        return articleId;
    }

    public void setArticleId(Integer articleId) {
        this.articleId = articleId;
    }

    public Integer getTagId() {
        return tagId;
    }

    public void setTagId(Integer tagId) {
        this.tagId = tagId;
    }

    public LocalDateTime getCreationDate() {
        return creationDate;
    }

    public void setCreationDate(LocalDateTime creationDate) {
        this.creationDate = creationDate;
    }
}