package com.bridge.backend.controller;

import com.bridge.backend.service.PaymentService;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
import com.stripe.model.checkout.Session;
import com.stripe.net.Webhook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/v1/payment")
public class PaymentController {

    private final PaymentService paymentService;

    @Value("${stripe.webhook.secret}")
    private String webhookSecret;

    @Autowired
    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping("/checkout-session")
    public ResponseEntity<Map<String, String>> createCheckoutSession(@RequestBody Map<String, Object> request) {
        try {
            // 必須パラメータのnullチェック
            if (request.get("amount") == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "amount is required"));
            }
            if (request.get("currency") == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "currency is required"));
            }
            if (request.get("userType") == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "userType is required"));
            }
            if (request.get("successUrl") == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "successUrl is required"));
            }
            if (request.get("cancelUrl") == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "cancelUrl is required"));
            }

            Long amount = Long.valueOf(request.get("amount").toString());
            String currency = request.get("currency").toString();
            String userType = request.get("userType").toString();
            String successUrl = request.get("successUrl").toString();
            String cancelUrl = request.get("cancelUrl").toString();

            // userId は個人ユーザー用。企業サインアップ時は null/未提供でもよい
            Integer userId = null;
            if (request.get("userId") != null) {
                userId = Integer.valueOf(request.get("userId").toString());
            }

            // メタデータ（company 登録に必要な情報を含める）
            Map<String, String> metadata = new HashMap<>();
            if ("company".equalsIgnoreCase(userType)) {
                Object companyName = request.get("companyName");
                Object companyEmail = request.get("companyEmail");
                if (companyName == null || companyEmail == null) {
                    return ResponseEntity.badRequest().body(Map.of("error", "companyName and companyEmail are required for company signups"));
                }
                metadata.put("userType", "company");
                metadata.put("companyName", companyName.toString());
                metadata.put("companyEmail", companyEmail.toString());

                // 任意で tempId やその他情報を格納可能
                if (request.get("tempId") != null) {
                    metadata.put("tempId", request.get("tempId").toString());
                }
            } else {
                metadata.put("userType", userType);
            }

            Map<String, String> response = paymentService.createCheckoutSession(
                    amount, currency, userType, successUrl, cancelUrl, userId, metadata
            );

            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/webhook")
    public ResponseEntity<String> handleStripeWebhook(@RequestBody String payload, @RequestHeader("Stripe-Signature") String sigHeader) {
        System.out.println("--- Webhookイベント受信開始 ---");

        try {
            // イベントの署名検証
            Event event = Webhook.constructEvent(payload, sigHeader, webhookSecret);
            System.out.println("Webhook Event Type: " + event.getType());

            if ("checkout.session.completed".equals(event.getType())) {
                System.out.println("Processing checkout.session.completed event.");
                Session session = (Session) event.getData().getObject();

                String clientReferenceId = session.getClientReferenceId();
                Map<String, String> metadata = session.getMetadata();
                String userType = (metadata != null && metadata.get("userType") != null) ? metadata.get("userType") : "standard";

                System.out.println("Session ID: " + session.getId());
                System.out.println("Client Reference ID (User ID): " + clientReferenceId);
                System.out.println("User Type: " + userType);

                if ("company".equalsIgnoreCase(userType)) {
                    // 企業サインアップ: metadata から会社情報を取り出してアカウント作成
                    String companyName = (metadata != null) ? metadata.get("companyName") : null;
                    String companyEmail = (metadata != null) ? metadata.get("companyEmail") : null;
                    if (companyName != null && companyEmail != null) {
                        paymentService.createCompanyAccount(companyName, companyEmail, metadata);
                        System.out.println("Created company account for: " + companyEmail);
                    } else {
                        System.err.println("Missing company metadata: cannot create account");
                    }
                } else {
                    // 個人ユーザー処理（既存ロジック）
                    if (clientReferenceId != null && !clientReferenceId.trim().isEmpty()) {
                        try {
                            Integer userId = Integer.valueOf(clientReferenceId);
                            paymentService.handleSuccessfulPayment(userId, userType);
                            System.out.println("Successfully processed payment for User ID: " + userId);
                        } catch (NumberFormatException e) {
                            System.err.println("Error: client_reference_id is not a valid integer: " + clientReferenceId);
                        }
                    } else {
                        System.out.println("Notice: Client Reference ID is null or empty. Skipping database update.");
                    }
                }

                System.out.println("Finished processing checkout.session.completed event.");
            } else {
                System.out.println("Unhandled event type: " + event.getType());
            }

            System.out.println("--- Webhook処理完了 ---");
            return ResponseEntity.ok("Webhook handled");

        } catch (StripeException e) {
            System.err.println("Stripe Webhook Signature Verification Failed: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Webhook error: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("Internal server error during webhook processing: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Internal server error: " + e.getMessage());
        }
    }

    @GetMapping("/session/{sessionId}")
    public ResponseEntity<?> getUserFromSession(@PathVariable String sessionId) {
        try {
            java.util.Map<String, Object> info = paymentService.getUserInfoFromSession(sessionId);
            if (info == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(java.util.Map.of("error", "user_not_found"));
            }
            return ResponseEntity.ok(info);
        } catch (com.stripe.exception.StripeException se) {
            System.err.println("Stripe error retrieving session: " + se.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(java.util.Map.of("error", se.getMessage()));
        } catch (Exception e) {
            System.err.println("Error retrieving session user: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(java.util.Map.of("error", e.getMessage()));
        }
    }
}