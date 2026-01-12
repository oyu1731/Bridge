package com.bridge.backend.service;

import com.stripe.Stripe;
import com.stripe.exception.StripeException;
import com.stripe.model.checkout.Session;
import com.bridge.backend.entity.Subscription;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.SubscriptionRepository;
import com.bridge.backend.repository.UserRepository;
import com.stripe.param.checkout.SessionCreateParams;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional; // [1] トランザクションをインポート

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
public class PaymentService {
    // ... (createCheckoutSession メソッドは変更なし)

    @Value("${stripe.secretKey}")
    private String stripeSecretKey;

    private final UserRepository userRepository;
    private final SubscriptionRepository subscriptionRepository;

    @Autowired
    public PaymentService(UserRepository userRepository, SubscriptionRepository subscriptionRepository) {
        this.userRepository = userRepository;
        this.subscriptionRepository = subscriptionRepository;
    }

    /**
     * Stripe Checkout セッション作成
     */
    public Map<String, String> createCheckoutSession(Long amount, String currency, String userType,
                                                     String successUrl, String cancelUrl, Integer userId) throws StripeException {
        Stripe.apiKey = stripeSecretKey;

        if (userType == null || userType.isEmpty()) {
            throw new IllegalArgumentException("Invalid user type: " + userType);
        }

        String planName = "";
        switch (userType) {
            case "学生":
                planName = "学生プレミアム";
                break;
            case "社会人":
                planName = "社会人プレミアム";
                break;
            case "企業":
                planName = "企業プレミアム";
                break;
            default:
                throw new IllegalArgumentException("Invalid user type: " + userType);
        }


        // Stripe Checkout セッション作成
        SessionCreateParams params = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.PAYMENT)
                .setSuccessUrl(successUrl)
                .setCancelUrl(cancelUrl)
                .setClientReferenceId(String.valueOf(userId))
                .putMetadata("userType", userType)
                .addLineItem(
                        SessionCreateParams.LineItem.builder()
                                .setQuantity(1L)
                                .setPriceData(
                                        SessionCreateParams.LineItem.PriceData.builder()
                                                .setCurrency(currency)
                                                .setUnitAmount(amount) 
                                                .setProductData(
                                                        SessionCreateParams.LineItem.PriceData.ProductData.builder()
                                                                .setName(planName)
                                                                .build()
                                                )
                                                .build()
                                )
                                .build()
                )
                .build();

        Session session = Session.create(params);

        Map<String, String> responseData = new HashMap<>();
        responseData.put("url", session.getUrl());
        responseData.put("sessionId", session.getId());
        return responseData;
    }

    @Transactional // [2] トランザクション境界を定義
    public void handleSuccessfulPayment(Integer userId, String userType) {
        System.out.println("--- DB更新処理開始 ---");
        System.out.println("handleSuccessfulPayment called with userId: " + userId + ", userType: " + userType);
        
        // ユーザーを検索し、存在しない場合は例外をスロー（Controllerに500を返させる）
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Invalid user ID: " + userId + ". User not found."));
        System.out.println("User found: " + user.getId() + ", current plan status: " + user.getPlanStatus());

        // 1. ユーザーのプランステータスを更新
        System.out.println("1. Updating user plan status to プレミアム for userId: " + userId);
        user.setPlanStatus("プレミアム");
        userRepository.save(user);
        System.out.println("   -> User status updated successfully. New plan status: " + user.getPlanStatus());

        // 2. 購読レコードを作成・保存
        Subscription subscription = new Subscription();
        subscription.setUserId(userId);
        subscription.setStartDate(LocalDateTime.now());
        subscription.setIsPlanStatus(true);
        subscription.setCreatedAt(LocalDateTime.now());
        System.out.println("   -> Initializing new subscription record. UserId: " + subscription.getUserId() + ", StartDate: " + subscription.getStartDate());


        switch (userType) {
            case "学生":
                subscription.setPlanName("学生プレミアム");
                subscription.setEndDate(LocalDateTime.now().plusMonths(1));
                break;
            case "社会人":
                subscription.setPlanName("社会人プレミアム");
                subscription.setEndDate(LocalDateTime.now().plusMonths(1));
                break;
            case "企業":
                subscription.setPlanName("企業プレミアム");
                subscription.setEndDate(LocalDateTime.now().plusYears(1));
                break;
            default:
                // ここで例外をスローすると、トランザクションがロールバックされる
                throw new IllegalArgumentException("Invalid user type received from Stripe metadata: " + userType);
        }
        System.out.println("   -> Subscription plan details set. PlanName: " + subscription.getPlanName() + ", EndDate: " + subscription.getEndDate());

        subscriptionRepository.save(subscription);
        System.out.println("2. Subscription record created successfully. Subscription ID: " + subscription.getId());
        System.out.println("--- DB更新処理完了 ---");
    }
}