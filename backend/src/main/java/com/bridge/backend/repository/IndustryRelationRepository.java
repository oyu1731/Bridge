package com.bridge.backend.repository;

import com.bridge.backend.entity.IndustryRelation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.List;

/**
 * IndustryRelationRepository
 * このインターフェースは、IndustryRelationエンティティのデータアクセス操作を提供します。
 * Spring Data JPAの `JpaRepository` を継承することで、CRUD操作を自動的に提供します。
 */
public interface IndustryRelationRepository extends JpaRepository<IndustryRelation, Integer> {
    
    /**
     * ユーザーIDとタイプに基づいて業界関係を検索
     * @param userId ユーザーID
     * @param type タイプ（3=企業の業界）
     * @return 業界関係
     */
    Optional<IndustryRelation> findByUserIdAndType(Integer userId, int type);

    List<IndustryRelation> findByUserId(Integer userid);

    List<IndustryRelation> deleteByUserId(Integer id);
}