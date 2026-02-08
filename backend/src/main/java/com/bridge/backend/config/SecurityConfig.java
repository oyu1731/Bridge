package com.bridge.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;

@Configuration
@EnableWebSecurity // これを追加して、明示的にセキュリティを有効化します
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configure(http)) // 最新の Lambda 形式
            .csrf(csrf -> csrf.disable())       // 最新の Lambda 形式
            .authorizeHttpRequests(auth -> auth
                .anyRequest().permitAll()       // すべての通信を許可
            );
        return http.build();
    }
}