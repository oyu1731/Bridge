package com.example.bridge.controller;

import com.example.bridge.dto.CompanySignUpRequest;
import com.example.bridge.service.CompanyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 企業ユーザー登録コントローラー
 */
@RestController
@RequestMapping("/api/companies")
public class CompanyController {
    
    @Autowired
    private CompanyService companyService;
    
    /**
     * 企業と企業ユーザーを登録
     * 
     * @param request 企業・ユーザー登録リクエスト
     * @return 登録されたユーザー情報
     */
    @PostMapping("/signup")
    public ResponseEntity<?> signUpCompany(@RequestBody CompanySignUpRequest request) {
        try {
            // バリデーション
            if (request.getCompanyName() == null || request.getCompanyName().isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "企業名は必須です"));
            }
            if (request.getUserEmail() == null || request.getUserEmail().isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "メールアドレスは必須です"));
            }
            if (request.getUserPassword() == null || request.getUserPassword().isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "パスワードは必須です"));
            }
            
            // サービス呼び出し（トランザクション内で処理）
            Map<String, Object> result = companyService.registerCompanyWithUser(request);
            
            System.out.println("✅ 企業登録完了: " + result);
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            System.out.println("❌ 企業登録エラー: " + e.getMessage());
            e.printStackTrace();
            
            // メール重複エラー
            if (e.getMessage().contains("既に登録されています")) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
            }
            
            // その他のエラー
            return ResponseEntity.status(500)
                .body(Map.of("error", "企業登録に失敗しました", "detail", e.getMessage()));
        }
    }
}
