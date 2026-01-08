package com.bridge.backend.controller;

import com.bridge.backend.dto.PaymentIntentRequest;
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
            String userType = request.get("userType").toString(); // ← 修正
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
        try {
            Event event = Webhook.constructEvent(payload, sigHeader, webhookSecret);

            if ("checkout.session.completed".equals(event.getType())) {
                System.out.println("Processing checkout.session.completed event.");
                Session session = (Session) event.getData().getObject();
                Integer userId = Integer.valueOf(session.getClientReferenceId());
                String userType = session.getMetadata().get("userType");

                System.out.println("User ID from session: " + userId);
                System.out.println("User type from metadata: " + userType);
                paymentService.handleSuccessfulPayment(userId, userType);
                System.out.println("Finished processing checkout.session.completed event.");
            }

            return ResponseEntity.ok("Webhook handled");
        } catch (StripeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Webhook error: " + e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Internal server error: " + e.getMessage());
        }
    }
}
