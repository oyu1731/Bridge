package com.bridge.backend.service;

import com.bridge.backend.dto.EmailCorrectionRequestDTO;
import com.bridge.backend.dto.EmailCorrectionResponseDTO;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class EmailCorrectionService {

    private static final Logger logger = LoggerFactory.getLogger(EmailCorrectionService.class);
    private final ObjectMapper objectMapper = new ObjectMapper();

    // Grok API設定
    private final String grokApiUrl = "https://api.groq.com/openai/v1/chat/completions";
    private final String apiKey = "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";

    public EmailCorrectionResponseDTO correctEmail(EmailCorrectionRequestDTO requestDTO) {
        logger.info("=== EmailCorrectionService.correctEmail ===");
        logger.info("受信メール: {}", requestDTO.getOriginalEmail());
        logger.info("===========================================");

        if (requestDTO.getOriginalEmail() == null || requestDTO.getOriginalEmail().trim().isEmpty()) {
            logger.warn("元のメールが空です");
            return createErrorResponse("メール本文が空です");
        }

        try {
            // システムプロンプトの構築
            String systemPrompt = buildSystemPrompt();
            
            // ユーザープロンプトの構築
            String userPrompt = buildUserPrompt(requestDTO.getOriginalEmail());

            // APIペイロードの構築
            Map<String, Object> apiPayload = buildApiPayload(systemPrompt, userPrompt);

            // HTTPヘッダーの設定
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(apiPayload, headers);

            // RestTemplateの設定
            SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
            requestFactory.setConnectTimeout(10000);
            requestFactory.setReadTimeout(30000);
            RestTemplate restTemplate = new RestTemplate(requestFactory);

            logger.info("Grok APIを呼び出します: {}", grokApiUrl);
            ResponseEntity<String> response = restTemplate.postForEntity(grokApiUrl, request, String.class);

            if (!response.getStatusCode().is2xxSuccessful()) {
                logger.error("Grok API呼び出し失敗: {} - {}", response.getStatusCode(), response.getBody());
                return createErrorResponse("Grok API呼び出しに失敗しました: " + response.getStatusCode());
            }

            String responseBody = response.getBody();
            logger.info("Grok API応答: {}", responseBody);

            // 応答の処理
            return processGrokResponse(responseBody);

        } catch (Exception e) {
            logger.error("Grok API呼び出し中にエラーが発生しました", e);
            return createErrorResponse("API呼び出し中にエラーが発生しました: " + e.getMessage());
        }
    }

    private String buildSystemPrompt() {
        return """
            あなたは、日本のビジネス慣習に精通したプロフェッショナルなメール添削コンサルタントです。
            提供されたメールの下書きを、相手に好印象を与え、かつ目的が確実に伝わる「完璧なビジネスメール」にリライトしてください。

            【添削の最重要方針】
            - **受信者が一読で内容を完全に理解し、返信や次の行動に移しやすい**ように構成してください。
            - 曖昧さや誤解の余地を徹底的に排除し、簡潔かつ明確な表現を追求してください。

            【重要な処理ルール】
            1. **文脈推測と最適化**: メール本文中のキーワード、宛名、挨拶文から「相手との関係性（社内・社外・目上・同僚）」と「メールの目的（謝罪・依頼・営業・報告・連絡・相談など）」を**正確に推測**し、それに完全に合致する最も丁寧で効果的なトーン＆マナーを適用してください。推測結果は添削詳細に簡潔に記載してください。
            2. **件名の最適化**: メール本文だけでなく、一目で内容が分かるよう、**【緊急】**や**【要返信】**などの適切なプレフィックスを含めつつ、開封率を高める具体的で分かりやすい「件名」を提案に含めてください。
            3. **クッション言葉の活用**: 依頼、質問、断り、要望などの場面では、「恐れ入りますが」「お忙しいところ恐縮ですが」などのクッション言葉を**自然かつ適切に**補い、丁寧さを際立たせてください。
            4. **冗長表現の徹底排除**: 「～させていただく」の過度な使用、無意味な前置き、重複表現を全て削除し、より洗練されたプロフェッショナルな文章に磨き上げてください。
            5. **ポジティブな代替案提示**: ネガティブな印象を与える表現（例：「できません」「分かりません」）は、**必ず**肯定的な代替案や解決策を示す表現（例：「誠に恐縮ではございますが、現状では〇〇しかいたしかねますが、△△であれば可能です」）に変換してください。

            【添削の5つの基準】
            1. **正しい敬語**: 尊敬語・謙譲語・丁寧語の誤用を正し、相手への敬意が適切に伝わる、慇懃無礼にならない自然な表現にする。
            2. **明快な論理構成**: 結論（最も伝えたい用件）を**最優先で**冒頭に述べ、読み手がスクロールせずに用件の全体像を把握できるようにする。その後に詳細を続く構成とする。
            3. **簡潔性と効率性**: 一文が長すぎないか、必要な情報が過不足なく含まれているかを確認し、無駄を徹底的に省く。
            4. **形式美と可読性**: 適切な改行、箇条書き、段落分けを巧みに利用し、PC・スマートフォンいずれでも視覚的に非常に読みやすいレイアウトにする。
            5. **状況に応じた配慮**: 緊急度、重要度、相手の状況（忙しさなど）を考慮した言葉選びと表現を用いる。

            【出力フォーマット（厳守）】
            回答は**以下のJSON形式のみ**を出力してください。
            **いかなる場合も、```json や、挨拶文、説明文、謝罪文など、JSON以外の余計なテキストは一切含めないでください。**
            JSON内の改行コードは \\n にエスケープしてください。

            {
              "correctedEmail": "件名：[提案した件名]\\n\\n[添削後の本文]",
              "correctionDetails": "【添削の方向性】\\n・推測された関係性：[例：社外の顧客・目上]\\n・推測された目的：[例：新商品導入の依頼]\\n\\n【主要な修正点】\\n1. [元の表現] → [修正後の表現]：[理由]\\n2. [元の表現] → [修正後の表現]：[理由]\\n3. 論理構成を改善：[具体的な変更点と効果]\\n\\n【プロからのアドバイス】\\n・[実践的なアドバイス1 (なぜその表現を使うのか、どうすればさらに良くなるか)]\\n・[実践的なアドバイス2]\\n・[よくある間違いと改善策]"
            }
            """;
    }

    private String buildUserPrompt(String originalEmail) {
        return String.format("""
            以下のメール下書きを、プロフェッショナルなビジネスメールに添削してください。
            
            【元のメール】
            %s
            """, originalEmail);
    }

    private Map<String, Object> buildApiPayload(String systemPrompt, String userPrompt) {
        Map<String, Object> apiPayload = new HashMap<>();
        apiPayload.put("model", "llama-3.3-70b-versatile");
        
        List<Map<String, String>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", systemPrompt));
        messages.add(Map.of("role", "user", "content", userPrompt));
        
        apiPayload.put("messages", messages);
        apiPayload.put("max_tokens", 2000);
        apiPayload.put("temperature", 0.3);
        
        return apiPayload;
    }

    private EmailCorrectionResponseDTO processGrokResponse(String responseBody) {
        try {
            JsonNode root = objectMapper.readTree(responseBody);
            
            if (!root.has("choices") || !root.get("choices").isArray() || root.get("choices").size() == 0) {
                logger.error("Grok応答にchoicesがありません");
                return createErrorResponse("Grok応答の形式が不正です");
            }
            
            JsonNode firstChoice = root.get("choices").get(0);
            if (!firstChoice.has("message") || !firstChoice.get("message").has("content")) {
                logger.error("Grok応答にcontentがありません");
                return createErrorResponse("Grok応答にコンテンツがありません");
            }
            
            String content = firstChoice.get("message").get("content").asText();
            logger.info("Grok応答コンテンツ: {}", content);
            
            // コンテンツのクリーニング
            content = cleanContent(content);
            
            // JSONのパース
            JsonNode contentNode = parseJsonRobustly(content);
            if (contentNode == null) {
                logger.error("JSONのパースに失敗しました: {}", content);
                return createFallbackResponse(content);
            }
            
            // フィールドの抽出
            String correctedEmail = extractField(contentNode, "correctedEmail");
            String correctionDetails = extractField(contentNode, "correctionDetails");
            
            if (correctedEmail == null || correctedEmail.trim().isEmpty()) {
                logger.warn("correctedEmailが空です");
                return createFallbackResponse(content);
            }
            
            EmailCorrectionResponseDTO response = new EmailCorrectionResponseDTO();
            response.setCorrectedEmail(correctedEmail.trim());
            response.setCorrectionDetails(correctionDetails != null ? correctionDetails.trim() : "修正内容の詳細はありません");
            
            logger.info("添削完了: 文字数 {}字", correctedEmail.length());
            return response;
            
        } catch (Exception e) {
            logger.error("Grok応答の処理中にエラーが発生しました", e);
            return createErrorResponse("応答の処理中にエラーが発生しました: " + e.getMessage());
        }
    }

    private String cleanContent(String content) {
        if (content == null) return "";
        
        // マークダウンのコードブロックを除去
        content = content.replaceAll("```json\\n?", "");
        content = content.replaceAll("```\\n?", "");
        
        // JSONの前後のテキストを除去
        int start = content.indexOf('{');
        int end = content.lastIndexOf('}') + 1;
        
        if (start >= 0 && end > start) {
            content = content.substring(start, end);
        }
        
        return content.trim();
    }

    private JsonNode parseJsonRobustly(String content) {
        try {
            return objectMapper.readTree(content);
        } catch (Exception e) {
            logger.debug("直接パース失敗: {}", e.getMessage());
            return null;
        }
    }

    private String extractField(JsonNode node, String fieldName) {
        if (node.has(fieldName)) {
            return node.get(fieldName).asText();
        }
        return null;
    }

    private EmailCorrectionResponseDTO createErrorResponse(String errorMessage) {
        EmailCorrectionResponseDTO response = new EmailCorrectionResponseDTO();
        response.setCorrectedEmail("エラー: " + errorMessage);
        response.setCorrectionDetails("メールの添削中にエラーが発生しました。");
        return response;
    }

    private EmailCorrectionResponseDTO createFallbackResponse(String content) {
        EmailCorrectionResponseDTO response = new EmailCorrectionResponseDTO();
        
        // コンテンツからメールらしい部分を抽出
        if (content.contains("件名") || content.contains("様") || content.contains("お世話になっております")) {
            response.setCorrectedEmail(content);
        } else {
            response.setCorrectedEmail("以下の内容でメールを作成しました:\\n\\n" + content);
        }
        
        response.setCorrectionDetails("AIからの応答をそのまま表示しています。詳細な修正内容はありません。");
        
        return response;
    }
}