package com.example.bridge.repository;

import com.example.bridge.entity.Company;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * 企業リポジトリ
 */
@Repository
public interface CompanyRepository extends JpaRepository<Company, Integer> {
    Company findById(int id);
}
