package com.bridge.backend.controller;

import com.bridge.backend.dto.ArticleDTO;
import com.bridge.backend.dto.LikeRequestDTO;
import com.bridge.backend.service.ArticleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

/**
 * ArticleController
 * 記事に関するRESTful APIエンドポイントを提供するコントローラーです。
 */
@RestController
@RequestMapping("/api/articles")
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
     * GET /api/articles/search?keyword=キーワード&industryIds=1,2,3
     * 
     * @param keyword 検索キーワード
     * @param industryIds 業界IDリスト（カンマ区切り）
     * @return 検索結果の記事一覧
     */
    @GetMapping("/search")
    public ResponseEntity<List<ArticleDTO>> searchArticles(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String industryIds,
            @RequestParam(required = false) String search_words,
            @RequestParam(required = false) String industry,
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) String article_id) {
        try {
            if (article_id != null) {
                Integer aid = null;
                try {
                    aid = Integer.valueOf(article_id);
                } catch (NumberFormatException e) {
                    ArticleDTO dto = new ArticleDTO();
                    dto.setId(null); // setIdはInteger型なのでnullをセット
                    dto.setDescription("不正な入力値です");
                    return ResponseEntity.ok(java.util.Arrays.asList(dto));
                }
                // DBから記事取得し、該当記事のtag_idでタグテーブルを絞り込み
                ArticleDTO article = articleService.getArticleById(aid, null);
                if (article == null) {
                    ArticleDTO dto = new ArticleDTO();
                    dto.setId(aid);
                    dto.setDescription("不正な入力値です");
                    return ResponseEntity.ok(java.util.Arrays.asList(dto));
                }
                // タグ配列を返却
                ArticleDTO dto = new ArticleDTO();
                dto.setId(aid);
                dto.setTags(article.getTags());
                return ResponseEntity.ok(java.util.Arrays.asList(dto));
            }

            // フロント互換: keyword優先、未指定なら従来search_wordsを使用
            String effectiveKeyword = (keyword != null && !keyword.trim().isEmpty())
                    ? keyword
                    : search_words;

            // フロント互換: industryIds=1,2,3 をパース
            List<Integer> parsedIndustryIds = null;
            if (industryIds != null && !industryIds.trim().isEmpty()) {
                parsedIndustryIds = new ArrayList<>();
                for (String raw : industryIds.split(",")) {
                    String value = raw.trim();
                    if (value.isEmpty()) {
                        continue;
                    }
                    try {
                        parsedIndustryIds.add(Integer.valueOf(value));
                    } catch (NumberFormatException ignored) {
                        // 不正値は無視して続行
                    }
                }
                if (parsedIndustryIds.isEmpty()) {
                    parsedIndustryIds = null;
                }
            }

            List<ArticleDTO> articles = articleService.searchArticles(effectiveKeyword, parsedIndustryIds);
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
    public ResponseEntity<ArticleDTO> getArticleById(@PathVariable String id, @RequestParam(required = false) Integer userId) {
        try {
            Integer articleId = null;
            try {
                articleId = Integer.valueOf(id);
            } catch (NumberFormatException e) {
                ArticleDTO dto = new ArticleDTO();
                dto.setId(null);
                dto.setDescription("不正な入力値です");
                return ResponseEntity.ok(dto);
            }
            ArticleDTO article = articleService.getArticleById(articleId, userId);
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
    public ResponseEntity<ArticleDTO> createArticle(@RequestBody ArticleDTO articleDTO, @RequestParam(required = false) List<String> tag_ids) {
        try {
            // article_idバリデーション（リクエストボディにidが含まれる場合）
            if (articleDTO.getId() != null) {
                try {
                    Integer.valueOf(articleDTO.getId().toString());
                } catch (NumberFormatException e) {
                    ArticleDTO dto = new ArticleDTO();
                    dto.setId(articleDTO.getId());
                    dto.setDescription("不正な入力値です");
                    return ResponseEntity.ok(dto);
                }
                // 存在チェック（serviceでnull返却時）
                if (articleService.getArticleById(articleDTO.getId(), null) == null) {
                    ArticleDTO dto = new ArticleDTO();
                    dto.setId(articleDTO.getId());
                    dto.setDescription("不正な入力値です");
                    return ResponseEntity.ok(dto);
                }
            }
            // tag_idsバリデーション
            if (tag_ids != null) {
                try {
                    List<Integer> tagIdList = new java.util.ArrayList<>();
                    for (String tagIdStr : tag_ids) {
                        tagIdList.add(Integer.valueOf(tagIdStr));
                    }
                } catch (NumberFormatException e) {
                    ArticleDTO dto = new ArticleDTO();
                    dto.setDescription("不正な入力値です");
                    dto.setTags(tag_ids);
                    return ResponseEntity.ok(dto);
                }
            }
            // titleバリデーション
            if (articleDTO.getTitle() == null || articleDTO.getTitle().trim().isEmpty()) {
                ArticleDTO dto = new ArticleDTO();
                dto.setTitle(articleDTO.getTitle());
                dto.setDescription("不正な入力値です");
                return ResponseEntity.ok(dto);
            }
            if (articleDTO.getTitle().length() > 40) {
                ArticleDTO dto = new ArticleDTO();
                dto.setTitle(articleDTO.getTitle());
                dto.setDescription("タイトルが長すぎます");
                return ResponseEntity.ok(dto);
            }
            // descriptionバリデーション
            if (articleDTO.getDescription() == null || articleDTO.getDescription().trim().isEmpty()) {
                ArticleDTO dto = new ArticleDTO();
                dto.setDescription(articleDTO.getDescription());
                dto.setTitle(articleDTO.getTitle());
                dto.setDescription("不正な入力値です");
                return ResponseEntity.ok(dto);
            }
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
            System.out.println("Debug: ArticleController.updateArticle received industries=" + articleDTO.getIndustries());
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