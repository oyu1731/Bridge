package com.bridge.backend.entity;

import jakarta.persistence.*;

/**
 * Tagエンティティ
 * このクラスは、データベースの `tag` テーブルに対応するエンティティです。
 * タグ情報を管理します。
 */
@Entity
@Table(name = "tag")
public class Tag {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // タグID (主キー、自動生成)

    @Column(name = "tag", nullable = false, length = 50)
    private String tag; // タグ名

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public Tag() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id タグID
     * @param tag タグ名
     */
    public Tag(Integer id, String tag) {
        this.id = id;
        this.tag = tag;
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getTag() {
        return tag;
    }

    public void setTag(String tag) {
        this.tag = tag;
    }
}