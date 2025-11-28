package com.bridge.backend.service;

import com.stripe.Stripe;
import com.stripe.exception.StripeException;
import com.stripe.model.Customer;
import com.stripe.model.EphemeralKey;
import com.stripe.model.PaymentIntent;
import com.stripe.param.PaymentIntentCreateParams;
import com.stripe.param.CustomerCreateParams;
import com.stripe.param.EphemeralKeyCreateParams;
import com.stripe.RequestOptions;
import com.stripe.param.PaymentIntentCreateParams.PaymentMethodOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class PaymentService {

    @Value("${stripe.secretKey}")
    private String stripeSecretKey;

    public Map<String, String> createPaymentIntent(Long amount, String currency, String planType) throws StripeException {
        Stripe.apiKey = stripeSecretKey;

        // 金額の検証
        long expectedAmount;
        switch (planType) {
            case "個人基本プラン": // 学生・社会人
                expectedAmount = 50000L; // 500円 * 100
                break;
            case "企業基本プラン": // 企業
                expectedAmount = 500000L; // 5000円 * 100
                break;
            case "企業プレミアムプラン": // 企業プレミアムプラン
                expectedAmount = 1000000L; // 10000円 * 100
                break;
            default:
                throw new IllegalArgumentException("Invalid plan type: " + planType);
        }

        if (amount.longValue() != expectedAmount) {
            throw new IllegalArgumentException("Amount mismatch for plan type " + planType + ". Expected: " + expectedAmount + ", Received: " + amount);
        }

        // 顧客の作成または取得（今回は仮で新規作成）
        CustomerCreateParams customerParams = CustomerCreateParams.builder()
                .setDescription("Customer for " + planType)
                .build();
        Customer customer = Customer.create(customerParams);

        // エフェメラルキーの作成
        EphemeralKeyCreateParams ephemeralKeyParams = EphemeralKeyCreateParams.builder()
                .setCustomer(customer.getId())
                .build();
        // RequestOptionsを使用してStripe-Versionを設定
        EphemeralKey ephemeralKey = EphemeralKey.create(ephemeralKeyParams, RequestOptions.builder().setStripeVersion("2022-11-15").build()); // APIバージョンを2022-11-15に更新


        PaymentIntentCreateParams params =
                PaymentIntentCreateParams.builder()
                        .setAmount(amount)
                        .setCurrency(currency)
                        .setCustomer(customer.getId())
                        .setPaymentMethodOptions(
                                PaymentIntentCreateParams.PaymentMethodOptions.builder()
                                        .setCard(PaymentIntentCreateParams.PaymentMethodOptions.Card.builder()
                                                .setRequestThreeDSecure(PaymentIntentCreateParams.PaymentMethodOptions.Card.RequestThreeDSecure.ANY)
                                                .build())
                                        .build())
                        .build();

        PaymentIntent paymentIntent = PaymentIntent.create(params);

        Map<String, String> responseData = new HashMap<>();
        responseData.put("clientSecret", paymentIntent.getClientSecret());
        responseData.put("customerId", customer.getId());
        responseData.put("customerEphemeralKeySecret", ephemeralKey.getSecret());
        return responseData;
    }
}