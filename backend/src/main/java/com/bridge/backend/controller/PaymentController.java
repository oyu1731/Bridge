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
            Long amount = Long.valueOf(request.get("amount").toString());
            String currency = request.get("currency").toString();
            String userType = request.get("userType").toString();
            String successUrl = request.get("successUrl").toString();
            String cancelUrl = request.get("cancelUrl").toString();
            Integer userId = Integer.valueOf(request.get("userId").toString());

            Map<String, String> response = paymentService.createCheckoutSession(
                    amount, currency, userType, successUrl, cancelUrl, userId
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
                
                // 各種データの取得（nullの可能性があるため安全に取得）
                String clientReferenceId = session.getClientReferenceId();
                Map<String, String> metadata = session.getMetadata();
                String userType = (metadata != null) ? metadata.get("userType") : "standard";

                System.out.println("Session ID: " + session.getId());
                System.out.println("Client Reference ID (User ID): " + clientReferenceId);
                System.out.println("User Type: " + userType);

                // clientReferenceId が null または空文字でないかチェック
                if (clientReferenceId != null && !clientReferenceId.trim().isEmpty()) {
                    try {
                        Integer userId = Integer.valueOf(clientReferenceId);
                        paymentService.handleSuccessfulPayment(userId, userType);
                        System.out.println("Successfully processed payment for User ID: " + userId);
                    } catch (NumberFormatException e) {
                        System.err.println("Error: client_reference_id is not a valid integer: " + clientReferenceId);
                    }
                } else {
                    // stripe trigger 等のテストデータではここに入る
                    System.out.println("Notice: Client Reference ID is null or empty. Skipping database update.");
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
}