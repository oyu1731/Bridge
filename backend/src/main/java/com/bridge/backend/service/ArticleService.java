package com.bridge.backend.service;

import com.bridge.backend.dto.ArticleDTO;
import com.bridge.backend.entity.Article;
import com.bridge.backend.entity.ArticleTag;
import com.bridge.backend.entity.ArticleLike;
import com.bridge.backend.entity.Company;
import com.bridge.backend.entity.Tag;
import com.bridge.backend.repository.ArticleRepository;
import com.bridge.backend.repository.ArticleTagRepository;
import com.bridge.backend.repository.ArticleLikeRepository;
import com.bridge.backend.repository.CompanyRepository;
import com.bridge.backend.repository.TagRepository;
import com.bridge.backend.service.CompanyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import com.bridge.backend.entity.User;
import com.bridge.backend.entity.IndustryRelation;
import com.bridge.backend.entity.Industry;
import com.bridge.backend.repository.UserRepository;
import com.bridge.backend.repository.IndustryRelationRepository;
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

    @Autowired
    private ArticleLikeRepository articleLikeRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private IndustryRelationRepository industryRelationRepository;

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
    /**
     * @param keyword 検索キーワード
     * @param industryIds 業界IDリスト（複数対応）
     * @return ArticleDTOのリスト
     */
    public List<ArticleDTO> searchArticles(String keyword, List<Integer> industryIds) {
        if ((keyword == null || keyword.trim().isEmpty()) && (industryIds == null || industryIds.isEmpty())) {
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

                    // 業界フィルタ（複数業界ID対応）
                    if (industryIds != null && !industryIds.isEmpty()) {
                        // ID→業界名変換
                        List<String> targetIndustries = industryIds.stream().map(id -> {
                            switch (id) {
                                case 1: return "IT";
                                case 2: return "製造業";
                                case 3: return "サービス業";
                                default: return null;
                            }
                        }).filter(s -> s != null).collect(Collectors.toList());

                        // ArticleDTOのindustriesリストに含まれるか判定
                        if (article.getIndustries() != null && !article.getIndustries().isEmpty()) {
                            matchesIndustry = article.getIndustries().stream().anyMatch(targetIndustries::contains);
                        } else if (article.getIndustry() != null) {
                            matchesIndustry = targetIndustries.contains(article.getIndustry());
                        } else {
                            matchesIndustry = false;
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
        return getArticleById(id, null);
    }

    /**
     * IDで記事を取得（ユーザーのいいね状態も含む）
     * 
     * @param id 記事ID
     * @param userId ユーザーID（オプション）
     * @return ArticleDTO（存在しない場合はnull）
     */
    public ArticleDTO getArticleById(Integer id, Integer userId) {
        Article article = articleRepository.findByIdAndIsDeletedFalseWithTags(id);
        if (article == null) {
            return null;
        }
        
        ArticleDTO dto = convertToDTO(article);
        
        // ユーザーIDが指定されている場合、いいね状態を設定
        if (userId != null) {
            boolean isLiked = articleLikeRepository.existsByArticleIdAndUserId(id, userId);
            dto.setIsLikedByUser(isLiked);
        }
        
        return dto;
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
     * ユーザーがいいねした未削除記事一覧を取得
     *
     * @param userId ユーザーID
     * @return いいね済み記事のDTO一覧
     */
    public List<ArticleDTO> getLikedArticlesByUserId(Integer userId) {
        List<Integer> likedArticleIds = articleLikeRepository.findArticleIdsByUserIdOrderByCreatedAtDesc(userId);
        if (likedArticleIds == null || likedArticleIds.isEmpty()) {
            return List.of();
        }

        List<Article> articles = articleRepository.findByIdInAndIsDeletedFalseWithTags(likedArticleIds);

        Map<Integer, Integer> orderMap = new HashMap<>();
        for (int index = 0; index < likedArticleIds.size(); index++) {
            orderMap.put(likedArticleIds.get(index), index);
        }

        articles.sort((left, right) -> {
            Integer leftOrder = orderMap.getOrDefault(left.getId(), Integer.MAX_VALUE);
            Integer rightOrder = orderMap.getOrDefault(right.getId(), Integer.MAX_VALUE);
            return leftOrder.compareTo(rightOrder);
        });

        return articles.stream()
                .map(article -> {
                    ArticleDTO dto = convertToDTO(article);
                    dto.setIsLikedByUser(true);
                    return dto;
                })
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

        // 業界リストを保存
        if (articleDTO.getIndustries() != null) {
            article.setIndustries(articleDTO.getIndustries());
        }
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

        // 業界リストを更新
        if (articleDTO.getIndustries() != null) {
            existingArticle.setIndustries(articleDTO.getIndustries());
        }
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
        List<String> industriesList = null;
        if (article.getCompanyId() != null) {
            Company company = companyRepository.findById(article.getCompanyId()).orElse(null);
            if (company != null) {
                companyName = company.getName();
                // company関連APIと同じ業界リスト取得ロジック
                Optional<User> companyUser = userRepository.findByCompanyId(company.getId());
                if (companyUser.isPresent()) {
                    User user = companyUser.get();
                    java.util.List<String> industries = new java.util.ArrayList<>();
                    for (int type = 1; type <= 3; type++) {
                        List<IndustryRelation> relations = industryRelationRepository.findAllByUserIdAndType(user.getId(), type);
                        for (IndustryRelation rel : relations) {
                            Industry industry = rel.getIndustry();
                            if (industry != null && industry.getIndustry() != null && !industries.contains(industry.getIndustry())) {
                                industries.add(industry.getIndustry());
                            }
                        }
                    }
                    industriesList = industries;
                    // 代表業界名（最初の1件）
                    if (!industries.isEmpty()) {
                        industryName = industries.get(0);
                    }
                }
            }
        }
        // 記事自身のindustriesがあれば優先
        if (article.getIndustries() != null && !article.getIndustries().isEmpty()) {
            industriesList = article.getIndustries();
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
            industryName,
            industriesList
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

        if (isLiking) {
            // いいねを追加
            // 既にいいね済みかチェック
            if (!articleLikeRepository.existsByArticleIdAndUserId(articleId, userId)) {
                ArticleLike like = new ArticleLike(articleId, userId);
                articleLikeRepository.save(like);
                
                // total_likesを更新
                long totalLikes = articleLikeRepository.countByArticleId(articleId);
                article.setTotalLikes((int) totalLikes);
                articleRepository.save(article);
                
                System.out.println("Debug: Like added, new total_likes=" + totalLikes);
            }
        } else {
            // いいねを削除
            articleLikeRepository.findByArticleIdAndUserId(articleId, userId)
                .ifPresent(like -> {
                    articleLikeRepository.delete(like);
                    
                    // total_likesを更新
                    long totalLikes = articleLikeRepository.countByArticleId(articleId);
                    article.setTotalLikes((int) totalLikes);
                    articleRepository.save(article);
                    
                    System.out.println("Debug: Like removed, new total_likes=" + totalLikes);
                });
        }
        
        ArticleDTO dto = convertToDTO(article);
        // データベースから実際のいいね状態を確認して設定
        boolean actuallyLiked = articleLikeRepository.existsByArticleIdAndUserId(articleId, userId);
        dto.setIsLikedByUser(actuallyLiked);
        System.out.println("Debug: Final isLikedByUser=" + actuallyLiked);
        return dto;
    }
}