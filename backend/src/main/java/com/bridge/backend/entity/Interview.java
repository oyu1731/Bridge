package com.bridge.backend.entity;

import jakarta.persistence.*;

/**
 * Interviewエンティティ
 * このクラスは、データベースの `interviews` テーブルに対応するエンティティです。
 * 面接の質問情報を管理します。
 */
@Entity
@Table(name = "interviews")
public class Interview {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // 面接ID (主キー、自動生成)

    @Column(name = "question", nullable = false, length = 255)
    private String question; // 質問内容

    @Column(name = "type", nullable = false)
    private Integer type; // 面接タイプ: 1=一般、2=カジュアル、3=圧迫

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public Interview() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id 面接ID
     * @param question 質問内容
     * @param type 面接タイプ
     */
    public Interview(Integer id, String question, Integer type) {
        this.id = id;
        this.question = question;
        this.type = type;
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

    public Integer getType() {
        return type;
    }

    public void setType(Integer type) {
        this.type = type;
    }
}