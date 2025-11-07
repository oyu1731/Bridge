package com.bridge.backend.entity;

import jakarta.persistence.*;

/**
 * PhoneExerciseエンティティ
 * このクラスは、データベースの `phone_exercises` テーブルに対応するエンティティです。
 * 電話対応の練習問題情報を管理します。
 */
@Entity
@Table(name = "phone_exercises")
public class PhoneExercise {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // 電話対応練習ID (主キー、自動生成)

    @Column(name = "example", nullable = false, length = 255)
    private String example; // 例題内容

    @Column(name = "difficulty", nullable = false)
    private Integer difficulty; // 難易度: 1=簡単、2=普通、3=難しい

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public PhoneExercise() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id 電話対応練習ID
     * @param example 例題内容
     * @param difficulty 難易度
     */
    public PhoneExercise(Integer id, String example, Integer difficulty) {
        this.id = id;
        this.example = example;
        this.difficulty = difficulty;
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getExample() {
        return example;
    }

    public void setExample(String example) {
        this.example = example;
    }

    public Integer getDifficulty() {
        return difficulty;
    }

    public void setDifficulty(Integer difficulty) {
        this.difficulty = difficulty;
    }
}