package com.bridge.backend.entity;

import jakarta.persistence.*;

/**
 * QuizQuestionエンティティ
 * このクラスは、データベースの `quiz_questions` テーブルに対応するエンティティです。
 * 一問一答の質問情報を管理します。
 */
@Entity
@Table(name = "quiz_questions")
public class QuizQuestion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // クイズ質問ID (主キー、自動生成)

    @Column(name = "question", nullable = false, length = 100)
    private String question; // 質問内容

    @Column(name = "is_answer", nullable = false)
    private Boolean isAnswer; // 回答フラグ (true=正解、false=不正解)

    @Column(name = "expanation", nullable = false, length = 255)
    private String explanation; // 解説

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public QuizQuestion() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id クイズ質問ID
     * @param question 質問内容
     * @param isAnswer 回答フラグ
     * @param explanation 解説
     */
    public QuizQuestion(Integer id, String question, Boolean isAnswer, String explanation) {
        this.id = id;
        this.question = question;
        this.isAnswer = isAnswer;
        this.explanation = explanation;
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getQuestion() {
        return question;
    }

    public void setQuestion(String question) {
        this.question = question;
    }

    public Boolean getIsAnswer() {
        return isAnswer;
    }

    public void setIsAnswer(Boolean answer) {
        isAnswer = answer;
    }

    public String getExplanation() {
        return explanation;
    }

    public void setExplanation(String explanation) {
        this.explanation = explanation;
    }
}