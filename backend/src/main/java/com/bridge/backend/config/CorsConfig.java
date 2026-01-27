package com.bridge.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

@Configuration
public class CorsConfig {

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        
        // 許可するオリジン（開発・本番両対応）
        configuration.setAllowedOrigins(Arrays.asList(
            "http://localhost:3000",      // Flutter Web ローカル開発
            "http://localhost:8080",      // バックエンド自体
            "http://localhost:5000",      // 別ポート対応
            "https://api.bridge-tesg.com" // 本番環境
        ));
        
        // 許可するメソッド
        configuration.setAllowedMethods(Arrays.asList(
            "GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"
        ));
        
        // 許可するヘッダー
        configuration.setAllowedHeaders(Arrays.asList("*"));
        
        // リクエストにクレデンシャルを含めることを許可
        configuration.setAllowCredentials(true);
        
        // キャッシュ時間（秒）
        configuration.setMaxAge(3600L);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
