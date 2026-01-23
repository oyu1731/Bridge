package com.bridge.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

import com.bridge.backend.websocket.SimpleSocketHandler;
import com.bridge.backend.websocket.ThreadIdInterceptor;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final SimpleSocketHandler handler;
    private final ThreadIdInterceptor interceptor;

    public WebSocketConfig(SimpleSocketHandler handler, ThreadIdInterceptor interceptor) {
        this.handler = handler;
        this.interceptor = interceptor;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(handler, "/ws/chat/{threadId}")
                .addInterceptors(interceptor) // ← threadId を取り出すインターセプターを追加
                .setAllowedOrigins("*");
    }
}
