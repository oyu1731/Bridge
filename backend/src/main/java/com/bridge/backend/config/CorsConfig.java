package com.bridge.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

/**
 * CorsConfig
 * 静的リソース含む全エンドポイントにCORSヘッダーを付与する設定
 */
@Configuration
@Profile("dev")
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();
        
        // 全オリジンを許可（開発用）
        config.addAllowedOriginPattern("*");
        
        // 全HTTPメソッドを許可
        config.addAllowedMethod("*");
        
        // 全ヘッダーを許可
        config.addAllowedHeader("*");
        
        // クレデンシャルを許可しない（allowedOriginPattern=*と併用時はfalse必須）
        config.setAllowCredentials(false);
        
        // 全パスに適用
        source.registerCorsConfiguration("/**", config);
        
        return new CorsFilter(source);
    }
}
