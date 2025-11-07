package com.bridge.backend.entity;

import jakarta.persistence.*;

/**
 * Photoエンティティ
 * このクラスは、データベースの `photos` テーブルに対応するエンティティです。
 * 写真情報を管理します。
 */
@Entity
@Table(name = "photos")
public class Photo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // 写真ID (主キー、自動生成)

    @Column(name = "photo_path", nullable = false, length = 255)
    private String photoPath; // 写真パス

    @Column(name = "user_id")
    private Integer userId; // ユーザーID

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public Photo() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id 写真ID
     * @param photoPath 写真パス
     * @param userId ユーザーID
     */
    public Photo(Integer id, String photoPath, Integer userId) {
        this.id = id;
        this.photoPath = photoPath;
        this.userId = userId;
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getPhotoPath() {
        return photoPath;
    }

    public void setPhotoPath(String photoPath) {
        this.photoPath = photoPath;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }
}