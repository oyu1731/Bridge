package com.bridge.backend.repository;

import com.bridge.backend.entity.ImageRelation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ImageRelationRepository extends JpaRepository<ImageRelation, Long> {
    
    // 特定のターゲット（企業または記事）に関連する画像を取得（削除されていないもののみ）
    List<ImageRelation> findByTargetTypeAndTargetIdAndIsDeletedFalseOrderByDisplayOrder(String targetType, Long targetId);
    
    // 企業に関連する画像を取得
    List<ImageRelation> findByTargetTypeAndTargetIdAndIsDeletedFalseOrderByDisplayOrder(String targetType, Long targetId);
    
    // 記事に関連する画像を取得
    @Query("SELECT ir FROM ImageRelation ir WHERE ir.targetType = 'ARTICLE' AND ir.targetId = :articleId AND ir.isDeleted = false ORDER BY ir.displayOrder")
    List<ImageRelation> findArticleImages(@Param("articleId") Long articleId);
    
    // 企業に関連する画像を取得
    @Query("SELECT ir FROM ImageRelation ir WHERE ir.targetType = 'COMPANY' AND ir.targetId = :companyId AND ir.isDeleted = false ORDER BY ir.displayOrder")
    List<ImageRelation> findCompanyImages(@Param("companyId") Long companyId);
    
    // 特定の画像の表示順序を取得
    Optional<ImageRelation> findByTargetTypeAndTargetIdAndDisplayOrderAndIsDeletedFalse(String targetType, Long targetId, Integer displayOrder);
    
    // 画像パスで検索
    Optional<ImageRelation> findByImagePathAndIsDeletedFalse(String imagePath);
    
    // 特定ターゲットの画像数をカウント（削除されていないもののみ）
    int countByTargetTypeAndTargetIdAndIsDeletedFalse(String targetType, Long targetId);
    
    // 特定ターゲットの最大表示順序を取得
    @Query("SELECT COALESCE(MAX(ir.displayOrder), 0) FROM ImageRelation ir WHERE ir.targetType = :targetType AND ir.targetId = :targetId AND ir.isDeleted = false")
    Integer getMaxDisplayOrder(@Param("targetType") String targetType, @Param("targetId") Long targetId);
    
    // 削除されていない画像のみを取得
    List<ImageRelation> findByIsDeletedFalseOrderByCreatedAtDesc();
}