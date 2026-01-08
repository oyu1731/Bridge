package com.bridge.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Userエンティティ
 * このクラスは、データベースの `users` テーブルに対応するエンティティです。
 * JPA (Java Persistence API) を使用して、Javaオブジェクトとデータベースのレコードをマッピングします。
 *
 * チームメンバーへ:
 *   - `@Entity`: このクラスがJPAエンティティであることを示します。
 *   - `@Table(name = "users")`: このエンティティがマッピングされるデータベーステーブル名を指定します。
 *   - `@Id`: 主キーとなるフィールドを示します。
 *   - `@GeneratedValue(strategy = GenerationType.IDENTITY)`: 主キーの生成戦略を指定します。
 *     `IDENTITY` は、データベースのAUTO_INCREMENT機能を利用することを示します。
 */
@Entity
@Table(name = "users") // このエンティティがマッピングされるテーブル名を指定
public class User {
    @Id // 主キー
    @GeneratedValue(strategy = GenerationType.IDENTITY) // データベースのAUTO_INCREMENTを利用
    private Integer id; // ユーザーID (主キー、自動生成)

    @Column(name = "nickname", nullable = false, length = 100)
    private String nickname; // ニックネーム

    @Column(name = "type", nullable = false)
    private Integer type; // ユーザータイプ: 1=学生、2=社会人、3=企業、4=管理者

    @Column(name = "password", nullable = false)
    private String password; // パスワード (ハッシュ化)

    @Column(name = "phone_number", nullable = false, length = 15)
    private String phoneNumber; // 電話番号 (ハイフン込の文字列として保存)

    @Column(name = "email", nullable = false)
    private String email; // メールアドレス

    @Column(name = "company_id")
    private Integer companyId; // 所属企業ID (企業ユーザーの場合)

    @Column(name = "report_count", nullable = false)
    private Integer reportCount; // 通報回数

    @Column(name = "plan_status", nullable = false, length = 20)
    private String planStatus; // プランステータス (例: '無料', 'プレミアム')

    @Column(name = "is_withdrawn", nullable = false)
    private Boolean isWithdrawn; // 退会済みフラグ

    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted; // 退会済みフラグ

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt; // 作成日時

    @Column(name = "society_history")
    private Integer societyHistory; // 社会人経験年数 (社会人ユーザーの場合)

    @Column(name = "icon")
    private Integer icon; // アイコンID

    @Column(name = "announcement_deletion", nullable = false)
    private Integer announcementDeletion; // お知らせ削除フラグ: 1=新規お知らせなし、2=新規お知らせあり

    @Column(name = "token", nullable = false)
    private Integer token; // 面接練習やメール添削で使用

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (reportCount == null) {
            reportCount = 0;
        }
        if (planStatus == null || planStatus.isEmpty()) {
            planStatus = "無料";
        }
        if (isWithdrawn == null) {
            isWithdrawn = false;
        }
        if (isDeleted == null) {
            isDeleted = false;
        }
        if (announcementDeletion == null) {
            announcementDeletion = 1;
        }
        if (token == null) {
            token = 50;
        }
    }

    public User() {
    }

    public User(Integer id, String nickname, Integer type, String password, String phoneNumber, String email, Integer companyId, Integer reportCount, String planStatus, Boolean isWithdrawn, Boolean isDeleted, LocalDateTime createdAt, Integer societyHistory, Integer icon, Integer announcementDeletion, Integer token) {
        this.id = id;
        this.nickname = nickname;
        this.type = type;
        this.password = password;
        this.phoneNumber = phoneNumber;
        this.email = email;
        this.companyId = companyId;
        this.reportCount = reportCount;
        this.planStatus = planStatus;
        this.isWithdrawn = isWithdrawn;
        this.isDeleted = isDeleted;
        this.createdAt = createdAt;
        this.societyHistory = societyHistory;
        this.icon = icon;
        this.announcementDeletion = announcementDeletion;
        this.token = token;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public Integer getType() {
        return type;
    }

    public void setType(Integer type) {
        this.type = type;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Integer getCompanyId() {
        return companyId;
    }

    public void setCompanyId(Integer companyId) {
        this.companyId = companyId;
    }

    public Integer getReportCount() {
        return reportCount;
    }

    public void setReportCount(Integer reportCount) {
        this.reportCount = reportCount;
    }

    public String getPlanStatus() {
        return planStatus;
    }

    public void setPlanStatus(String planStatus) {
        this.planStatus = planStatus;
    }

    public Boolean getIsWithdrawn() {
        return isWithdrawn;
    }

    public void setIsWithdrawn(Boolean withdrawn) {
        isWithdrawn = withdrawn;
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public void setIsDeleted(Boolean deleted) {
        isDeleted = deleted;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Integer getSocietyHistory() {
        return societyHistory;
    }

    public void setSocietyHistory(Integer societyHistory) {
        this.societyHistory = societyHistory;
    }

    public Integer getIcon() {
        return icon;
    }

    public void setIcon(Integer icon) {
        this.icon = icon;
    }

    public Integer getAnnouncementDeletion() {
        return announcementDeletion;
    }

    public void setAnnouncementDeletion(Integer announcementDeletion) {
        this.announcementDeletion = announcementDeletion;
    }

    public Integer getToken() {
        return token;
    }

    public void setToken(Integer token) {
        this.token = token;
    }
}

