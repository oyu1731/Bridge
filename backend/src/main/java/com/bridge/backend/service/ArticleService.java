package com.bridge.backend.service;

import com.bridge.backend.dto.ArticleDTO;
import com.bridge.backend.entity.Article;
import com.bridge.backend.entity.ArticleTag;
import com.bridge.backend.entity.Company;
import com.bridge.backend.entity.Tag;
import com.bridge.backend.repository.ArticleRepository;
import com.bridge.backend.repository.ArticleTagRepository;
import com.bridge.backend.repository.CompanyRepository;
import com.bridge.backend.repository.TagRepository;
import com.bridge.backend.service.CompanyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Articleサービス
 * 記事のビジネスロジックを担当するサービスです。
 */
@Service
public class ArticleService {

    @Autowired
    private ArticleRepository articleRepository;

    @Autowired
    private CompanyRepository companyRepository;

    @Autowired
    private CompanyService companyService;

    @Autowired
    private TagRepository tagRepository;

    @Autowired
    private ArticleTagRepository articleTagRepository;

    @PersistenceContext
    private EntityManager entityManager;

    /**
     * 全ての記事を取得（削除されていないもの）
     * 
     * @return ArticleDTOのリスト
     */
    public List<ArticleDTO> getAllArticles() {
        System.out.println("Debug: Calling findAllWithTags()");
        List<Article> articles = articleRepository.findAllWithTags();
        System.out.println("Debug: Found " + articles.size() + " articles");
        return articles.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * キーワードや業界IDで記事を検索
     * 
     * @param keyword 検索キーワード
     * @param industryId 業界ID
     * @return ArticleDTOのリスト
     */
    public List<ArticleDTO> searchArticles(String keyword, Integer industryId) {
        if (keyword == null && industryId == null) {
            return getAllArticles();
        }
        
        List<ArticleDTO> allArticles = getAllArticles();
        return allArticles.stream()
                .filter(article -> {
                    boolean matchesKeyword = true;
                    boolean matchesIndustry = true;
                    
                    // キーワードフィルタ
                    if (keyword != null && !keyword.trim().isEmpty()) {
                        String searchText = keyword.trim().toLowerCase();
                        matchesKeyword = article.getTitle().toLowerCase().contains(searchText) ||
                                (article.getCompanyName() != null && article.getCompanyName().toLowerCase().contains(searchText)) ||
                                article.getDescription().toLowerCase().contains(searchText);
                    }
                    
                    // 業界フィルタ（業界IDを業界名に変換してマッチング）
                    if (industryId != null) {
                        // TODO: ここでindustryIdを業界名に変換する処理が必要
                        // 今は簡易実装として、ID=1は"IT"、ID=2は"製造業"、ID=3は"サービス業"とする
                        String targetIndustry = null;
                        switch (industryId) {
                            case 1: targetIndustry = "IT"; break;
                            case 2: targetIndustry = "製造業"; break;
                            case 3: targetIndustry = "サービス業"; break;
                        }
                        if (targetIndustry != null) {
                            matchesIndustry = targetIndustry.equals(article.getIndustry());
                        }
                    }
                    
                    return matchesKeyword && matchesIndustry;
                })
                .collect(Collectors.toList());
    }

    /**
     * IDで記事を取得
     * 
     * @param id 記事ID
     * @return ArticleDTO（存在しない場合はnull）
     */
    public ArticleDTO getArticleById(Integer id) {
        Article article = articleRepository.findByIdAndIsDeletedFalseWithTags(id);
        return article != null ? convertToDTO(article) : null;
    }

    /**
     * 企業IDで記事を取得
     * 
     * @param companyId 企業ID
     * @return ArticleDTOのリスト
     */
    public List<ArticleDTO> getArticlesByCompanyId(Integer companyId) {
        List<Article> articles = articleRepository.findByCompanyIdAndIsDeletedFalseOrderByCreatedAtDesc(companyId);
        return articles.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 記事を作成
     * 
     * @param articleDTO 作成する記事のDTO
     * @return 作成された記事のDTO
     */
    @Transactional
    public ArticleDTO createArticle(ArticleDTO articleDTO) {
        // 記事を保存
        Article article = new Article();
        article.setTitle(articleDTO.getTitle());
        article.setDescription(articleDTO.getDescription());
        article.setCompanyId(articleDTO.getCompanyId());
        article.setIsDeleted(false);
        article.setTotalLikes(0);
        article.setCreatedAt(LocalDateTime.now());
        article.setPhoto1Id(articleDTO.getPhoto1Id());
        article.setPhoto2Id(articleDTO.getPhoto2Id());
        article.setPhoto3Id(articleDTO.getPhoto3Id());

        Article savedArticle = articleRepository.save(article);

        // タグを中間テーブルに保存（名称/ID両対応・trim対応）
        if (articleDTO.getTags() != null && !articleDTO.getTags().isEmpty()) {
            System.out.println("Debug: createArticle received tags=" + articleDTO.getTags());
            for (String raw : articleDTO.getTags()) {
                if (raw == null) continue;
                String tagInput = raw.trim();
                if (tagInput.isEmpty()) continue;

                Tag tag = null;
                // 1) 名称で検索
                try {
                    tag = tagRepository.findByTag(tagInput);
                } catch (Exception ignored) {}

                // 2) 名称で見つからず、数値ならID解釈も試す
                if (tag == null) {
                    try {
                        Integer maybeId = Integer.valueOf(tagInput);
                        tag = tagRepository.findById(maybeId).orElse(null);
                    } catch (NumberFormatException ignored) {}
                }

                if (tag != null) {
                    ArticleTag articleTag = new ArticleTag();
                    articleTag.setArticleId(savedArticle.getId());
                    articleTag.setTagId(tag.getId());
                    articleTag.setCreationDate(LocalDateTime.now());
                    articleTagRepository.save(articleTag);
                    System.out.println("Debug: linked tag id=" + tag.getId() + " to article id=" + savedArticle.getId());
                } else {
                    System.out.println("Warn: tag not found for input='" + tagInput + "'");
                }
            }
            // DBへ反映を強制
            try { articleTagRepository.flush(); } catch (Exception ignored) {}
        } else {
            System.out.println("Debug: createArticle received no tags");
        }

        // 保存直後にタグ付きで再読込して返す
        // 同一永続化コンテキストのキャッシュをクリアして関連を新鮮に読み込む
        try { entityManager.flush(); entityManager.clear(); } catch (Exception ignored) {}
        Article reloaded = articleRepository.findByIdAndIsDeletedFalseWithTags(savedArticle.getId());
        return convertToDTO(reloaded != null ? reloaded : savedArticle);
    }

    /**
     * 記事を更新
     * 
     * @param id 更新する記事のID
     * @param articleDTO 更新内容
     * @return 更新された記事のDTO（存在しない場合はnull）
     */
    @Transactional
    public ArticleDTO updateArticle(Integer id, ArticleDTO articleDTO) {
        Article existingArticle = articleRepository.findByIdAndIsDeletedFalse(id);
        if (existingArticle == null) {
            return null;
        }

        existingArticle.setTitle(articleDTO.getTitle());
        existingArticle.setDescription(articleDTO.getDescription());
        existingArticle.setPhoto1Id(articleDTO.getPhoto1Id());
        existingArticle.setPhoto2Id(articleDTO.getPhoto2Id());
        existingArticle.setPhoto3Id(articleDTO.getPhoto3Id());

        Article updatedArticle = articleRepository.save(existingArticle);

        // 既存のタグ関連付けを削除
        articleTagRepository.deleteByArticleId(id);

        // 新しいタグを中間テーブルに保存（名称/ID両対応・trim対応）
        if (articleDTO.getTags() != null && !articleDTO.getTags().isEmpty()) {
            System.out.println("Debug: updateArticle received tags=" + articleDTO.getTags());
            for (String raw : articleDTO.getTags()) {
                if (raw == null) continue;
                String tagInput = raw.trim();
                if (tagInput.isEmpty()) continue;

                Tag tag = null;
                try {
                    tag = tagRepository.findByTag(tagInput);
                } catch (Exception ignored) {}
                if (tag == null) {
                    try {
                        Integer maybeId = Integer.valueOf(tagInput);
                        tag = tagRepository.findById(maybeId).orElse(null);
                    } catch (NumberFormatException ignored) {}
                }

                if (tag != null) {
                    ArticleTag articleTag = new ArticleTag();
                    articleTag.setArticleId(id);
                    articleTag.setTagId(tag.getId());
                    articleTag.setCreationDate(LocalDateTime.now());
                    articleTagRepository.save(articleTag);
                    System.out.println("Debug: linked tag id=" + tag.getId() + " to article id=" + id);
                } else {
                    System.out.println("Warn: tag not found for input='" + tagInput + "'");
                }
            }
            // DBへ反映を強制
            try { articleTagRepository.flush(); } catch (Exception ignored) {}
        } else {
            System.out.println("Debug: updateArticle received no tags");
        }

        // 更新後にタグ付きで再読込して返す
        try { entityManager.flush(); entityManager.clear(); } catch (Exception ignored) {}
        Article reloaded = articleRepository.findByIdAndIsDeletedFalseWithTags(updatedArticle.getId());
        return convertToDTO(reloaded != null ? reloaded : updatedArticle);
    }

    /**
     * 記事を削除（論理削除）
     * 
     * @param id 削除する記事のID
     * @return 削除成功の場合true
     */
    public boolean deleteArticle(Integer id) {
        Article article = articleRepository.findByIdAndIsDeletedFalse(id);
        if (article == null) {
            return false;
        }

        article.setIsDeleted(true);
        articleRepository.save(article);
        return true;
    }

    /**
     * ArticleエンティティをArticleDTOに変換
     * 
     * @param article Articleエンティティ
     * @return ArticleDTO
     */
    private ArticleDTO convertToDTO(Article article) {
        // 企業名を取得
        String companyName = null;
        if (article.getCompanyId() != null) {
            Company company = companyRepository.findById(article.getCompanyId()).orElse(null);
            if (company != null) {
                companyName = company.getName();
            }
        }

        // タグ情報を取得
        List<String> tagNames = null;
        System.out.println("Debug: Article tags: " + article.getTags());
        if (article.getTags() != null) {
            tagNames = article.getTags().stream()
                    .map(Tag::getTag)
                    .collect(Collectors.toList());
            System.out.println("Debug: Tag names: " + tagNames);
        } else {
            System.out.println("Debug: No tags found for article " + article.getId());
        }

        String industryName = null;
        if (article.getCompanyId() != null) {
            try {
                industryName = companyService.getCompanyById(article.getCompanyId())
                        .map(dto -> dto.getIndustry())
                        .orElse(null);
            } catch (Exception e) {
                // Ignore and leave industryName as null
            }
        }

        return new ArticleDTO(
                article.getId(),
                article.getCompanyId(),
                companyName,
                article.getTitle(),
                article.getDescription(),
                article.getTotalLikes(),
                article.getIsDeleted(),
                article.getCreatedAt() != null ? article.getCreatedAt().toString() : null,
                article.getPhoto1Id(),
                article.getPhoto2Id(),
                article.getPhoto3Id(),
                tagNames,
                industryName
        );
    }

    /**
     * 記事のいいねをトグル
     * フロントエンドから送られるisLikingに基づいてtotal_likesを調整
     * 
     * @param articleId 記事ID
     * @param userId ユーザーID
     * @param isLiking いいねするかどうか
     * @return 更新された記事
     */
    public ArticleDTO toggleLike(Integer articleId, Integer userId, boolean isLiking) {
        System.out.println("Debug: ArticleService.toggleLike called with articleId=" + articleId + ", userId=" + userId + ", isLiking=" + isLiking);
        
        Article article = articleRepository.findById(articleId).orElse(null);
        if (article == null) {
            System.out.println("Debug: Article not found with id=" + articleId);
            return null;
        }

        Integer currentLikes = article.getTotalLikes();
        System.out.println("Debug: Current total_likes=" + currentLikes);
        
        if (isLiking) {
            // いいねを追加：total_likesを+1
            article.setTotalLikes(currentLikes + 1);
            System.out.println("Debug: Adding like, new total_likes=" + (currentLikes + 1));
        } else {
            // いいねを削除：total_likesを-1（0より下にならないように）
            article.setTotalLikes(Math.max(0, currentLikes - 1));
            System.out.println("Debug: Removing like, new total_likes=" + Math.max(0, currentLikes - 1));
        }
        
        articleRepository.save(article);
        
        return convertToDTO(article);
    }
}