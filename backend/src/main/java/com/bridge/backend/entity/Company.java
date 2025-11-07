package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Companyエンティティ
 * このクラスは、データベースの `companies` テーブルに対応するエンティティです。
 * 企業情報を管理します。
 */
@Entity
@Table(name = "companies")
public class Company {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // 企業ID (主キー、自動生成)

    @Column(name = "name", nullable = false, length = 150)
    private String name; // 企業名

    @Column(name = "address", nullable = false, length = 255)
    private String address; // 住所

    @Column(name = "phone_number", nullable = false, length = 15)
    private String phoneNumber; // 電話番号 (ハイフン込の文字列として保存)

    @Column(name = "description", length = 255)
    private String description; // 企業説明

    @Column(name = "plan_status", nullable = false)
    private Integer planStatus; // プランステータス: 1=加入中、2=中断中

    @Column(name = "is_withdrawn", nullable = false)
    private Boolean isWithdrawn; // 退会済みフラグ

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt; // 作成日時

    @Column(name = "photo_id")
    private Integer photoId; // 写真ID

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public Company() {
    }

    /**
     * 引数付きコンストラクタ
     * @param id 企業ID
     * @param name 企業名
     * @param address 住所
     * @param phoneNumber 電話番号
     * @param description 企業説明
     * @param planStatus プランステータス
     * @param isWithdrawn 退会済みフラグ
     * @param createdAt 作成日時
     * @param photoId 写真ID
     */
    public Company(Integer id, String name, String address, String phoneNumber, String description, Integer planStatus, Boolean isWithdrawn, LocalDateTime createdAt, Integer photoId) {
        this.id = id;
        this.name = name;
        this.address = address;
        this.phoneNumber = phoneNumber;
        this.description = description;
        this.planStatus = planStatus;
        this.isWithdrawn = isWithdrawn;
        this.createdAt = createdAt;
        this.photoId = photoId;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (isWithdrawn == null) {
            isWithdrawn = false;
        }
    }

    // ゲッターとセッター
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Integer getPlanStatus() {
        return planStatus;
    }

    public void setPlanStatus(Integer planStatus) {
        this.planStatus = planStatus;
    }

    public Boolean getIsWithdrawn() {
        return isWithdrawn;
    }

    public void setIsWithdrawn(Boolean withdrawn) {
        isWithdrawn = withdrawn;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Integer getPhotoId() {
        return photoId;
    }

    public void setPhotoId(Integer photoId) {
        this.photoId = photoId;
    }
}