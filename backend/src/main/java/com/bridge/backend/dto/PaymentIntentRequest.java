package com.bridge.backend.dto;

public class PaymentIntentRequest {
    private Long amount;
    private String currency;
    private String planType;
    private String successUrl;
    private String cancelUrl;

    public Long getAmount() {
        return amount;
    }
    public void setAmount(Long amount) {
        this.amount = amount;
    }

    public String getCurrency() {
        return currency;
    }
    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public String getPlanType() {
        return planType;
    }
    public void setPlanType(String planType) {
        this.planType = planType;
    }

    public String getSuccessUrl() {
        return successUrl;
    }
    public void setSuccessUrl(String successUrl) {
        this.successUrl = successUrl;
    }

    public String getCancelUrl() {
        return cancelUrl;
    }
    public void setCancelUrl(String cancelUrl) {
        this.cancelUrl = cancelUrl;
    }
}
