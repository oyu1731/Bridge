package com.bridge.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "industry_relations")
@Data
public class IndustryRelation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 1=希望業界
    private int type;

    // 登録されたユーザーID
    @Column(name = "user_id")
    private Long userId;

    // industries テーブルの ID
    @Column(name = "target_id")
    private Long targetId;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
