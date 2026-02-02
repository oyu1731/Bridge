package com.bridge.backend.service;

import com.stripe.Stripe;
import com.stripe.exception.StripeException;
import com.stripe.model.checkout.Session;
import com.bridge.backend.entity.Company;
import com.bridge.backend.entity.Subscription;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.CompanyRepository;
import com.bridge.backend.repository.SubscriptionRepository;
import com.bridge.backend.repository.UserRepository;
import com.stripe.param.checkout.SessionCreateParams;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
public class PaymentService {

    @Value("${stripe.secretKey}")
    private String stripeSecretKey;

    private final UserRepository userRepository;
    private final CompanyRepository companyRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final UserService userService;
    private final com.bridge.backend.repository.TempCompanySignupRepository tempSignupRepository;

    @Autowired
    public PaymentService(UserRepository userRepository, CompanyRepository companyRepository, SubscriptionRepository subscriptionRepository, UserService userService, com.bridge.backend.repository.TempCompanySignupRepository tempSignupRepository) {
        this.userRepository = userRepository;
        this.companyRepository = companyRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.userService = userService;
        this.tempSignupRepository = tempSignupRepository;
    }

    // Retrieve user info from a Checkout Session id. Used by frontend to map session -> user.
    public java.util.Map<String, Object> getUserInfoFromSession(String sessionId) throws com.stripe.exception.StripeException {
        Stripe.apiKey = stripeSecretKey;
        Session session = Session.retrieve(sessionId);

        // Try metadata first (company flow)
        java.util.Map<String, String> metadata = session.getMetadata();
        if (metadata != null && metadata.get("companyEmail") != null) {
            String email = metadata.get("companyEmail");
            return userRepository.findByEmail(email)
                    .map(user -> {
                        java.util.Map<String, Object> map = new java.util.HashMap<>();
                        map.put("id", user.getId());
                        map.put("nickname", user.getNickname());
                        map.put("email", user.getEmail());
                        map.put("type", user.getType());
                        map.put("planStatus", user.getPlanStatus());
                        return map;
                    })
                    .orElse(null);
        }

        // Next try client_reference_id (personal users)
        String clientRef = session.getClientReferenceId();
        if (clientRef != null && !clientRef.trim().isEmpty()) {
            try {
                Integer userId = Integer.valueOf(clientRef);
                return userRepository.findById(userId)
                        .map(user -> {
                            java.util.Map<String, Object> map = new java.util.HashMap<>();
                            map.put("id", user.getId());
                            map.put("nickname", user.getNickname());
                            map.put("email", user.getEmail());
                            map.put("type", user.getType());
                            map.put("planStatus", user.getPlanStatus());
                            return map;
                        })
                        .orElse(null);
            } catch (NumberFormatException nfe) {
                return null;
            }
        }

        return null;
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

        // userType を英語/日本語どちらでも扱えるように正規化してプラン名を決定
        String planName = mapUserTypeToPlanName(userType);

        SessionCreateParams.Builder paramsBuilder = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.PAYMENT)
                .setSuccessUrl(successUrl)
                .setCancelUrl(cancelUrl)
                .putMetadata("userType", userType);

        // userId が null の場合は client_reference_id を設定しない（"null" が入らないようにする）
        if (userId != null) {
            paramsBuilder.setClientReferenceId(String.valueOf(userId));
        }

        SessionCreateParams params = paramsBuilder
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

    // 既存の createCheckoutSession に metadata を追加するオーバーロード
    public Map<String, String> createCheckoutSession(Long amount, String currency, String userType, String successUrl, String cancelUrl, Integer userId, Map<String, String> metadata) throws StripeException {
        Stripe.apiKey = stripeSecretKey;

        if (userType == null || userType.isEmpty()) {
            throw new IllegalArgumentException("Invalid user type: " + userType);
        }

        // userType を英語/日本語どちらでも扱えるように正規化してプラン名を決定
        String planName = mapUserTypeToPlanName(userType);

        SessionCreateParams.Builder paramsBuilder = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.PAYMENT)
                .setSuccessUrl(successUrl)
                .setCancelUrl(cancelUrl)
                .putMetadata("userType", userType);

        // userId が null の場合は client_reference_id を設定しない
        if (userId != null) {
            paramsBuilder.setClientReferenceId(String.valueOf(userId));
        }

        // metadata が null でない場合、その内容をセッションに追加
        if (metadata != null) {
            for (Map.Entry<String, String> entry : metadata.entrySet()) {
                paramsBuilder.putMetadata(entry.getKey(), entry.getValue());
            }
        }

        SessionCreateParams params = paramsBuilder
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

    // 企業アカウント作成（Webhook から呼ばれる）→ 作成されたユーザーID を返す
    @Transactional
    public Integer createCompanyAccount(String companyName, String companyEmail, Map<String, String> metadata) {
        System.out.println("Creating company account for: " + companyName + ", Email: " + companyEmail);

        if (metadata != null) {
            for (Map.Entry<String, String> entry : metadata.entrySet()) {
                System.out.println("Metadata - " + entry.getKey() + ": " + entry.getValue());
            }
        }

        // 既存ユーザーがいるか確認
        // まず、metadata に tempId があれば一時登録から本登録を行う
        if (metadata != null && metadata.get("tempId") != null) {
            try {
                Integer tempId = Integer.valueOf(metadata.get("tempId"));
                return tempSignupRepository.findById(tempId).map(temp -> {
                    try {
                        String email = temp.getEmail();
                        if (email != null && userRepository.existsByEmail(email)) {
                            // 既存ユーザーを企業として更新し、サブスクリプションを作成
                            return userRepository.findByEmail(email).map(existing -> {
                                existing.setType(3);
                                existing.setPlanStatus("プレミアム");
                                existing.setToken((existing.getToken() != null ? existing.getToken() : 0) + 500);
                                userRepository.save(existing);

                                Subscription subscription = new Subscription();
                                subscription.setUserId(existing.getId());
                                subscription.setPlanName("企業プレミアム");
                                subscription.setStartDate(java.time.LocalDateTime.now());
                                subscription.setEndDate(java.time.LocalDateTime.now().plusYears(1));
                                subscription.setIsPlanStatus(true);
                                subscription.setCreatedAt(java.time.LocalDateTime.now());
                                subscriptionRepository.save(subscription);
                                System.out.println("✅ Updated existing user and created subscription for email: " + email + ", userId=" + existing.getId());
                                tempSignupRepository.deleteById(tempId);
                                return existing.getId();
                            }).orElse(null);
                        } else {
                            com.bridge.backend.dto.UserDto dto = new com.bridge.backend.dto.UserDto();
                            dto.setType(3);
                            dto.setEmail(temp.getEmail());
                            dto.setNickname(temp.getNickname() != null ? temp.getNickname() : temp.getCompanyName());
                            dto.setPassword(temp.getPassword());
                            dto.setPhoneNumber(temp.getPhoneNumber());
                            dto.setCompanyName(temp.getCompanyName());
                            dto.setCompanyAddress(temp.getCompanyAddress());
                            dto.setCompanyPhoneNumber(temp.getCompanyPhoneNumber());

                            User created = userService.createUser(dto);
                            System.out.println("✅ Created company user from temp signup id=" + created.getId());
                            tempSignupRepository.deleteById(tempId);
                            return created.getId();
                        }
                    } catch (Exception ex) {
                        System.err.println("Error creating user from temp signup: " + ex.getMessage());
                        return null;
                    }
                }).orElse(null);
            } catch (NumberFormatException nfe) {
                System.err.println("Invalid tempId in metadata: " + metadata.get("tempId"));
            }
        }

        if (companyEmail != null && userRepository.existsByEmail(companyEmail)) {
            // 既存ユーザーをアップデート（企業ユーザーとしてマークし、サブスクリプションを追加）
            Integer userId = userRepository.findByEmail(companyEmail).map(user -> {
                user.setPlanStatus("プレミアム");
                user.setToken((user.getToken() != null ? user.getToken() : 0) + 500);
                // type を 3 (企業) に設定
                user.setType(3);

                // ✅ 企業情報を作成して companyId を設定
                if (user.getCompanyId() == null) {
                    Company company = new Company();
                    company.setName(companyName != null ? companyName : companyEmail);
                    company.setAddress(metadata != null && metadata.get("companyAddress") != null ? metadata.get("companyAddress") : "");
                    company.setPhoneNumber(metadata != null && metadata.get("companyPhone") != null ? metadata.get("companyPhone") : "");
                    company.setDescription("");
                    company.setPlanStatus(1); // 1=プレミアム、2=無料
                    company.setIsWithdrawn(false);
                    company.setCreatedAt(java.time.LocalDateTime.now());

                    Company savedCompany = companyRepository.save(company);
                    user.setCompanyId(savedCompany.getId());
                    System.out.println("✅ Created company for existing user: companyId=" + savedCompany.getId());
                }

                userRepository.save(user);

                // サブスクリプションを作成
                Subscription subscription = new Subscription();
                subscription.setUserId(user.getId());
                subscription.setPlanName("企業プレミアム");
                subscription.setStartDate(java.time.LocalDateTime.now());
                subscription.setEndDate(java.time.LocalDateTime.now().plusYears(1));
                subscription.setIsPlanStatus(true);
                subscription.setCreatedAt(java.time.LocalDateTime.now());
                subscriptionRepository.save(subscription);
                System.out.println("✅ Updated existing user and created subscription for email: " + companyEmail + ", userId=" + user.getId());
                return user.getId();
            }).orElse(null);
            return userId;
        }

        // 新規ユーザー作成: UserService#createUser を利用する
        try {
            com.bridge.backend.dto.UserDto dto = new com.bridge.backend.dto.UserDto();
            // 企業ユーザーの型は 3
            dto.setType(3);
            dto.setEmail(companyEmail);
            // ニックネームは会社名を使用
            dto.setNickname(companyName != null ? companyName : companyEmail);

            // 一時パスワードを生成して設定（ログに出力はするがメール送信は行わない）
            String tempPassword = java.util.UUID.randomUUID().toString().replaceAll("-", "").substring(0, 12);
            dto.setPassword(tempPassword);

            // 企業用の情報を DTO にセット
            dto.setCompanyName(companyName);
            // 連絡先が metadata に入っていれば使う
            if (metadata != null) {
                if (metadata.get("companyPhone") != null) dto.setCompanyPhoneNumber(metadata.get("companyPhone"));
                if (metadata.get("companyAddress") != null) dto.setCompanyAddress(metadata.get("companyAddress"));
            }

            User created = userService.createUser(dto);
            System.out.println("✅ Created new company user id=" + created.getId() + " email=" + created.getEmail());
            System.out.println("Temporary password (please deliver securely): " + tempPassword);
            return created.getId();
        } catch (Exception e) {
            System.err.println("Error creating company account: " + e.getMessage());
            throw e;
        }
    }

    @Transactional
    public void handleSuccessfulPayment(Integer userId, String userType) {
        System.out.println("--- DB更新処理開始 ---");
        System.out.println("handleSuccessfulPayment called with userId: " + userId + ", userType: " + userType);

        // 1. userType の null チェック（ガード節）
        // stripe trigger 等で null が来る場合に備え、デフォルト値を設定
        String safeUserType = (userType == null) ? "社会人" : userType;

        // 2. ユーザーを検索
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Invalid user ID: " + userId + ". User not found."));
        System.out.println("User found: " + user.getId() + ", current plan status: " + user.getPlanStatus());

        // 3. ユーザーのプランステータスを更新
        System.out.println("1. Updating user plan status to プレミアム for userId: " + userId);
        user.setPlanStatus("プレミアム");
        // 現在のトークン量を取得し、500を加算する（nullの場合は0からスタート）
        Integer currentToken = (user.getToken() != null) ? user.getToken() : 0;
        user.setToken(currentToken + 500);
        userRepository.save(user);
        System.out.println("   -> User status updated successfully. New plan status: " + user.getPlanStatus());

        // 4. 購読レコードを作成・保存
        Subscription subscription = new Subscription();
        subscription.setUserId(userId);
        subscription.setStartDate(LocalDateTime.now());
        subscription.setIsPlanStatus(true);
        subscription.setCreatedAt(LocalDateTime.now());

        // switch 文に渡す前に null を回避した safeUserType を使用する
        switch (safeUserType) {
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
                throw new IllegalArgumentException("Invalid user type received: " + safeUserType);
        }

        System.out.println("   -> Subscription plan details set. PlanName: " + subscription.getPlanName() + ", EndDate: " + subscription.getEndDate());

        subscriptionRepository.save(subscription);
        System.out.println("2. Subscription record created successfully. Subscription ID: " + subscription.getId());
        System.out.println("--- DB更新処理完了 ---");
    }

    // helper: userType を正規化してプラン名を返す
    private String mapUserTypeToPlanName(String userType) {
        String key = userType.toLowerCase();
        if (key.contains("学") || key.contains("student")) {
            return "学生プレミアム";
        } else if (key.contains("社") || key.contains("professional") || key.contains("worker") || key.contains("社会")) {
            return "社会人プレミアム";
        } else if (key.contains("企") || key.contains("company")) {
            return "企業プレミアム";
        } else {
            throw new IllegalArgumentException("Invalid user type: " + userType);
        }
    }
}