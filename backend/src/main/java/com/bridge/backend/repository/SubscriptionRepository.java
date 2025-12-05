package com.bridge.backend.repository;

import com.bridge.backend.entity.Subscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List; // java.util.List をインポート
import java.util.Optional;

@Repository
public interface SubscriptionRepository extends JpaRepository<Subscription, Integer> {

	// 最新のサブスクリプションを取得（終了日で降順）
	Optional<Subscription> findTopByUserIdOrderByEndDateDesc(Integer userId);

	/**
	 * 有効な（加入中の）サブスクリプションをすべて取得する。
	 * データベースに複数の有効なレコードが存在する場合に備え、Listで取得するよう修正。
	 * @param userId ユーザーID
	 * @return 有効なサブスクリプションのリスト（終了日降順）
	 */
	@Query("SELECT s FROM Subscription s WHERE s.userId = :userId AND s.isPlanStatus = true ORDER BY s.endDate DESC")
	List<Subscription> findActiveByUserId(@Param("userId") Integer userId);
}