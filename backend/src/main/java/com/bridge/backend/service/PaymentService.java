package com.bridge.backend.service;

import com.stripe.Stripe;
import com.stripe.exception.StripeException;
import com.stripe.model.Customer;
import com.stripe.model.EphemeralKey;
import com.stripe.model.PaymentIntent;
import com.stripe.model.checkout.Session;
import com.stripe.param.CustomerCreateParams;
import com.stripe.param.EphemeralKeyCreateParams;
import com.stripe.param.PaymentIntentCreateParams;
import com.stripe.param.checkout.SessionCreateParams;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class PaymentService {

    @Value("${stripe.secretKey}")
    private String stripeSecretKey;

    // 方法1: Checkout Sessionを使用する方法（推奨）
    public Map<String, String> createCheckoutSession(Long amount, String currency, String planType, String successUrl, String cancelUrl) throws StripeException {
        Stripe.apiKey = stripeSecretKey;

        // 金額の検証
        long expectedAmount;
        switch (planType) {
            case "個人基本プラン":
                expectedAmount = 500L;
                break;
            case "企業基本プラン":
                expectedAmount = 5000L;
                break;
            case "企業プレミアムプラン":
                expectedAmount = 10000L;
                break;
            default:
                throw new IllegalArgumentException("Invalid plan type: " + planType);
        }

        if (!amount.equals(expectedAmount)) {
            throw new IllegalArgumentException("Amount mismatch for plan type " + planType + ". Expected: " + expectedAmount + ", Received: " + amount);
        }

        // Checkout Sessionのパラメータ作成
        SessionCreateParams params = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.PAYMENT)
                .setSuccessUrl(successUrl)
                .setCancelUrl(cancelUrl)
                .addLineItem(
                    SessionCreateParams.LineItem.builder()
                        .setQuantity(1L)
                        .setPriceData(
                            SessionCreateParams.LineItem.PriceData.builder()
                                .setCurrency(currency)
                                .setUnitAmount(amount * 100) // 日本円なので100倍
                                .setProductData(
                                    SessionCreateParams.LineItem.PriceData.ProductData.builder()
                                        .setName(planType)
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

    // 方法2: Payment Intent + 最新のEphemeral Key作成方法
    public Map<String, String> createPaymentIntent(Long amount, String currency, String planType) throws StripeException {
        Stripe.apiKey = stripeSecretKey;

        // 金額の検証
        long expectedAmount;
        switch (planType) {
            case "個人基本プラン":
                expectedAmount = 500L;
                break;
            case "企業基本プラン":
                expectedAmount = 5000L;
                break;
            case "企業プレミアムプラン":
                expectedAmount = 10000L;
                break;
            default:
                throw new IllegalArgumentException("Invalid plan type: " + planType);
        }

        long stripeAmount = amount * 100L;

        if (amount.longValue() != expectedAmount) {
            throw new IllegalArgumentException("Amount mismatch for plan type " + planType + ". Expected: " + expectedAmount + ", Received: " + amount);
        }

        // 顧客作成
        CustomerCreateParams customerParams = CustomerCreateParams.builder()
                .setDescription("Customer for " + planType)
                .build();
        Customer customer = Customer.create(customerParams);

        // エフェメラルキーの作成（最新の方法）
        EphemeralKeyCreateParams ephemeralKeyParams = EphemeralKeyCreateParams.builder()
                .setCustomer(customer.getId())
                .setStripeVersion("2022-11-15") // バージョンを直接指定
                .build();
        
        EphemeralKey ephemeralKey = EphemeralKey.create(ephemeralKeyParams);

        // Payment Intent作成
        PaymentIntentCreateParams params =
                PaymentIntentCreateParams.builder()
                        .setAmount(stripeAmount)
                        .setCurrency(currency)
                        .setCustomer(customer.getId())
                        .setAutomaticPaymentMethods(
                                PaymentIntentCreateParams.AutomaticPaymentMethods.builder()
                                        .setEnabled(true)
                                        .build()
                        )
                        .build();

        PaymentIntent paymentIntent = PaymentIntent.create(params);

        Map<String, String> responseData = new HashMap<>();
        responseData.put("clientSecret", paymentIntent.getClientSecret());
        responseData.put("customerId", customer.getId());
        responseData.put("ephemeralKey", ephemeralKey.getSecret());
        return responseData;
    }
}