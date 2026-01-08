package com.bridge.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**") // API全体（または /api/**）を対象
                .allowedOrigins("http://localhost:5000") // フロントエンドのURLを明示的に許可
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*") // 必要なヘッダ（Content-Type, Authorizationなど）をすべて許可
                .allowCredentials(true);
    }
}