package com.bridge.backend.controller;

import com.bridge.backend.dto.ArticleDTO;
import com.bridge.backend.dto.LikeRequestDTO;
import com.bridge.backend.service.ArticleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * ArticleController
 * 記事に関するRESTful APIエンドポイントを提供するコントローラーです。
 */
@RestController
@RequestMapping("/api/articles")
@CrossOrigin(origins = "*")
public class ArticleController {

    @Autowired
    private ArticleService articleService;

    /**
     * 全記事を取得
     * GET /api/articles
     * 
     * @return 記事一覧
     */
    @GetMapping
    public ResponseEntity<List<ArticleDTO>> getAllArticles() {
        try {
            List<ArticleDTO> articles = articleService.getAllArticles();
            return ResponseEntity.ok(articles);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * 記事を検索
     * GET /api/articles/search?keyword=キーワード&industryId=業界ID
     * 
     * @param keyword 検索キーワード
     * @param industryId 業界ID（オプション）
     * @return 検索結果の記事一覧
     */
    @GetMapping("/search")
    public ResponseEntity<List<ArticleDTO>> searchArticles(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer industryId) {
        try {
            List<ArticleDTO> articles = articleService.searchArticles(keyword, industryId);
            return ResponseEntity.ok(articles);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * IDで記事を取得
     * GET /api/articles/{id}
     * 
     * @param id 記事ID
     * @param userId ユーザーID（オプション、いいね状態確認用）
     * @return 記事データ
     */
    @GetMapping("/{id}")
    public ResponseEntity<ArticleDTO> getArticleById(@PathVariable Integer id, @RequestParam(required = false) Integer userId) {
        try {
            ArticleDTO article = articleService.getArticleById(id, userId);
            if (article != null) {
                return ResponseEntity.ok(article);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * 企業IDで記事を取得
     * GET /api/articles/company/{companyId}
     * 
     * @param companyId 企業ID
     * @return 企業の記事一覧
     */
    @GetMapping("/company/{companyId}")
    public ResponseEntity<List<ArticleDTO>> getArticlesByCompanyId(@PathVariable Integer companyId) {
        try {
            List<ArticleDTO> articles = articleService.getArticlesByCompanyId(companyId);
            return ResponseEntity.ok(articles);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * 記事を作成
     * POST /api/articles
     * 
     * @param articleDTO 作成する記事データ
     * @return 作成された記事データ
     */
    @PostMapping
    public ResponseEntity<ArticleDTO> createArticle(@RequestBody ArticleDTO articleDTO) {
        try {
            System.out.println("Debug: ArticleController.createArticle received title=" + articleDTO.getTitle());
            System.out.println("Debug: ArticleController.createArticle received tags=" + articleDTO.getTags());
            ArticleDTO createdArticle = articleService.createArticle(articleDTO);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdArticle);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * 記事を更新
     * PUT /api/articles/{id}
     * 
     * @param id 更新する記事のID
     * @param articleDTO 更新内容
     * @return 更新された記事データ
     */
    @PutMapping("/{id}")
    public ResponseEntity<ArticleDTO> updateArticle(@PathVariable Integer id, @RequestBody ArticleDTO articleDTO) {
        try {
            System.out.println("Debug: ArticleController.updateArticle received id=" + id + ", tags=" + articleDTO.getTags());
            ArticleDTO updatedArticle = articleService.updateArticle(id, articleDTO);
            if (updatedArticle != null) {
                return ResponseEntity.ok(updatedArticle);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * 記事を削除
     * DELETE /api/articles/{id}
     * 
     * @param id 削除する記事のID
     * @return 削除結果
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteArticle(@PathVariable Integer id) {
        try {
            boolean deleted = articleService.deleteArticle(id);
            if (deleted) {
                return ResponseEntity.noContent().build();
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * 記事にいいねをトグル（追加/削除）
     * POST /api/articles/{id}/like
     * 
     * @param id 記事ID
     * @param likeRequest いいね操作の詳細
     * @return いいね操作の結果
     */
    @PostMapping("/{id}/like")
    public ResponseEntity<ArticleDTO> toggleLike(@PathVariable Integer id, @RequestBody LikeRequestDTO likeRequest) {
        try {
            System.out.println("Debug: toggleLike called with articleId=" + id + ", userId=" + likeRequest.getUserId() + ", isLiking=" + likeRequest.isLiking());
            
            // リクエストからユーザーIDを取得
            Integer userId = likeRequest.getUserId();
            if (userId == null) {
                return ResponseEntity.badRequest().build();
            }
            ArticleDTO article = articleService.toggleLike(id, userId, likeRequest.isLiking());
            
            System.out.println("Debug: Updated article total_likes=" + (article != null ? article.getTotalLikes() : "null"));
            
            if (article != null) {
                return ResponseEntity.ok(article);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}