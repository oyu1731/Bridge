package com.example.bridge.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

/**
 * エラーハンドリングのテスト用コントローラー
 * 開発環境でのみ使用
 */
@RestController
@RequestMapping("/api/test")
public class TestErrorController {

    /**
     * 400 Bad Request をテスト
     */
    @GetMapping("/400")
    public ResponseEntity<?> testError400() {
        return ResponseEntity.badRequest()
                .body(Map.of("error", "Bad Request - Invalid input parameter"));
    }

    /**
     * 401 Unauthorized をテスト
     */
    @GetMapping("/401")
    public ResponseEntity<?> testError401() {
        return ResponseEntity.status(401)
                .body(Map.of("error", "Unauthorized - Authentication required"));
    }

    /**
     * 403 Forbidden をテスト
     */
    @GetMapping("/403")
    public ResponseEntity<?> testError403() {
        return ResponseEntity.status(403)
                .body(Map.of("error", "Forbidden - Access denied"));
    }

    /**
     * 404 Not Found をテスト
     */
    @GetMapping("/404")
    public ResponseEntity<?> testError404() {
        return ResponseEntity.notFound().build();
    }

    /**
     * 500 Internal Server Error をテスト
     * RuntimeExceptionを発生させてSpringのエラーハンドリングにより500を返す
     */
    @GetMapping("/500")
    public ResponseEntity<?> testError500() {
        // 意図的にエラーを発生させて500エラーを返す
        Integer.parseInt("invalid-number");  // NumberFormatException を発生
        return ResponseEntity.ok(Map.of("error", "This should not be reached"));
    }

    /**
     * 成功レスポンス（200 OK）をテスト
     */
    @GetMapping("/success")
    public ResponseEntity<?> testSuccess() {
        return ResponseEntity.ok(Map.of(
                "message", "Success",
                "status", "OK",
                "timestamp", System.currentTimeMillis()
        ));
    }
}
