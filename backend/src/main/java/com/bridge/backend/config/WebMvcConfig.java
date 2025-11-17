package com.bridge.backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * WebMvcConfig
 * 静的リソース（アップロードされた画像）の提供を設定
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Value("${file.upload-dir:uploads/photos}")
    private String uploadDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // アップロードされた画像を /uploads/photos/** で提供
        Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
        String uploadPathString = uploadPath.toUri().toString();
        
        registry.addResourceHandler("/uploads/photos/**")
                .addResourceLocations(uploadPathString);
    }
}
