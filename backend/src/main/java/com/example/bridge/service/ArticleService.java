package com.example.bridge.service;

import com.example.bridge.entity.Article;
import com.example.bridge.entity.User;
import com.example.bridge.repository.ArticleRepository;
import com.example.bridge.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 記事サービス
 */
@Service
public class ArticleService {
    
    @Autowired
    private ArticleRepository articleRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    /**
     * 企業記事を投稿
     * 
     * @param userId ユーザーID
     * @param title 記事タイトル
     * @param content 記事内容
     * @return 作成された記事
     * @throws Exception バリデーションエラー時
     */
    @Transactional
    public Article postCompanyArticle(Integer userId, String title, String content) throws Exception {
        // Step 1: ユーザー検証
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) {
            throw new Exception("ユーザーが見つかりません");
        }
        
        // Step 2: 企業ユーザーの確認 (type == 3)
        if (user.getType() != 3) {
            throw new Exception("企業ユーザーのみ記事投稿が可能です");
        }
        
        // ★重要★ Step 3: company_id が NULL でないことを確認
        if (user.getCompanyId() == null) {
            System.out.println("❌ 企業ユーザー投稿エラー: userId=" + userId + " に company_id がセットされていません");
            throw new Exception("企業ユーザーとして正しく登録されていません。企業IDが設定されていません。");
        }
        
        System.out.println("✅ 企業記事投稿: userId=" + userId + ", companyId=" + user.getCompanyId());
        
        // Step 4: 記事を作成
        Article article = new Article();
        article.setTitle(title);
        article.setContent(content);
        article.setUserId(userId);
        article.setCompanyId(user.getCompanyId());  // 企業IDをセット
        
        return articleRepository.save(article);
    }
}
