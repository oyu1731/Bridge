package com.bridge.backend.dto;

/**
 * TagDTO
 * タグデータの転送用オブジェクトです。
 */
public class TagDTO {
    private Integer id;
    private String tag;

    // デフォルトコンストラクタ
    public TagDTO() {
    }

    // 全フィールドのコンストラクタ
    public TagDTO(Integer id, String tag) {
        this.id = id;
        this.tag = tag;
    }

    // Getters and Setters
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

    @Override
    public String toString() {
        return "TagDTO{" +
                "id=" + id +
                ", tag='" + tag + '\'' +
                '}';
    }
}