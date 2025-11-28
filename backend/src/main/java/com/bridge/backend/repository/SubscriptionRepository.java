package com.bridge.backend.repository;

import com.bridge.backend.entity.Subscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SubscriptionRepository extends JpaRepository<Subscription, Integer> {

	// 最新のサブスクリプションを取得（終了日で降順）
	Optional<Subscription> findTopByUserIdOrderByEndDateDesc(Integer userId);

	// 有効な（加入中の）サブスクリプションを取得
	@Query("SELECT s FROM Subscription s WHERE s.userId = :userId AND s.isPlanStatus = true ORDER BY s.endDate DESC")
	Optional<Subscription> findActiveByUserId(@Param("userId") Integer userId);
}
