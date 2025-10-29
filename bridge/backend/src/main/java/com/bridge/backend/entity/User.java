package com.bridge.backend.entity;

import jakarta.persistence.*; // JPA (Java Persistence API) のアノテーションをインポート

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
    private Integer id; // ユーザーID

    private String name; // ユーザー名
    private String email; // ユーザーメールアドレス

    // Getter / Setter
    // これらのメソッドは、フィールドの値を取得・設定するために使用されます。
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}

