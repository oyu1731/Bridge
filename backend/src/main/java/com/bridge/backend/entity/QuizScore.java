package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * QuizScoreエンティティ
 * このクラスは、データベースの `quiz_scores` テーブルに対応するエンティティです。
 * 一問一答のスコア情報を管理します。
 */
@Entity
@Table(name = "quiz_scores")
public class QuizScore {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // クイズスコアID (主キー、自動生成)

    @Column(name = "user_id", nullable = false)
    private Integer userId; // ユーザーID

    @Column(name = "score", nullable = false)
    private Integer score; // スコア

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt; // 作成日時

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public QuizScore() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id クイズスコアID
     * @param userId ユーザーID
     * @param score スコア
     * @param createdAt 作成日時
     */
    public QuizScore(Integer id, Integer userId, Integer score, LocalDateTime createdAt) {
        this.id = id;
        this.userId = userId;
        this.score = score;
        this.createdAt = createdAt;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public Integer getScore() {
        return score;
    }

    public void setScore(Integer score) {
        this.score = score;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}