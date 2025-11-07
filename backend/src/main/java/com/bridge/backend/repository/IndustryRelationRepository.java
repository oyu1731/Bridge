package com.bridge.backend.repository;

import com.bridge.backend.entity.IndustryRelation;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * IndustryRelationRepository
 * このインターフェースは、IndustryRelationエンティティのデータアクセス操作を提供します。
 * Spring Data JPAの `JpaRepository` を継承することで、CRUD操作を自動的に提供します。
 */
public interface IndustryRelationRepository extends JpaRepository<IndustryRelation, Integer> {
}