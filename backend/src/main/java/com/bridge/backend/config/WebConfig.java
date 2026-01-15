package com.bridge.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
        public void addCorsMappings(CorsRegistry registry) {
            registry.addMapping("/**")
                    .allowedOriginPatterns(
                        "https://bridge-tesg.com",           // あなたのドメイン
                        "https://*.bridge-tesg.com",         // サブドメイン(apiなど)
                        "https://bridge-915bd.web.app",     // Firebaseの本番URL
                        "http://localhost:*"                 // ローカルテスト用も残してOK
                    )
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                    .allowedHeaders("*")
                    .allowCredentials(true);
        }   
    }