package com.bridge.backend.service;

import com.bridge.backend.entity.Subscription;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.SubscriptionRepository;
import com.bridge.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional; // トランザクション管理のためインポート

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class SubscriptionService {

    @Autowired
    private SubscriptionRepository subscriptionRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * ユーザーIDに基づいて、現在有効なサブスクリプション情報を取得する。
     * データベースに複数の有効なレコードが存在する場合でも、最も新しい有効なもの1つを返す。
     * また、有効期限(end_date)が過ぎていた場合、is_plan_statusをfalseに更新する。
     *
     * @param userId ユーザーID
     * @return 有効なSubscriptionエンティティ (存在しない場合はOptional.empty())
     */
    public Optional<Subscription> getActiveSubscriptionByUserId(Integer userId) {
        // ユーザーが存在するかどうかを確認
        Optional<User> userOpt = userRepository.findById(userId);
        
        if (userOpt.isPresent()) {
            try {
                // 有効なサブスクリプションのリストを取得（endDateの降順でソートされている）
                // RepositoryのfindActiveByUserIdは、isPlanStatus=trueのものを返す
                List<Subscription> activeSubscriptions = subscriptionRepository.findActiveByUserId(userId);

                final LocalDateTime now = LocalDateTime.now();
                Subscription validSubscription = null;

                // 期限切れのチェックと状態更新
                for (Subscription subscription : activeSubscriptions) {
                    if (subscription.getEndDate().isBefore(now)) {
                        // 1. 有効期限が切れている場合
                        if (subscription.getIsPlanStatus()) {
                            // isPlanStatusがtrueならfalseに更新する
                            subscription.setIsPlanStatus(false);
                            subscriptionRepository.save(subscription);
                            System.out.println("Info: Subscription for user ID " + userId + " (ID: " + subscription.getId() + ") expired and was updated to isPlanStatus=false.");
                        }
                    } else {
                        // 2. 有効期限が切れていない場合
                        // 最も新しい有効なサブスクリプションを採用
                        validSubscription = subscription;
                        break; // 有効なものが見つかったのでループを終了
                    }
                }
                
                if (validSubscription == null) {
                    // 有効期限内のサブスクリプションが見つからなかった場合（無料扱い）
                    return Optional.empty();
                }

                if (activeSubscriptions.size() > 1) {
                    // DBのデータ不整合の警告 (有効なものが複数ある場合)
                    System.err.println("Warning: Multiple active subscriptions found for user ID " + userId + ". Using the most recent (valid) one.");
                }

                return Optional.of(validSubscription);

            } catch (Exception e) {
                System.err.println("Error fetching active subscription for user ID " + userId + ": " + e.getMessage());
                return Optional.empty();
            }
        }
        
        // ユーザーが存在しない場合はOptional.empty()を返す
        return Optional.empty();
    }

    /**
     * 新規加入または既存サブスクリプションの更新を行う。
     * ユーザーに最新のサブスクリプションが存在する場合、そのend_dateを更新（延長）する。
     * 存在しない場合は、新しいサブスクリプションを作成する。
     * * @param userId ユーザーID
     * @param planName プラン名
     * @param durationMonths 購読期間（月単位）
     * @return 更新または作成されたSubscriptionエンティティ
     */
    @Transactional // DB操作を含むためトランザクションを付与
    public Subscription subscribeOrRenewPlan(Integer userId, String planName, Integer durationMonths) {
        
        // 1. 最新のサブスクリプションを取得
        // is_plan_statusに関わらず、最もendDateが新しいレコードを探す（更新の起点とするため）
        Optional<Subscription> latestSubscriptionOpt = subscriptionRepository.findTopByUserIdOrderByEndDateDesc(userId);
        
        final LocalDateTime now = LocalDateTime.now();
        Subscription subscription;

        if (latestSubscriptionOpt.isPresent()) {
            // 2. 既存のサブスクリプションがある場合（更新/延長）
            subscription = latestSubscriptionOpt.get();
            LocalDateTime currentEndDate = subscription.getEndDate();
            
            // 延長の起点を決定: 
            // 既存のend_dateが現在時刻より後の場合はそのend_dateを起点とする（延長）
            // 既存のend_dateが現在時刻より前の場合は現在時刻を起点とする（再開）
            LocalDateTime renewalStartPoint = currentEndDate.isAfter(now) ? currentEndDate : now;

            // 新しい終了日を計算
            LocalDateTime newEndDate = renewalStartPoint.plusMonths(durationMonths);

            // サブスクリプションの内容を更新
            subscription.setPlanName(planName);
            subscription.setStartDate(renewalStartPoint); // 延長の開始日を更新
            subscription.setEndDate(newEndDate);
            subscription.setIsPlanStatus(true); // 確実に有効にする

            System.out.println("Info: User ID " + userId + " subscription renewed/extended. New end date: " + newEndDate);

        } else {
            // 3. 既存のサブスクリプションがない場合（新規加入）
            LocalDateTime startDate = now;
            LocalDateTime endDate = now.plusMonths(durationMonths);

            subscription = new Subscription();
            subscription.setUserId(userId);
            subscription.setPlanName(planName);
            subscription.setStartDate(startDate);
            subscription.setEndDate(endDate);
            subscription.setIsPlanStatus(true);
            subscription.setCreatedAt(now);

            System.out.println("Info: User ID " + userId + " new subscription created. End date: " + endDate);
        }

        // DBに保存（更新または新規作成）
        return subscriptionRepository.save(subscription);
    }
}