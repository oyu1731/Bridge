package com.bridge.backend.repository;

import com.bridge.backend.entity.Company;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CompanyRepository extends JpaRepository<Company, Integer> {
    
    // 退会していない企業のみを取得
    List<Company> findByIsWithdrawnFalseOrderByCreatedAtDesc();
    
    // 企業名での検索（部分一致、大小文字を区別しない）
    List<Company> findByNameContainingIgnoreCaseAndIsWithdrawnFalseOrderByCreatedAtDesc(String name);
    
    // 住所での検索（部分一致、大小文字を区別しない）
    List<Company> findByAddressContainingIgnoreCaseAndIsWithdrawnFalseOrderByCreatedAtDesc(String address);
    
    // 企業名または住所での検索
    @Query("SELECT c FROM Company c WHERE (UPPER(c.name) LIKE UPPER(CONCAT('%', :keyword, '%')) OR " +
           "UPPER(c.address) LIKE UPPER(CONCAT('%', :keyword, '%'))) AND c.isWithdrawn = false " +
           "ORDER BY c.createdAt DESC")
    List<Company> findByNameOrAddressContaining(@Param("keyword") String keyword);
    
    // IDで検索（退会していない企業のみ）
    Optional<Company> findByIdAndIsWithdrawnFalse(Integer id);
    
    // 企業の存在確認（退会していない企業のみ）
    boolean existsByIdAndIsWithdrawnFalse(Integer id);
    
    // プランステータスで検索
    List<Company> findByPlanStatusAndIsWithdrawnFalseOrderByCreatedAtDesc(Integer planStatus);
}