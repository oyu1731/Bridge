// src/main/java/com/bridge/backend/config/RestTemplateConfig.java
package com.bridge.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;
import java.time.Duration;

@Configuration
public class RestTemplateConfig {

    @Bean
    public RestTemplate restTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        
        // 最適化されたタイムアウト設定
        factory.setConnectTimeout(Duration.ofSeconds(60));  // 接続タイムアウト
        factory.setReadTimeout(Duration.ofSeconds(90));     // 読み取りタイムアウト
        
        return new RestTemplate(factory);
    }
}