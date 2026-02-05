package com.example.bridge.controller;

import com.example.bridge.service.ArticleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 記事コントローラー
 */
@RestController
@RequestMapping("/api/articles")
public class ArticleController {
    
    @Autowired
    private ArticleService articleService;
    
    /**
     * 企業記事を投稿
     * 
     * @param userId ユーザーID
     * @param title 記事タイトル
     * @param content 記事内容
     * @return 作成された記事
     */
    @PostMapping("/post")
    public ResponseEntity<?> postArticle(
            @RequestParam Integer userId,
            @RequestParam String title,
            @RequestParam String content) {
        try {
            // バリデーション
            if (title == null || title.isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "記事タイトルは必須です"));
            }
            if (content == null || content.isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "記事内容は必須です"));
            }
            
            var article = articleService.postCompanyArticle(userId, title, content);
            
            System.out.println("✅ 記事投稿完了: articleId=" + article.getId());
            return ResponseEntity.ok(Map.of(
                "articleId", article.getId(),
                "title", article.getTitle(),
                "companyId", article.getCompanyId(),
                "createdAt", article.getCreatedAt()
            ));
            
        } catch (Exception e) {
            System.out.println("❌ 記事投稿エラー: " + e.getMessage());
            e.printStackTrace();
            
            // company_id がない場合のエラー
            if (e.getMessage().contains("正しく登録されていません")) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "企業ユーザーとして登録されていません"));
            }
            
            // その他のエラー
            return ResponseEntity.status(500)
                .body(Map.of("error", "記事投稿に失敗しました", "detail", e.getMessage()));
        }
    }
}
