package com.bridge.backend.service;

import com.bridge.backend.entity.Subscription;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.SubscriptionRepository;
import com.bridge.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
     * 有効なサブスクリプションを取得
     */
    public Optional<Subscription> getActiveSubscriptionByUserId(Integer userId) {
        try {
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isEmpty()) {
                return Optional.empty();
            }

            List<Subscription> activeSubscriptions = subscriptionRepository.findActiveByUserId(userId);
            final LocalDateTime now = LocalDateTime.now();
            Subscription validSubscription = null;

            for (Subscription subscription : activeSubscriptions) {
                if (subscription.getEndDate().isBefore(now)) {
                    if (subscription.getIsPlanStatus()) {
                        subscription.setIsPlanStatus(false);
                        subscriptionRepository.save(subscription);
                    }
                } else {
                    validSubscription = subscription;
                    break;
                }
            }
            return Optional.ofNullable(validSubscription);

        } catch (Exception e) {
            // DBエラー時にControllerのcatchブロックへ飛ばす
            throw new RuntimeException("Database connection error", e);
        }
    }

    /**
     * 加入または更新
     */
    @Transactional
    public Subscription subscribeOrRenewPlan(Integer userId, String planName, Integer durationMonths) {
        try {
            Optional<Subscription> latestOpt = subscriptionRepository.findTopByUserIdOrderByEndDateDesc(userId);
            final LocalDateTime now = LocalDateTime.now();
            Subscription subscription;

            if (latestOpt.isPresent()) {
                subscription = latestOpt.get();
                LocalDateTime startPoint = subscription.getEndDate().isAfter(now) ? subscription.getEndDate() : now;

                subscription.setPlanName(planName);
                subscription.setStartDate(startPoint);
                subscription.setEndDate(startPoint.plusMonths(durationMonths));
                subscription.setIsPlanStatus(true);
            } else {
                subscription = new Subscription();
                subscription.setUserId(userId);
                subscription.setPlanName(planName);
                subscription.setStartDate(now);
                subscription.setEndDate(now.plusMonths(durationMonths));
                subscription.setIsPlanStatus(true);
                subscription.setCreatedAt(now);
            }

            return subscriptionRepository.save(subscription);
        } catch (Exception e) {
            throw new RuntimeException("Database connection error", e);
        }
    }
}