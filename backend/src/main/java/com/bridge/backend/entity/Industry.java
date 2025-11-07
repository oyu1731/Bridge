package com.bridge.backend.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "industries")
public class Industry {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // 業界ID (主キー、自動生成)

    @Column(name = "industry", nullable = false, length = 50)
    private String industry; // 業界名

    /**
     * JPAが必要とする引数なしコンストラクタ
     */
    public Industry() {
    }

    /**
     * Controller側で使う引数付きコンストラクタ
     * @param id 業界ID
     * @param industry 業界名
     */
    public Industry(Integer id, String industry) {
        this.id = id;
        this.industry = industry;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getIndustry() {
        return industry;
    }

    public void setIndustry(String industry) {
        this.industry = industry;
    }
}


