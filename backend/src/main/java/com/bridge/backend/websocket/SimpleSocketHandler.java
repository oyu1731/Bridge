package com.bridge.backend.websocket;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class SimpleSocketHandler extends TextWebSocketHandler {

    // threadId → セッション一覧
    private final Map<String, Set<WebSocketSession>> roomSessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String threadId = (String) session.getAttributes().get("threadId");

        roomSessions.putIfAbsent(threadId, ConcurrentHashMap.newKeySet());
        roomSessions.get(threadId).add(session);

        System.out.println("WebSocket connected to thread " + threadId);
    }

    @Override
    public void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String threadId = (String) session.getAttributes().get("threadId");

        // 同じ threadId のルームのみに送信
        for (WebSocketSession s : roomSessions.getOrDefault(threadId, Set.of())) {
            if (s.isOpen()) {
                s.sendMessage(message);
            }
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String threadId = (String) session.getAttributes().get("threadId");

        roomSessions.getOrDefault(threadId, Set.of()).remove(session);

        System.out.println("WebSocket disconnected from thread " + threadId);
    }
    
    /**
     * 特定のスレッドに人狼ゲーム募集の状態変更を配信
     */
    public void broadcastWerewolfUpdate(String threadId, String message) throws Exception {
        TextMessage textMessage = new TextMessage(message);
        for (WebSocketSession s : roomSessions.getOrDefault(threadId, Set.of())) {
            if (s.isOpen()) {
                s.sendMessage(textMessage);
            }
        }
    }
}
