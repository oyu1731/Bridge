package com.bridge.backend.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "industries")
public class Industry {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private String industry;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getIndustry() { return industry; }
    public void setIndustry(String industry) { this.industry = industry; }
}