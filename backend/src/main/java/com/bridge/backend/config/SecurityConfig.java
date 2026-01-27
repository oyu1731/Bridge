package com.bridge.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors().configurationSource(corsConfigurationSource()).and() // CORS設定を適用
            .csrf().disable()
            .authorizeHttpRequests(auth -> auth.anyRequest().permitAll());
        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        // 許可するオリジン（開発・本番環境対応）
        configuration.setAllowedOriginPatterns(Arrays.asList(
            "https://bridge-915bd.web.app",    // Firebase Hosting
            "https://bridge-tesg.com",         // 本番ドメイン
            "https://api.bridge-tesg.com",     // API ドメイン
            "http://localhost:3000",           // Flutter Web ローカル開発
            "http://localhost:5000",           // 別ポート対応
            "http://localhost:8080"            // バックエンド自体
        ));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true); // Cookieや認証ヘッダーを許可
        configuration.setMaxAge(3600L); // キャッシュ時間（秒）

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}