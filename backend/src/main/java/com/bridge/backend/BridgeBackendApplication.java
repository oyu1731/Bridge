package com.bridge.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;


/**
 * BridgeBackendApplication
 * このクラスはSpring Bootアプリケーションのエントリポイントです。
 *
 * チームメンバーへ:
 *   - `@SpringBootApplication` アノテーションは、Spring Bootアプリケーションを構成するための
 *     主要な設定クラスであることを示します。
 *   - `main` メソッドからアプリケーションが起動します。
 */
@EnableScheduling // スケジューラ有効化
@SpringBootApplication
public class BridgeBackendApplication {
    public static void main(String[] args) {
        SpringApplication.run(BridgeBackendApplication.class, args);
        
    }
}

