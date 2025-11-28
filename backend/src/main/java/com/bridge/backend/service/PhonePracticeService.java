package com.bridge.backend.service;

import com.bridge.backend.dto.PhonePracticeContinueRequestDTO;
import com.bridge.backend.dto.PhonePracticeEvaluationDTO;
import com.bridge.backend.dto.PhonePracticeRequestDTO;
import com.bridge.backend.dto.PhonePracticeResponseDTO;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;
import java.util.*;
import java.util.regex.Pattern;

@Service
public class PhonePracticeService {

    private final Logger logger = LoggerFactory.getLogger(PhonePracticeService.class);
    private final ObjectMapper mapper = new ObjectMapper();

    // 会話の状態を保持する簡易的なキャッシュ
    private final Map<String, ConversationState> conversationCache = new HashMap<>();
    
    // 評価結果を保持するキャッシュ
    private final Map<String, PhonePracticeEvaluationDTO> evaluationCache = new HashMap<>();

    /**
     * 会話の状態を保持するクラス
     */
    static class ConversationState {
        private String memo;
        private String scenario;
        private List<ConversationTurn> conversationHistory;

        // getters and setters
        public String getMemo() { return memo; }
        public void setMemo(String memo) { this.memo = memo; }
        
        public String getScenario() { return scenario; }
        public void setScenario(String scenario) { this.scenario = scenario; }
        
        public List<ConversationTurn> getConversationHistory() { return conversationHistory; }
        public void setConversationHistory(List<ConversationTurn> conversationHistory) {
            this.conversationHistory = conversationHistory;
        }
    }

    /**
     * 会話のターンを表すクラス
     */
    static class ConversationTurn {
        private String role; // "user" or "assistant"
        private String content;
        private Instant timestamp;

        public ConversationTurn(String role, String content) {
            this.role = role;
            this.content = content;
            this.timestamp = Instant.now();
        }

        // getters and setters
        public String getRole() { return role; }
        public void setRole(String role) { this.role = role; }
        
        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
        
        public Instant getTimestamp() { return timestamp; }
        public void setTimestamp(Instant timestamp) { this.timestamp = timestamp; }
    }

    /**
     * リクエスト受信 → Grok に問い合わせ → memo/scenario/firstMessage を返す
     */
    public PhonePracticeResponseDTO startPractice(PhonePracticeRequestDTO requestDTO) {
        logger.info("=== PhonePracticeService.startPractice ===");
        logger.info("受信データ: {}", requestDTO);
        logger.info("==========================================");

        // DTOから安全に取り出す
        String userName = Optional.ofNullable(requestDTO.getUserName()).orElse("ユーザー");
        String companyName = Optional.ofNullable(requestDTO.getCompanyName()).orElse("あなたの会社");
        String genre = Optional.ofNullable(requestDTO.getGenre()).orElse("ビジネス");
        String callAtmosphere = Optional.ofNullable(requestDTO.getCallAtmosphere()).orElse("普通");
        String difficulty = Optional.ofNullable(requestDTO.getDifficulty()).orElse("普通");
        String reviewType = Optional.ofNullable(requestDTO.getReviewType()).orElse("all");

        // セッションIDを生成（既存のセッションがある場合は再利用）
        String sessionId = generateSessionId(requestDTO);
        // 評価キャッシュから古い評価を削除
        evaluationCache.remove(sessionId);

        // システムプロンプト - メモの具体性を強化
        String systemPrompt = """
            あなたは電話対応練習のシナリオ生成AIです。
            出力は必ず有効なJSON形式で、キーは "memo", "scenario", "firstMessage" の3つのみとしてください。
            
            ## 重要な前提:
            - ユーザーは電話**を受ける側**です（ユーザー名: %s、会社名: %s）
            - 電話をかけてくる相手は**ランダムに生成**してください
            - firstMessageは電話をかけてくる相手のセリフです
            
            ## 出力フォーマット:
            {
              "memo": "具体的な状況メモ",
              "scenario": "電話の状況説明",
              "firstMessage": "相手の最初の発言"
            }
            
            ### memoの作成ルール:
            - **シナリオに基づいた具体的な状況**を記載
            - 以下の情報を含める:
              【自社の状況】
              ・あなた: [会社名] [部署] [役職] [ユーザー名]
              ・関連人物: [状況に応じた社内の人物とその状況]
              
              【相手先の情報】
              ・会社: [会社名]
              ・部署: [部署名]
              ・役職: [役職名]
              ・名前: [名前]
              
              【具体的な状況と背景】
              ・現在の状況: [具体的な業務状況]
              ・これまでの経緯: [過去のやり取りや背景]
              ・必要な情報: [対応に必要な具体的なデータ]
              ・注意点: [特に気をつけるべきこと]
            
            ### scenarioの作成ルール:
            - 2-3文で簡潔に状況を説明
            - 誰から、何の目的で電話がかかってくるか明確に
            - **相手が求めている人物**を明記（ユーザー本人 or 他の担当者）
            
            ### firstMessageの作成ルール:
            - **自然な日本語の敬語**を使用
            - **電話をかけてくる相手**のセリフ
            - **基本的な流れ: 挨拶 → 自己紹介 → 担当者への接続依頼**
            - **絶対に用件の詳細を伝えないでください**
            - パターン例:
              ○ "お世話になっております。○○株式会社の△△と申します。□□様はいらっしゃいますか？"
              ○ "いつもお世話になっております。○○の△△でございます。営業部の□□様、お願いいたします。"
            - 禁止事項:
              × 用件の詳細を伝える
              × 長々と自己紹介する
              × 要件を説明する
            
            ## 具体例:
            シナリオ: "オーエッチシー株式会社の営業部部長、小林太郎が電話をし、インフォメックスの営業部の吉田一郎に連絡を希望しています。小林太郎はインフォメックスで行われているプロジェクトについて、先日吉田と相談した資料の送付について確認したいと考えています"
            
            適切なメモ:
            "【自社の状況】\\n・あなた: インフォメックス 営業部 内山\\n・吉田一郎: 席を外している（終日外出）\\n【相手先の情報】\\n・会社: オーエッチシー株式会社\\n・部署: 営業部\\n・役職: 部長\\n・名前: 小林太郎\\n【具体的な状況と背景】\\n・現在の状況: 吉田が先日、オーエッチシー株式会社とのプロジェクトで資料を送付済み\\n・プロジェクト名: 新規システム開発プロジェクト\\n・資料送付日: 11月15日\\n・資料内容: 要件定義書と見積もり\\n・必要な情報: 資料の到着確認、内容に関する質問\\n・注意点: 吉田は終日外出のため折り返し連絡が必要"
            
            ## 絶対的な禁止事項:
            - firstMessageで用件の詳細を伝えない
            - 韓国語、中国語などの日本語以外の文字を使用しない
            - 改行文字（\\\\n）を文字列内に含めない
            - マークダウン記法を使用しない
            - JSON以外のテキストを出力しない
            """.formatted(userName, companyName);

        // 難易度に応じた具体的な指示を生成するための定義
        String difficultyInstruction = """
            ### 難易度レベル定義 (この定義に従ってシナリオを作成してください):
            
            1. **簡単 (Easy)**:
               - **相手の態度**: 非常に丁寧、穏やか、協力的。
               - **用件**: 単純明快（例: 担当者の在席確認、簡単な伝言）。
               - **社内状況**: 担当者は「在席中」または「すぐ戻る」設定が多い。
               - **話し方**: ゆっくり、はっきりとした敬語。
            
            2. **普通 (Normal)**:
               - **相手の態度**: 標準的なビジネスライク、事務的。
               - **用件**: 少し詳細（例: 日程変更の依頼、資料の到着確認）。
               - **社内状況**: 担当者は「会議中」や「外出中」で、折り返し対応が必要。
               - **話し方**: 一般的なビジネス会話の速度。
            
            3. **難しい (Hard)**:
               - **相手の態度**: 早口、高圧的、焦っている、または少し苛立っている。
               - **用件**: 複雑、緊急、または情報が曖昧（例: 「あの件どうなった？」といきなり聞く、クレーム予備軍）。
               - **社内状況**: 担当者が「長期不在」「トラブル対応中」など、即答できない状況。
               - **話し方**: 専門用語が多い、主語が抜ける、結論を急かす。
            """;

        // ユーザープロンプト - 具体例を追加
        String userPrompt = String.format(
            "以下の条件で電話対応練習のシナリオを生成してください。\n\n" +
            "## ユーザー情報（電話を受ける側）:\n" +
            "- 名前: %s\n" +
            "- 会社: %s\n" +
            "- ジャンル: %s\n" +
            "- 雰囲気: %s\n" +
            "- 指定難易度: **%s**\n\n" +
            "## 重要な指示:\n" +
            "1. **firstMessageでは用件を伝えない** - 挨拶と担当者への接続依頼のみ\n" +
            "2. **メモには具体的な状況と背景**を詳細に記載\n" +
            "3. 電話をかけてくる相手はランダムに生成\n" +
            "4. 相手が求める人物もランダム（ユーザー本人 or 他の担当者）\n" + 
            "5. 日本語のみ使用、改行文字なし\n" +
            "6. 有効なJSON形式で出力\n\n" +
            "## メモの具体例参考:\n" +
            "良い例: \"【自社の状況】 ・あなた: インフォメックス 営業部 内山 ・吉田一郎: 席を外している（終日外出） 【相手先の情報】 ・会社: オーエッチシー株式会社 ・部署: 営業部 ・役職: 部長 ・名前: 小林太郎 【具体的な状況と背景】 ・現在の状況: 吉田が先日、オーエッチシー株式会社とのプロジェクトで資料を送付済み ・プロジェクト名: 新規システム開発プロジェクト ・資料送付日: 11月15日 ・資料内容: 要件定義書と見積もり ・必要な情報: 資料の到着確認、内容に関する質問 ・注意点: 吉田は終日外出のため折り返し連絡が必要\"\n\n" +
            "ランダムなビジネスシナリオでお願いします。",
            userName, companyName, genre, callAtmosphere, difficultyInstruction, difficulty
        );

        // Grok API のペイロード
        Map<String, Object> apiPayload = new HashMap<>();
        apiPayload.put("model", "llama-3.3-70b-versatile");
        List<Map<String, String>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", systemPrompt));
        messages.add(Map.of("role", "user", "content", userPrompt));
        apiPayload.put("messages", messages);

        // String apiKey = "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";
        String apiKey = "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";
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(apiPayload, headers);

        // RestTemplate（タイムアウト設定）
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(5000);
        requestFactory.setReadTimeout(15000);
        RestTemplate restTemplate = new RestTemplate(requestFactory);

        String grokUrl = "https://api.groq.com/openai/v1/chat/completions";

        try {
            logger.info("Calling Grok API at {}", grokUrl);
            ResponseEntity<String> responseEntity = restTemplate.postForEntity(grokUrl, request, String.class);

            if (!responseEntity.getStatusCode().is2xxSuccessful()) {
                logger.error("Grok returned non-2xx: {} - {}", responseEntity.getStatusCode(), responseEntity.getBody());
                return createErrorResponse("Grok API error: " + responseEntity.getStatusCode().toString());
            }

            String bodyText = responseEntity.getBody();
            logger.debug("Grok raw response: {}", bodyText);

            // OpenAI互換 chat response パース
            JsonNode root = mapper.readTree(bodyText);
            String content = null;

            if (root.has("choices") && root.get("choices").isArray() && root.get("choices").size() > 0) {
                JsonNode firstChoice = root.get("choices").get(0);
                if (firstChoice.has("message") && firstChoice.get("message").has("content")) {
                    content = firstChoice.get("message").get("content").asText();
                }
            }

            if (content == null || content.isBlank()) {
                logger.error("Grok response didn't include a parsable content.");
                return createErrorResponse("Grok response parsing error", bodyText);
            }

            logger.info("Original content from Grok: {}", content);

            // マークダウンと余分な文字を除去
            content = cleanContent(content);
            
            // JSON 文字列をパース
            JsonNode contentNode = parseJsonRobustly(content);
            
            if (contentNode == null) {
                logger.error("Failed to parse JSON after all attempts");
                return createStructuredFallbackResponse(content, userName, companyName);
            }

            // フィールドを抽出し、品質チェック
            Map<String, Object> extractedFields = extractAndValidateFields(contentNode, userName, companyName);

            // 会話状態をキャッシュに保存
            ConversationState conversationState = new ConversationState();
            conversationState.setMemo(extractedFields.get("memo").toString());
            conversationState.setScenario(extractedFields.get("scenario").toString());
            conversationState.setConversationHistory(new ArrayList<>());
            
            // 最初のメッセージを履歴に追加
            ConversationTurn firstTurn = new ConversationTurn("assistant", extractedFields.get("firstMessage").toString());
            conversationState.getConversationHistory().add(firstTurn);
            
            conversationCache.put(sessionId, conversationState);

            PhonePracticeResponseDTO response = new PhonePracticeResponseDTO();
            response.setSessionId(sessionId);
            response.setMemo(conversationState.getMemo());
            response.setScenario(conversationState.getScenario());
            response.setMessage(firstTurn.getContent());
            response.setTimestamp(Instant.now());
            response.setTurnCount(conversationState.getConversationHistory().size() / 2);
            response.setIsConversationEnd(false); // 最初のメッセージなので会話は終了していない

            logger.info("Successfully generated and validated scenario with sessionId: {}", sessionId);
            return response;

        } catch (Exception e) {
            logger.error("Error while calling Grok API", e);
            return createErrorResponse("Exception when calling Groq API", e.getMessage());
        }
    }

    /**
     * 2回目以降の返信を処理
     */
    public PhonePracticeResponseDTO continuePractice(PhonePracticeContinueRequestDTO requestDTO) {
        logger.info("=== PhonePracticeService.continuePractice ===");
        logger.info("セッションID: {}, ユーザーメッセージ: {}", requestDTO.getSessionId(), requestDTO.getMessage());
        logger.info("=============================================");

        String sessionId = requestDTO.getSessionId();
        String userMessage = requestDTO.getMessage();
 
        // 不適切/悪意のある入力チェックの前にセッションの存在を確認
        if (!conversationCache.containsKey(sessionId)) {
            logger.error("Session not found: {}", sessionId);
            return createErrorResponse("セッションが見つかりません", sessionId);
        }
 
        ConversationState conversationState = conversationCache.get(sessionId);
        
        logger.info("ユーザーメッセージ: '{}', isAbusiveOrInappropriateの結果: {}", userMessage, isAbusiveOrInappropriate(userMessage)); // 追加
        // 不適切/悪意のある入力チェック
        if (isAbusiveOrInappropriate(userMessage)) {
            logger.warn("不適切な発言を検出し、会話を終了します: {}", userMessage);
            
            // 評価を実施
            PhonePracticeEvaluationDTO evaluation = evaluateConversation(conversationState, "不適切な発言による強制終了");
            if (evaluation != null) {
                logger.info("不適切発言検出時の評価結果をキャッシュに保存します。sessionId: {}, totalScore: {}", sessionId, evaluation.getTotalScore());
                evaluationCache.put(sessionId, evaluation);
            } else {
                logger.warn("不適切発言検出時の評価結果がnullのため、キャッシュに保存できませんでした。sessionId: {}", sessionId);
            }
            conversationCache.remove(sessionId); // 評価キャッシュ保存後に移動
            
            PhonePracticeResponseDTO response = createEndResponse(
                sessionId,
                "申し訳ございませんが、不適切な発言を検出したため、電話をお切りします。",
                "相手が不適切な発言により電話を切りました。",
                true
            );
            response.setEvaluation(evaluation);
            return response;
        }

        // ユーザーメッセージを履歴に追加
        ConversationTurn userTurn = new ConversationTurn("user", userMessage);
        conversationState.getConversationHistory().add(userTurn);

        // Grok API用のメッセージリストを作成
        List<Map<String, String>> messages = new ArrayList<>();
        
        // 完璧なシステムプロンプト - 役割と振る舞いを明確に定義
        String systemPrompt = createPerfectSystemPrompt(conversationState);
        
        messages.add(Map.of("role", "system", "content", systemPrompt));
        
        // 会話履歴を追加（最新の2往復のみ）
        List<ConversationTurn> recentTurns = getRecentConversationTurns(conversationState.getConversationHistory(), 4);
        for (ConversationTurn turn : recentTurns) {
            messages.add(Map.of("role", turn.getRole(), "content", turn.getContent()));
        }

        logger.info("Sending {} messages to Grok API", messages.size());

        // Grok API のペイロード
        Map<String, Object> apiPayload = new HashMap<>();
        apiPayload.put("model", "llama-3.3-70b-versatile");
        apiPayload.put("messages", messages);
        apiPayload.put("max_tokens", 200);
        apiPayload.put("temperature", 0.2); // 低めにして一貫性を確保

        String apiKey = "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";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(apiPayload, headers);

        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(10000);
        requestFactory.setReadTimeout(30000);
        RestTemplate restTemplate = new RestTemplate(requestFactory);

        String grokUrl = "https://api.groq.com/openai/v1/chat/completions";

        try {
            logger.info("Calling Grok API for continuation at {}", grokUrl);
            ResponseEntity<String> responseEntity = restTemplate.postForEntity(grokUrl, request, String.class);

            logger.info("Grok API response status: {}", responseEntity.getStatusCode());

            if (!responseEntity.getStatusCode().is2xxSuccessful()) {
                logger.error("Grok returned non-2xx: {} - {}", responseEntity.getStatusCode(), responseEntity.getBody());
                return createContextualDefaultResponse(sessionId, conversationState, userMessage);
            }

            String bodyText = responseEntity.getBody();
            JsonNode root = mapper.readTree(bodyText);
            String assistantReply = "";

            if (root.has("choices") && root.get("choices").isArray() && root.get("choices").size() > 0) {
                JsonNode firstChoice = root.get("choices").get(0);
                if (firstChoice.has("message") && firstChoice.get("message").has("content")) {
                    assistantReply = firstChoice.get("message").get("content").asText();
                }
            }

            if (assistantReply == null || assistantReply.isBlank()) {
                logger.warn("Grok response content is empty, using default response");
                return createContextualDefaultResponse(sessionId, conversationState, userMessage);
            }

            logger.info("Raw Grok assistant reply: {}", assistantReply);

            // 高度なレスポンスクリーニング
            assistantReply = advancedResponseCleaning(assistantReply, conversationState.getMemo(), userMessage);

            // AIの返答を履歴に追加
            ConversationTurn assistantTurn = new ConversationTurn("assistant", assistantReply);
            conversationState.getConversationHistory().add(assistantTurn);

            // 会話状態を更新
            conversationCache.put(sessionId, conversationState);

            // 会話終了判断
            boolean isEnd = shouldEndConversation(assistantReply, userMessage, conversationState.getConversationHistory().size(), sessionId);
            String endReason = null;
            PhonePracticeEvaluationDTO evaluation = null;
            
            if (isEnd) {
                logger.info("会話終了条件を満たしました。sessionId: {}, isEnd: {}", sessionId, isEnd);
                endReason = "会話が自然に終了しました。";
                logger.info("Conversation ended: {}", assistantReply);
                
                // 会話終了時に評価を実施
                evaluation = evaluateConversation(conversationState, "自然終了");
                if (evaluation != null) {
                    logger.info("評価結果をキャッシュに保存します。sessionId: {}, totalScore: {}", sessionId, evaluation.getTotalScore());
                    evaluationCache.put(sessionId, evaluation);
                } else {
                    logger.warn("評価結果がnullのため、キャッシュに保存できませんでした。sessionId: {}", sessionId);
                }
                conversationCache.remove(sessionId); // 評価キャッシュ保存後に移動
            } else {
                logger.info("会話終了条件を満たしていません。isEnd: {}", isEnd);
            }

            PhonePracticeResponseDTO response = new PhonePracticeResponseDTO();
            response.setSessionId(sessionId);
            response.setMessage(assistantReply);
            response.setTimestamp(Instant.now());
            response.setIsConversationEnd(isEnd);
            response.setEndReason(endReason);
            response.setMemo(conversationState.getMemo());
            response.setScenario(conversationState.getScenario());
            response.setTurnCount(conversationState.getConversationHistory().size() / 2);
            response.setEvaluation(evaluation);

            logger.info("Final response: {}", response.getMessage());
            return response;

        } catch (Exception e) {
            logger.error("Error while calling Grok API for continuation", e);
            return createContextualDefaultResponse(sessionId, conversationState, userMessage);
        }
    }

    /**
     * 完璧なシステムプロンプトを作成（修正版）
     */
    private String createPerfectSystemPrompt(ConversationState conversationState) {
        String opponentCompany = extractCompanyFromMemo(conversationState.getMemo());
        String opponentName = extractNameFromMemo(conversationState.getMemo());
        String purpose = extractDetailedPurposeFromMemo(conversationState.getMemo());
        String targetPerson = extractTargetPersonFromScenario(conversationState.getScenario());

        return """
           あなたは「%s」の「%s」という実在のビジネスパーソンです。
           電話対応の練習相手役として、ユーザー（電話を受ける側）と会話を行います。
           
           ## あなたの役割定義（絶対厳守）
           - あなたは **電話をかけている側** です。絶対に「AIアシスタント」や「電話を受ける側」として振る舞わないでください。
           - 「いかがなさいましたか？」「何かお手伝いしましょうか？」といった、サポート役のセリフは **禁止** です。
           
           ## 現在の状況設定
           - あなたの情報: %s (%s)
           - 電話の目的: %s
           - 話したい相手: %s
           - 状況詳細: %s
           
           ## 会話のガイドライン（重要）
           
           1. **「少々お待ちください」と言われた場合**:
              - **「はい、お願いします」** や **「はい、承知いたしました」** とだけ短く答えてください。
              - 禁止: 「お時間を取りにください」「ごゆっくりどうぞ」などの不自然な配慮は絶対に言わないでください。
           
           2. **担当者が「不在」「席を外している」と言われた場合**:
              - 残念がりつつ、**「それでは、伝言をお願いできますでしょうか？」** や **「何時頃お戻りでしょうか？」** と質問してください。
              - もしくは、相手（電話口のユーザー）が要件を聞いてくれた場合は、素直に要件を伝えてください。
           
           3. **話し方のルール**:
              - 簡潔なビジネス口語を使ってください。
              - 一度に喋りすぎないでください（1ターンに1〜2文が理想）。
              - 文脈と無関係な「ありがとうございます」を連呼しないでください。
              - 自然な相槌（「左様でございますか」「なるほど」）を適度に入れてください。
           
           4. **目的の達成**:
              - 最終的に用件（%s）を相手に伝え、解決することを目指してください。
              - いきなり全ての情報を話さず、相手の反応を見ながら会話を進めてください。
           
           ## 出力生成の制約
           - 必ず日本語で出力すること。
           - 英語の直訳のような表現（例：「お時間を取りにください」「確認させてください」）は避けること。
           - 会話履歴の文脈を読み、直前のユーザーの発言に対して自然に繋がる応答をすること。
           """.formatted(
               opponentCompany, opponentName,
               opponentCompany, opponentName,
               purpose,
               targetPerson,
               conversationState.getMemo(),
               purpose
           );
    }
    /**
     * 高度なレスポンスクリーニング
     */
    /**
     * 高度なレスポンスクリーニング（修正版）
     */
    private String advancedResponseCleaning(String assistantReply, String memo, String userMessage) {
        String cleaned = assistantReply.trim();
        
        // 0. 特定の不自然なフレーズを強制置換（ログ対策）
        cleaned = cleaned.replace("お時間を取りにください", "お待ちしております")
                         .replace("お時間を取りに召しあがりください", "お待ちしております")
                         .replace("どうぞごゆっくり", "はい、お願いします")
                         .replace("時間を取ってください", "お待ちします");

        // 1. 基本的なクリーニング
        cleaned = cleanTextForFlutter(cleaned);
        
        // 2. 句読点の修正
        cleaned = fixPunctuation(cleaned);
        
        // 3. 自然な日本語への修正
        cleaned = naturalizeJapanesePhrases(cleaned);
        
        // 4. 役割の一貫性チェックと修正
        cleaned = enforceRoleConsistency(cleaned, memo, userMessage);
        
        // ユーザーが「お待ちください」系を言った直後のAIの返答補正
        String lowerUserMsg = userMessage.replaceAll("\\s", "");
        if (lowerUserMsg.contains("お待ちください") || lowerUserMsg.contains("確認します") || lowerUserMsg.contains("保留")) {
             // AIが長々と喋っていたら短くする
             if (cleaned.length() > 15) {
                 cleaned = "承知いたしました。お願いします。";
             }
        }

        // 5. 重複表現の削除
        cleaned = removeDuplicateExpressions(cleaned);
        
        // 6. 文末の調整
        cleaned = adjustEnding(cleaned, userMessage);
        
        return cleaned;
    }
    /**
     * 句読点を修正
     */
    private String fixPunctuation(String text) {
        if (text == null || text.isEmpty()) return text;
        
        String fixed = text;
        
        // 1. まず、すべての句点を一旦読点に置き換える（文末以外）
        // 文末の句点は保持するために、文単位に分割
        String[] sentences = fixed.split("。(?=[^」）])"); // 文末の句点で分割（ただし、括弧内を除く）
        List<String> processedSentences = new ArrayList<>();
        
        for (String sentence : sentences) {
            String processed = sentence;
            // 文の中の句点を読点に置き換え（ただし、数字や記号の後は除く）
            processed = processed.replaceAll("(?<=[^0-9\\s])\\。(?=[^\\s])", "、");
            processedSentences.add(processed);
        }
        
        fixed = String.join("。", processedSentences);
        
        // 2. 不自然な読点パターンを修正
        fixed = fixed
            .replace("お忙しい中、", "お忙しいところ")
            .replace("大変恐れ入りますが、", "恐れ入りますが")
            .replace("でございますが、", "ですが")
            .replace("いたしますが、", "しますが")
            .replace("いただきますが、", "いただきますが") // これは変更しない
            .replace("ございますが、", "ございますが"); // これは変更しない
        
        // 3. 連続する読点を修正
        fixed = fixed.replaceAll("、{2,}", "、");
        
        // 4. 文末の調整：文末が読点で終わっている場合は句点に変更
        fixed = fixed.replaceAll("、$", "。");
        
        return fixed;
    }
    /**
     * 役割の一貫性を強制
     */
    private String enforceRoleConsistency(String text, String memo, String userMessage) {
        String userCompany = extractUserCompanyFromMemo(memo);
        String userName = extractUserNameFromMemo(memo);
        String opponentCompany = extractCompanyFromMemo(memo);
        String opponentName = extractNameFromMemo(memo);
        
        // 明らかな役割逆転の検出と修正
        if (text.contains(userCompany + "の" + userName) && 
            (text.contains("申します") || text.contains("と申します"))) {
            logger.warn("役割逆転を検出して修正: {}", text);
            return text.replace(userCompany + "の" + userName, opponentCompany + "の" + opponentName)
                      .replace("申します", "でございます");
        }
        
        // 電話を受ける側の表現を検出
        String[] receiverExpressions = {
            "少々お待ちください", "確認いたします", "確認します", "お調べします", 
            "担当者をお呼びします", "折り返しお電話します"
        };
        
        for (String expr : receiverExpressions) {
            if (text.contains(expr)) {
                logger.warn("受信側の表現を検出して修正: {}", text);
                return "承知いたしました。";
            }
        }
        
        // 不自然な電話番号の提供を抑制
        if (text.matches(".*[0-9]{2,4}[\\-－][0-9]{2,4}[\\-－][0-9]{3,4}.*")) {
            logger.warn("不自然な電話番号提供を検出: {}", text);
            return "折り返しご連絡いただけますでしょうか。";
        }
        
        return text;
    }

    /**
     * 日本語表現を自然化
     */
    private String naturalizeJapanesePhrases(String text) {
        String naturalized = text;
        
        // 不自然な表現を修正
        Map<String, String> unnaturalToNatural = Map.ofEntries(
            Map.entry("でございますけど", "ですが"),
            Map.entry("でございますが", "ですが"),
            Map.entry("いたしますけど", "しますが"),
            Map.entry("いただきますでしょうか", "いただけますか"),
            Map.entry("お願いしたいと思っております", "お願いいたします"),
            Map.entry("お話ししたいことがあります", "ご連絡いたしました"),
            Map.entry("大変恐れ入りますが", "申し訳ございませんが"),
            Map.entry("どうぞお時間を取りにください", "お待ちください"),
            Map.entry("どうぞお時間を取りに召しあがりください", "お待ちください"),
            Map.entry("召しあがりください", "お待ちください"),
            Map.entry("承知いたしました、", "承知いたしました。"),
            Map.entry("ありがとうございます、", "ありがとうございます。"),
            Map.entry("よろしくお願いいたします、", "よろしくお願いいたします。")
        );
        
        for (Map.Entry<String, String> entry : unnaturalToNatural.entrySet()) {
            naturalized = naturalized.replace(entry.getKey(), entry.getValue());
        }
        
        return naturalized;
    }
    /**
     * 重複表現を削除
     */
    private String removeDuplicateExpressions(String text) {
        String[] phrases = text.split("[、。]");
        List<String> uniquePhrases = new ArrayList<>();
        Set<String> seenPhrases = new HashSet<>();
        
        for (String phrase : phrases) {
            String trimmed = phrase.trim();
            if (!trimmed.isEmpty() && !seenPhrases.contains(trimmed)) {
                uniquePhrases.add(trimmed);
                seenPhrases.add(trimmed);
            }
        }
        
        if (uniquePhrases.isEmpty()) {
            return text;
        }
        
        // 最後の文末記号を保持
        String result = String.join("、", uniquePhrases);
        if (text.endsWith("。") || text.endsWith("？") || text.endsWith("?")) {
            char lastChar = text.charAt(text.length() - 1);
            result += lastChar;
        } else {
            result += "。";
        }
        
        return result;
    }

    /**
     * 文末を調整
     */
    private String adjustEnding(String text, String userMessage) {
        if (text.isEmpty()) return text;
        
        char lastChar = text.charAt(text.length() - 1);
        
        // 既に適切な文末記号がある場合はそのまま
        if (lastChar == '。' || lastChar == '？' || lastChar == '!' || lastChar == '?') {
            return text;
        }
        
        // ユーザーの発言に基づいて文末を判断
        String lowerUserMessage = userMessage.toLowerCase();
        if (lowerUserMessage.contains("か") || lowerUserMessage.contains("でしょうか") || 
            lowerUserMessage.contains("ますか") || text.contains("でしょうか")) {
            return text + "？";
        } else {
            return text + "。";
        }
    }

    /**
     * 対象人物を抽出
     */
    private String extractTargetPersonFromScenario(String scenario) {
        if (scenario.contains("田中")) return "田中和樹様";
        if (scenario.contains("佐藤")) return "佐藤様";
        if (scenario.contains("鈴木")) return "鈴木様";
        if (scenario.contains("山田")) return "山田様";
        
        // パターンマッチングで抽出
        Pattern pattern = Pattern.compile("(.+?)様");
        java.util.regex.Matcher matcher = pattern.matcher(scenario);
        if (matcher.find()) {
            return matcher.group(1) + "様";
        }
        
        return "担当者様";
    }

    /**
     * 詳細な目的を抽出
     */
    private String extractDetailedPurposeFromMemo(String memo) {
        if (memo.contains("提案書") && memo.contains("確認")) {
            return "提案書の到着確認と内容についての質問";
        } else if (memo.contains("プロジェクト") && memo.contains("進捗")) {
            return "プロジェクトの進捗状況確認";
        } else if (memo.contains("打ち合わせ") && memo.contains("日程")) {
            return "次回打ち合わせの日程調整";
        } else if (memo.contains("資料") && memo.contains("送付")) {
            return "資料の送付と確認";
        } else if (memo.contains("問い合わせ")) {
            return "製品・サービスに関するお問い合わせ";
        }
        return "ご連絡";
    }

    /**
     * 強化された不適切発言検出
     */
    private boolean isAbusiveOrInappropriate(String message) {
        if (message == null || message.trim().isEmpty()) return false;
        
        String lowerMessage = message.toLowerCase().trim();
        
        // 悪意のある発言パターン
        String[] abusivePatterns = {
            "しね", "死ね", "くたばれ", "ばか", "あほ", "まぬけ",
            "殺す", "消えろ", "うせる", 
            "ばばあ", "くそ", "くそったれ", "畜生", "デブ", "ブス",
            "あほ", "ドアホ", "カス", "雑魚", "ゴミ"
        };
        
        for (String pattern : abusivePatterns) {
            if (lowerMessage.contains(pattern)) {
                logger.warn("不適切な発言を検出: {} -> {}", message, pattern);
                return true;
            }
        }
        
        // 繰り返しの無意味な発言
        if (isMeaninglessRepetition(message)) {
            return true;
        }
        
        return false;
    }

    /**
     * 無意味な繰り返しを検出
     */
    private boolean isMeaninglessRepetition(String message) {
        String cleanMessage = message.replaceAll("[\\s\\、。]", "");
        if (cleanMessage.length() < 2) return false;
        
        // 同じ文字の繰り返し（例: "あああ"）
        if (cleanMessage.matches("(.)\\1{3,}")) {
            return true;
        }
        
        // 同じ単語の繰り返し（例: "はいはいはい"）
        String[] words = message.split("[\\s\\、。]");
        if (words.length >= 3) {
            Set<String> uniqueWords = new HashSet<>();
            for (String word : words) {
                if (word.length() > 1) {
                    uniqueWords.add(word);
                }
            }
            if (uniqueWords.size() <= 1) {
                return true;
            }
        }
        
        return false;
    }

    /**
     * 会話終了判断の改善
     */
    private boolean shouldEndConversation(String assistantReply, String userMessage, int conversationLength, String sessionId) {
        // 最低限の会話長を確保 (2往復 = 4ターン)
        if (conversationLength < 4) {
            return false;
        }

        String lowerReply = assistantReply.toLowerCase();
        String lowerUserMessage = userMessage.toLowerCase();

        // 1. ユーザーの明確な終了意図
        boolean userExplicitlyEnding =
            lowerUserMessage.contains("失礼します") ||
            lowerUserMessage.contains("ありがとうございました") ||
            lowerUserMessage.contains("以上です") ||
            (lowerUserMessage.contains("ありがとう") && lowerUserMessage.contains("失礼します")) ||
            lowerUserMessage.contains("これで大丈夫です") ||
            lowerUserMessage.contains("結構です");

        // 2. AIの終了を促す発言後のユーザーの応答
        boolean aiPromptedEnding = false;
        if (conversationLength >= 2) {
            ConversationState state = conversationCache.get(sessionId);
            if (state != null && state.getConversationHistory().size() >= 2) {
                String lastAiMessage = state.getConversationHistory().get(state.getConversationHistory().size() - 2).getContent().toLowerCase();
                if (lastAiMessage.contains("これで用件は全てでしょうか") ||
                    lastAiMessage.contains("他にご用件はございますか") ||
                    lastAiMessage.contains("何か他にございますか")) {
                    // AIが終了を促した後、ユーザーが肯定的な終了応答をした場合
                    if (lowerUserMessage.contains("はい") || lowerUserMessage.contains("ええ") ||
                        lowerUserMessage.contains("大丈夫です") || lowerUserMessage.contains("結構です")) {
                        aiPromptedEnding = true;
                    }
                }
            }
        }
        

        // 3. 用件の完了度合い (メモと会話履歴から判断)
        boolean purposeAchieved = isPurposeAchieved(sessionId, conversationLength);

        // 4. 会話の膠着状態
        boolean isStalled = isConversationStalled(sessionId, conversationLength);

        // 5. AIの明示的な終了フレーズ (用件完了後、またはユーザーの終了意図と合わせて)
        boolean aiExplicitlyEnding =
            lowerReply.contains("失礼いたします") ||
            lowerReply.contains("お電話ありがとうございました") ||
            lowerReply.contains("それでは失礼します") ||
            (lowerReply.contains("よろしくお願いいたします") && conversationLength >= 6); // 3往復以上で「よろしくお願いいたします」は終了の可能性

        // 総合的な終了判断ロジック（柔軟性を高める）
        // 1. ユーザーが明示的に終了を意図している場合 (一定の会話長以上)
        if (userExplicitlyEnding && conversationLength >= 4) {
            logger.info("shouldEndConversation: ユーザーの明示的な終了意図によりtrue");
            return true;
        }
        
        // 2. AIが終了を促し、ユーザーがそれに同意した場合
        if (aiPromptedEnding) {
            logger.info("shouldEndConversation: AIの終了促しとユーザーの同意によりtrue");
            return true;
        }
        
        // 3. 用件が達成され、かつAIまたはユーザーが終了を示唆している場合、または会話が十分に進んだ場合
        if (purposeAchieved) {
            if (aiExplicitlyEnding || userExplicitlyEnding || conversationLength >= 6) { // 3往復以上で用件達成なら終了
                logger.info("shouldEndConversation: 用件達成と終了示唆/会話長によりtrue");
                return true;
            }
        }
        
        // 4. 会話が膠着状態に陥っている場合
        if (isStalled) {
            logger.info("shouldEndConversation: 会話が膠着状態によりtrue");
            return true;
        }
        
        // 5. AIが明確に終了を告げている場合 (ある程度の会話長を考慮)
        if (aiExplicitlyEnding && conversationLength >= 4) {
            logger.info("shouldEndConversation: AIの明示的な終了発言によりtrue");
            return true;
        }
        
        // 6. 会話のターン数が一定以上で、かつAIの最後の発言が用件を伝達し終えたと判断できる場合
        if (conversationLength >= 6) { // 最低3往復
            ConversationState state = conversationCache.get(sessionId);
            if (state != null && state.getConversationHistory().size() >= 2) {
                String lastAiMessage = state.getConversationHistory().get(state.getConversationHistory().size() - 1).getContent().toLowerCase();
                // AIが情報を伝え終えたと判断できるフレーズ
                if ((lastAiMessage.contains("ご連絡いたします") || lastAiMessage.contains("折り返します") || lastAiMessage.contains("承知いたしました")) &&
                    !(lastAiMessage.contains("でしょうか") || lastAiMessage.contains("ますか") || lastAiMessage.contains("ご用件は"))) {
                    logger.info("shouldEndConversation: 会話長とAIの用件伝達完了によりtrue");
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * 会話が膠着状態に陥っているかを判断するヘルパーメソッド
     */
    private boolean isConversationStalled(String sessionId, int conversationLength) {
        // 例: 8ターン以上会話が続き、かつ直近4ターンのユーザーメッセージが非常に短い、または繰り返しの場合
        if (conversationLength >= 8 && conversationCache.containsKey(sessionId)) {
            ConversationState state = conversationCache.get(sessionId);
            List<ConversationTurn> history = state.getConversationHistory();
            if (history.size() >= 4) { // ユーザーとAIの2往復分
                String lastUserMessage = history.get(history.size() - 1).getContent().toLowerCase();
                String secondLastUserMessage = history.get(history.size() - 3).getContent().toLowerCase(); // ユーザーの2つ前の発言

                // 短い返答の繰り返し
                if (lastUserMessage.length() < 10 && secondLastUserMessage.length() < 10 &&
                    (lastUserMessage.equals(secondLastUserMessage) ||
                     (lastUserMessage.contains("はい") && secondLastUserMessage.contains("はい")) ||
                     (lastUserMessage.contains("承知しました") && secondLastUserMessage.contains("承知しました")))) {
                    return true;
                }
                // 意味のない相槌の繰り返し
                if (lastUserMessage.matches("^(はい|ええ|うん|なるほど|そうですか|わかりました|承知しました)[。、]*$") &&
                    secondLastUserMessage.matches("^(はい|ええ|うん|なるほど|そうですか|わかりました|承知しました)[。、]*$")) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * 用件が達成されたかを判断するヘルパーメソッド
     */
    private boolean isPurposeAchieved(String sessionId, int conversationLength) {
        if (conversationLength < 6) { // 最低3往復は必要
            return false;
        }

        ConversationState state = conversationCache.get(sessionId);
        if (state == null) {
            return false;
        }

        String memo = state.getMemo();
        String scenario = state.getScenario();
        List<ConversationTurn> history = state.getConversationHistory();

        // メモから目的を抽出
        String purpose = extractDetailedPurposeFromMemo(memo);
        if (purpose.equals("ご連絡")) { // 汎用的な目的の場合は、より厳しく判断
            return false;
        }

        // 会話履歴全体を分析し、目的達成のキーワードが出ているか確認
        StringBuilder fullConversation = new StringBuilder();
        for (ConversationTurn turn : history) {
            fullConversation.append(turn.getContent()).append(" ");
        }
        String lowerFullConversation = fullConversation.toString().toLowerCase();

        // 目的達成の具体的なキーワード（より柔軟な判断）
        boolean purposeKeywordsPresent = false;
        if (purpose.contains("提案書") && (lowerFullConversation.contains("提案書") && (lowerFullConversation.contains("確認できました") || lowerFullConversation.contains("送付しました")))) {
            purposeKeywordsPresent = true;
        } else if (purpose.contains("進捗状況確認") && (lowerFullConversation.contains("進捗") && (lowerFullConversation.contains("共有できました") || lowerFullConversation.contains("お伝えしました")))) {
            purposeKeywordsPresent = true;
        } else if (purpose.contains("日程調整") && (lowerFullConversation.contains("日程") && (lowerFullConversation.contains("調整できました") || lowerFullConversation.contains("ご連絡いたします")))) {
            purposeKeywordsPresent = true;
        } else if (purpose.contains("資料の送付") && (lowerFullConversation.contains("資料") && (lowerFullConversation.contains("送付しました") || lowerFullConversation.contains("到着しました")))) {
            purposeKeywordsPresent = true;
        } else if (purpose.contains("お問い合わせ") && (lowerFullConversation.contains("回答") && (lowerFullConversation.contains("解決しました") || lowerFullConversation.contains("お伝えしました")))) {
            purposeKeywordsPresent = true;
        } else if (purpose.contains("ご連絡")) { // 汎用的な目的でも、会話が進んでいればOKとする
            if (conversationLength >= 8) { // 4往復以上の会話があれば用件は伝えられたと判断
                 purposeKeywordsPresent = true;
            }
        }
 
        // AIが用件の完了を示唆する発言をしているか
        boolean aiSuggestsCompletion = false;
        if (history.size() >= 2) {
            String lastAiMessage = history.get(history.size() - 2).getContent().toLowerCase();
            if (lastAiMessage.contains("これで用件は全てでしょうか") ||
                lastAiMessage.contains("他にご用件はございますか") ||
                lastAiMessage.contains("何か他にございますか") ||
                (lastAiMessage.contains("承知いたしました") && lastAiMessage.contains("ご連絡いたします")) ||
                lastAiMessage.contains("では、失礼いたします") ||
                lastAiMessage.contains("改めてご連絡いたします") ||
                lastAiMessage.contains("またご連絡いたします")) {
                aiSuggestsCompletion = true;
            }
        }
 
        // ユーザーが用件の完了を示唆する発言をしているか
        boolean userSuggestsCompletion = false;
        String lastUserMessage = history.get(history.size() - 1).getContent().toLowerCase();
        if (lastUserMessage.contains("はい、大丈夫です") ||
            lastUserMessage.contains("これで結構です") ||
            (lastUserMessage.contains("承知しました") && lastUserMessage.contains("ありがとうございます")) ||
            lastUserMessage.contains("またお願いします") ||
            lastUserMessage.contains("失礼いたします")) {
            userSuggestsCompletion = true;
        }
        
        // 用件達成の判断をより柔軟にする
        // 1. 目的達成キーワードがあり、かつAIまたはユーザーが完了を示唆
        if (purposeKeywordsPresent && (aiSuggestsCompletion || userSuggestsCompletion)) {
            logger.info("isPurposeAchieved: 用件達成キーワードと終了示唆によりtrue");
            return true;
        }
        
        // 2. 会話が長く、AIとユーザーの両方が完了を示唆している場合
        if (conversationLength >= 8 && aiSuggestsCompletion && userSuggestsCompletion) {
            logger.info("isPurposeAchieved: 会話が長く、両者が終了を示唆によりtrue");
            return true;
        }
 
        return false;
    }
    /**
     * 文脈に応じたデフォルト応答
     */
    private PhonePracticeResponseDTO createContextualDefaultResponse(String sessionId, ConversationState conversationState, String userMessage) {
        String defaultReply = generatePerfectDefaultReply(userMessage, conversationState.getMemo());
        
        ConversationTurn assistantTurn = new ConversationTurn("assistant", defaultReply);
        conversationState.getConversationHistory().add(assistantTurn);
        conversationCache.put(sessionId, conversationState);
        
        PhonePracticeResponseDTO response = new PhonePracticeResponseDTO();
        response.setSessionId(sessionId);
        response.setMessage(defaultReply);
        response.setTimestamp(Instant.now());
        response.setIsConversationEnd(false);
        response.setMemo(conversationState.getMemo());
        response.setScenario(conversationState.getScenario());
        response.setTurnCount(conversationState.getConversationHistory().size() / 2);
        
        logger.info("Using contextual default response: {}", defaultReply);
        return response;
    }

    /**
     * 完璧なデフォルト応答を生成
     */
    private String generatePerfectDefaultReply(String userMessage, String memo) {
        String lowerMessage = userMessage.toLowerCase();
        String opponentName = extractNameFromMemo(memo);
        String purpose = extractDetailedPurposeFromMemo(memo);
        
        if (lowerMessage.contains("確認") && lowerMessage.contains("待ち")) {
            return "承知いたしました。お願いします。";
        } else if (lowerMessage.contains("席を外") || lowerMessage.contains("不在")) {
            return "わかりました。折り返しご連絡いただけますでしょうか。";
        } else if (lowerMessage.contains("代わり") && lowerMessage.contains("伺い")) {
            return "ありがとうございます。" + purpose + "についてご確認いただけますか。";
        } else if (lowerMessage.contains("伝え")) {
            return "承知いたしました。よろしくお願いいたします。";
        } else if (lowerMessage.contains("はい") && lowerMessage.contains("失礼")) {
            return "失礼いたします。";
        } else {
            return "承知いたしました。";
        }
    }

    // ===== 既存のユーティリティメソッド =====

    /**
     * セッションIDを生成
     */
    private String generateSessionId(PhonePracticeRequestDTO requestDTO) {
        String baseId = requestDTO.getUserName() + "_" + requestDTO.getCompanyName() + "_" + 
                       requestDTO.getGenre() + "_" + requestDTO.getCallAtmosphere();
        return baseId + "_" + Instant.now().toEpochMilli();
    }

    /**
     * コンテンツをクリーニング
     */
    private String cleanContent(String content) {
        if (content == null) return "";
        
        // マークダウンのコードブロックを完全に除去
        content = content.replaceAll("```json\\n?", "");
        content = content.replaceAll("```\\n?", "");
        
        // JSON以外のテキストを除去（JSONの前後のテキスト）
        int start = content.indexOf('{');
        int end = content.lastIndexOf('}') + 1;
        
        if (start >= 0 && end > start) {
            content = content.substring(start, end);
        }
        
        return content.trim();
    }

    /**
     * 強力なJSONパース処理
     */
    private JsonNode parseJsonRobustly(String content) {
        // 試行1: 直接パース
        try {
            return mapper.readTree(content);
        } catch (Exception e) {
            logger.debug("Direct parse failed: {}", e.getMessage());
        }
        
        // 試行2: JSONオブジェクトを抽出してパース
        try {
            String jsonStr = extractJsonObject(content);
            if (jsonStr != null) {
                return mapper.readTree(jsonStr);
            }
        } catch (Exception e) {
            logger.debug("Extracted JSON parse failed: {}", e.getMessage());
        }
        
        return null;
    }

    /**
     * JSONオブジェクトを抽出
     */
    private String extractJsonObject(String content) {
        // { から } までを抽出
        int start = content.indexOf('{');
        int end = content.lastIndexOf('}') + 1;
        
        if (start >= 0 && end > start) {
            return content.substring(start, end);
        }
        
        return null;
    }

    /**
     * フィールドを抽出し、バリデーション
     */
    private Map<String, Object> extractAndValidateFields(JsonNode contentNode, String userName, String companyName) {
        Map<String, Object> result = new HashMap<>();
        
        String memo = "";
        String scenario = "";
        String firstMessage = "";
        
        if (contentNode.has("memo")) {
            memo = contentNode.get("memo").asText();
            memo = enhanceMemoContent(memo, userName, companyName);
        }
        
        if (contentNode.has("scenario")) {
            scenario = contentNode.get("scenario").asText();
            scenario = cleanTextForFlutter(scenario);
        }
        
        if (contentNode.has("firstMessage")) {
            firstMessage = contentNode.get("firstMessage").asText();
            firstMessage = validateAndCleanFirstMessage(firstMessage);
        }
        
        result.put("memo", memo);
        result.put("scenario", scenario);
        result.put("firstMessage", firstMessage);
        
        return result;
    }

    /**
     * メモ内容を強化
     */
    private String enhanceMemoContent(String memo, String userName, String companyName) {
        if (memo == null || memo.trim().isEmpty()) {
            return createContextualMemo(userName, companyName);
        }
        
        // メモが簡素すぎる場合や形式が適切でない場合は強化
        if (memo.length() < 150 || !memo.contains("【") || !memo.contains("】")) {
            return createContextualMemo(userName, companyName);
        }
        
        // ユーザー情報が含まれているか確認
        if (!memo.contains(userName) && !memo.contains(companyName)) {
            memo = addUserContextToMemo(memo, userName, companyName);
        }
        
        return cleanTextForFlutter(memo);
    }

    /**
     * 状況に応じたメモを作成
     */
    private String createContextualMemo(String userName, String companyName) {
        // ランダムなビジネスシチュエーションに基づいたメモを作成
        String[] situations = {
            "【自社の状況】 ・あなた: %s %s 営業部 ・山田課長: 会議中（15時まで） 【相手先の情報】 ・会社: 東京商事 ・部署: 購買部 ・役職: 主任 ・名前: 佐藤健一 【具体的な状況と背景】 ・現在の状況: 先週提案した新商品の見積もりについて問合せ ・プロジェクト名: 新商品導入プロジェクト ・見積もり金額: 250万円 ・納期: 2週間 ・必要な情報: 見積もり内容の確認、数量変更の可能性 ・注意点: 山田課長に確認が必要な事項あり",
            "【自社の状況】 ・あなた: %s %s 総務部 ・鈴木部長: 外出中（終日） 【相手先の情報】 ・会社: さくら銀行 ・部署: 融資部 ・役職: 支店長 ・名前: 田中宏 【具体的な状況と背景】 ・現在の状況: 来月更新の事務所賃貸契約について相談 ・契約満了日: 12月20日 ・現在の賃料: 月額80万円 ・必要な情報: 更新条件、賃料改定の有無 ・注意点: 鈴木部長が折り返し連絡することを伝える",
            "【自社の状況】 ・あなた: %s %s 開発部 ・佐藤プロジェクトリーダー: 客先訪問中 【相手先の情報】 ・会社: ABCソフトウェア ・部署: 技術部 ・役職: 部長 ・名前: 伊藤正 【具体的な状況と背景】 ・現在の状況: 共同開発プロジェクトの進捗確認 ・プロジェクト名: 次期基幹システム開発 ・現在の進捗: 設計フェーズ完了 ・次のマイルストーン: 12月15日 ・必要な情報: 開発環境の設定状況、課題の有無 ・注意点: 佐藤が16時に戻る予定"
        };
        
        Random random = new Random();
        String situation = situations[random.nextInt(situations.length)];
        return String.format(situation, companyName, userName);
    }

    /**
     * メモにユーザーコンテキストを追加
     */
    private String addUserContextToMemo(String memo, String userName, String companyName) {
        if (memo.contains("【自社の状況】")) {
            return memo.replace("【自社の状況】", String.format("【自社の状況】 ・あなた: %s %s", companyName, userName));
        } else {
            return String.format("【自社の状況】 ・あなた: %s %s ", companyName, userName) + memo;
        }
    }

    /**
     * firstMessageをバリデーションとクリーニング
     */
    private String validateAndCleanFirstMessage(String firstMessage) {
        if (firstMessage == null || firstMessage.trim().isEmpty()) {
            return "お世話になっております。○○株式会社の△△と申します。ご担当者様はいらっしゃいますでしょうか？";
        }
        
        // 基本クリーニング
        String cleaned = cleanTextForFlutter(firstMessage);
        
        // 用件の詳細が含まれていないかチェック
        if (containsBusinessDetails(cleaned)) {
            cleaned = removeBusinessDetails(cleaned);
        }
        
        // 自然な日本語に修正
        cleaned = naturalizeJapanese(cleaned);
        
        return cleaned;
    }

    /**
     * ビジネス詳細が含まれているかチェック
     */
    private boolean containsBusinessDetails(String text) {
        String[] businessKeywords = {
            "について", "確認", "相談", "問合せ", "依頼", "納期", "商品", "注文", 
            "発注", "プロジェクト", "打合せ", "会議", "契約", "請求", "価格", "資料", "送付"
        };
        
        for (String keyword : businessKeywords) {
            if (text.contains(keyword) && 
                !text.contains("いらっしゃいます") && 
                !text.contains("お願い") && 
                !text.contains("でしょうか")) {
                return true;
            }
        }
        return false;
    }

    /**
     * ビジネス詳細を除去
     */
    private String removeBusinessDetails(String text) {
        // "について"以降を削除するなど、詳細を除去
        if (text.contains("について")) {
            int index = text.indexOf("について");
            text = text.substring(0, index) + "でございますが、";
        }
        
        // 特定のパターンを除去
        text = text
            .replaceAll("詳細を確認したい", "")
            .replaceAll("ご連絡いたしました", "お電話いたしました")
            .replaceAll("ということで", "")
            .replaceAll("という件で", "")
            .replaceAll("資料の送付", "")
            .trim();
        
        // 最後に基本的な接続依頼を追加
        if (!text.contains("いらっしゃいます") && !text.contains("お願い")) {
            if (text.endsWith("が、") || text.endsWith("で、")) {
                text += "ご担当者様はいらっしゃいますでしょうか？";
            } else {
                text += "。ご担当者様はいらっしゃいますでしょうか？";
            }
        }
        
        return text;
    }

    /**
     * Flutter表示用にテキストをクリーニング
     */
    private String cleanTextForFlutter(String text) {
        if (text == null || text.trim().isEmpty()) {
            return "";
        }
        
        // 韓国語・中国語文字を除去
        text = removeNonJapaneseCharacters(text);
        
        // 改行文字を除去（Flutterで問題が発生するため）
        text = text.replaceAll("\\\\n", " ").replaceAll("\\n", " ");
        
        // 連続する空白を単一の空白に
        text = text.replaceAll("\\s+", " ");
        
        return text.trim();
    }

    /**
     * 日本語以外の文字を除去
     */
    private String removeNonJapaneseCharacters(String text) {
        if (text == null) return "";
        
        // 日本語（ひらがな、カタカナ、漢字、英数字、記号）以外を除去
        text = text.replaceAll("[^\\u3040-\\u309F\\u30A0-\\u30FF\\u4E00-\\u9FFF\\uFF00-\\uFFEF\\u0000-\\u007E\\u3000-\\u303F]", "");
        
        return text;
    }

    /**
     * 日本語を自然化
     */
    private String naturalizeJapanese(String text) {
        if (text == null) return "";
        
        String normalized = text
            // 不自然な表現を修正
            .replace("ではありませんか？", "ではございませんか？")
            .replace("ご縁がありました", "ご連絡させていただきました")
            .replace("確認したいということで", "")
            .replace("詳細を確認したい", "")
            .replace("いらっしゃいますか", "いらっしゃいますでしょうか")
            .replace("からです", "でございます")
            .replace("ですが、", "でございますが、")
            .replace("したいのですが", "させていただきたいのですが")
            .trim();
        
        // 基本的な敬語チェックと補完
        if (!normalized.contains("ございます") && !normalized.contains("いたします") && !normalized.contains("いただきます")) {
            // 丁寧な表現が不足している場合、基本的な敬語を追加
            if (normalized.contains("です") && !normalized.contains("でございます")) {
                normalized = normalized.replace("です", "でございます");
            }
        }
        
        // 文末の調整
        if (!normalized.endsWith("。") && !normalized.endsWith("？") && !normalized.endsWith("?") && !normalized.endsWith("か？")) {
            if (normalized.contains("いらっしゃいます")) {
                normalized += "？";
            } else {
                normalized += "。";
            }
        }
        
        return normalized;
    }

    /**
     * 構造化されたフォールバックレスポンスを作成
     */
    private PhonePracticeResponseDTO createStructuredFallbackResponse(String content, String userName, String companyName) {
        logger.warn("Creating structured fallback response");
        
        String memo = extractMemoFromText(content, userName, companyName);
        String scenario = extractScenarioFromText(content);
        String firstMessage = extractFirstMessageFromText(content);
        
        PhonePracticeResponseDTO fallback = new PhonePracticeResponseDTO();
        fallback.setMemo(memo);
        fallback.setScenario(scenario);
        fallback.setMessage(firstMessage);
        fallback.setTimestamp(Instant.now());
        fallback.setIsConversationEnd(false); // フォールバックなので会話は継続
        fallback.setEndReason("Grok APIからの応答が不正だったため、フォールバック情報が生成されました。");
        
        return fallback;
    }

    /**
     * テキストからメモを抽出
     */
    private String extractMemoFromText(String content, String userName, String companyName) {
        String memo = extractField(content, "memo");
        if (memo != null) {
            return enhanceMemoContent(memo, userName, companyName);
        }
        
        return createContextualMemo(userName, companyName);
    }

    /**
     * テキストからシナリオを抽出
     */
    private String extractScenarioFromText(String content) {
        String scenario = extractField(content, "scenario");
        if (scenario != null) {
            return cleanTextForFlutter(scenario);
        }
        
        return "取引先からの問い合わせ電話です。";
    }

    /**
     * テキストからfirstMessageを抽出
     */
    private String extractFirstMessageFromText(String content) {
        String firstMessage = extractField(content, "firstMessage");
        if (firstMessage != null) {
            return validateAndCleanFirstMessage(firstMessage);
        }
        
        return "お世話になっております。○○株式会社の△△と申します。ご担当者様はいらっしゃいますでしょうか？";
    }

    /**
     * フィールドを抽出
     */
    private String extractField(String content, String fieldName) {
        String pattern = "\"" + fieldName + "\"\\s*:\\s*\"([^\"]*)\"";
        Pattern p = Pattern.compile(pattern);
        java.util.regex.Matcher m = p.matcher(content);
        
        if (m.find()) {
            return m.group(1);
        }
        
        return null;
    }

    /**
     * 最近の会話ターンを取得（制限付き）
     */
    private List<ConversationTurn> getRecentConversationTurns(List<ConversationTurn> history, int maxTurns) {
        if (history.size() <= maxTurns) {
            return new ArrayList<>(history);
        }
        return new ArrayList<>(history.subList(history.size() - maxTurns, history.size()));
    }

    // ===== 情報抽出メソッド =====

    /**
     * メモから相手会社名を抽出
     */
    private String extractCompanyFromMemo(String memo) {
        if (memo.contains("【相手先の情報】") && memo.contains("・会社:")) {
            String[] lines = memo.split("\n");
            for (String line : lines) {
                if (line.contains("・会社:")) {
                    return line.replace("・会社:", "").trim();
                }
            }
        }
        return "取引先会社";
    }

    /**
     * メモから相手部署を抽出
     */
    private String extractDepartmentFromMemo(String memo) {
        if (memo.contains("【相手先の情報】") && memo.contains("・部署:")) {
            String[] lines = memo.split("\n");
            for (String line : lines) {
                if (line.contains("・部署:")) {
                    return line.replace("・部署:", "").trim();
                }
            }
        }
        return "対応部署";
    }

    /**
     * メモから相手役職を抽出
     */
    private String extractPositionFromMemo(String memo) {
        if (memo.contains("【相手先の情報】") && memo.contains("・役職:")) {
            String[] lines = memo.split("\n");
            for (String line : lines) {
                if (line.contains("・役職:")) {
                    return line.replace("・役職:", "").trim();
                }
            }
        }
        return "担当者";
    }

    /**
     * メモから相手名前を抽出
     */
    private String extractNameFromMemo(String memo) {
        if (memo.contains("【相手先の情報】") && memo.contains("・名前:")) {
            String[] lines = memo.split("\n");
            for (String line : lines) {
                if (line.contains("・名前:")) {
                    return line.replace("・名前:", "").trim();
                }
            }
        }
        return "担当者";
    }

    /**
     * メモからユーザー会社名を抽出
     */
    private String extractUserCompanyFromMemo(String memo) {
        if (memo.contains("【自社の状況】") && memo.contains("あなた:")) {
            String[] lines = memo.split("\n");
            for (String line : lines) {
                if (line.contains("あなた:")) {
                    String youInfo = line.replace("あなた:", "").trim();
                    String[] parts = youInfo.split(" ");
                    return parts.length > 0 ? parts[0] : "自社";
                }
            }
        }
        return "自社";
    }

    /**
     * メモからユーザー部署を抽出
     */
    private String extractUserDepartmentFromMemo(String memo) {
        if (memo.contains("【自社の状況】") && memo.contains("あなた:")) {
            String[] lines = memo.split("\n");
            for (String line : lines) {
                if (line.contains("あなた:")) {
                    String youInfo = line.replace("あなた:", "").trim();
                    String[] parts = youInfo.split(" ");
                    return parts.length > 1 ? parts[1] : "営業部";
                }
            }
        }
        return "営業部";
    }

    /**
     * メモからユーザー名を抽出
     */
    private String extractUserNameFromMemo(String memo) {
        if (memo.contains("【自社の状況】") && memo.contains("あなた:")) {
            String[] lines = memo.split("\n");
            for (String line : lines) {
                if (line.contains("あなた:")) {
                    String youInfo = line.replace("あなた:", "").trim();
                    String[] parts = youInfo.split(" ");
                    return parts.length > 1 ? parts[parts.length - 1] : "ユーザー";
                }
            }
        }
        return "ユーザー";
    }

    // ===== レスポンス作成メソッド =====

    /**
     * エラーレスポンスを作成
     */
    private PhonePracticeResponseDTO createErrorResponse(String errorMessage) {
        return createErrorResponse(errorMessage, null);
    }

    private PhonePracticeResponseDTO createErrorResponse(String errorMessage, String rawResponse) {
        PhonePracticeResponseDTO response = new PhonePracticeResponseDTO();
        response.setMessage("エラーが発生しました: " + errorMessage);
        response.setIsConversationEnd(true);
        response.setEndReason("エラー: " + errorMessage);
        if (rawResponse != null) {
            logger.error("Raw Grok response for error: {}", rawResponse);
        }
        response.setTimestamp(Instant.now());
        return response;
    }

    /**
     * 会話終了レスポンスを作成
     */
    private PhonePracticeResponseDTO createEndResponse(String sessionId, String message, String endReason, boolean isConversationEnd) {
        PhonePracticeResponseDTO response = new PhonePracticeResponseDTO();
        response.setSessionId(sessionId);
        response.setMessage(message);
        response.setTimestamp(Instant.now());
        response.setIsConversationEnd(isConversationEnd);
        response.setEndReason(endReason);
        return response;
    }

    /**
     * 会話の状態をクリア、および評価を行う（ユーザーが電話を切った場合など）
     */
    public PhonePracticeResponseDTO endPracticeAndEvaluate(String sessionId) {
        logger.info("PhonePracticeService.endPracticeAndEvaluate: セッションID {} の評価とクリアを開始", sessionId);
        logger.info("現在のconversationCacheの状態: {}", conversationCache.keySet());
        if (!conversationCache.containsKey(sessionId)) {
            logger.warn("PhonePracticeService.endPracticeAndEvaluate: セッションID {} がconversationCacheに見つかりません。評価なしで終了。", sessionId);
            return createErrorResponse("セッションが見つかりません", sessionId);
        }

        ConversationState conversationState = conversationCache.get(sessionId);
        logger.info("セッションID {} のconversationStateを取得しました。", sessionId);
        
        // 評価を実施
        PhonePracticeEvaluationDTO evaluation = evaluateConversation(conversationState, "ユーザーによる強制終了");
        logger.info("evaluateConversationの結果: evaluation is {}", (evaluation != null ? "NOT null (score: " + evaluation.getTotalScore() + ")" : "null"));
        
        if (evaluation != null) {
            logger.info("評価結果をキャッシュに保存します。sessionId: {}, totalScore: {}", sessionId, evaluation.getTotalScore());
            evaluationCache.put(sessionId, evaluation);
        } else {
            logger.warn("評価結果がnullのため、キャッシュに保存できませんでした。sessionId: {}", sessionId);
        }

        // 会話キャッシュをクリア
        conversationCache.remove(sessionId);
        logger.info("Cleared conversation for session: {}", sessionId);

        PhonePracticeResponseDTO response = new PhonePracticeResponseDTO();
        response.setSessionId(sessionId);
        response.setIsConversationEnd(true);
        response.setEndReason("ユーザーが電話を切りました。会話が終了し、評価が保存されました。");
        response.setMessage("電話を終了しました。評価が保存されました。");
        response.setTimestamp(Instant.now());
        response.setEvaluation(evaluation);
        return response;
    }

    /**
     * 電話対応を評価するメソッド
     */
    private PhonePracticeEvaluationDTO evaluateConversation(ConversationState conversationState, String endReason) {
        logger.info("=== 電話対応評価開始 ===");
        if (conversationState == null) {
            logger.error("evaluateConversation: conversationStateがnullです。デフォルト評価を作成します。");
            return createDefaultEvaluation(conversationState, endReason); // conversationStateがnullの場合も考慮
        }
        
        try {
            // 評価用のシステムプロンプト
            String systemPrompt = """
                あなたは厳格で優秀な電話対応評価AIです。ユーザーの電話対応を徹底的に評価し、100点満点で採点します。
                
                ## 評価基準:
                
                1. **理解力 (20点)**:
                   - 相手の意図や情報をどれだけ正確に理解できたか。
                   - 質問に対する適切な聞き返しや確認。
                   - 例: "「〇〇の件で」という相手の発言に対して、「〇〇の件でございますね、承知いたしました」と正しく復唱できたため高評価です。"
                
                2. **ビジネスマナー (20点)**:
                   - 適切な挨拶、言葉遣い、態度（ログから推測）。
                   - 電話の開始から終了までのプロフェッショナルな振る舞い。
                   - 例: "電話口での第一声の挨拶が明瞭で、好印象を与えました。"
                
                3. **敬語 (20点)**:
                   - 適切な敬語（尊敬語、謙譲語、丁寧語）の選択と使用。
                   - 不自然な敬語や二重敬語の有無。
                   - 例: "「確認いたします」という謙譲語を適切に使用できていました。"
                
                4. **対応の流れ (20点)**:
                   - 会話の進行がスムーズで、論理的であったか。
                   - 相手を待たせる時間の長さや、適切な状況説明。
                   - 例: "担当者不在の際、「〇〇は現在席を外しておりまして、〇時頃に戻る予定です」と簡潔かつ適切に状況を説明できていました。"
                
                5. **シナリオ達成度 (20点)**:
                   - 電話の目的（相手の要望、必要な情報の聞き取り、伝達）をどれだけ達成できたか。
                   - 担当者不在の場合の適切な対応（折り返し連絡の確認、伝言の受け付けなど）。
                   - 用件が完了していない場合の減点は厳しく行う。
                   - 例: "相手の「資料の到着確認」という要望に対して、「資料は無事お手元に届きましたでしょうか？」と具体的な内容を確認できていました。"
                
                ## 出力形式 (JSONのみ):
                {
                  "total_score": 85,
                  "summary": "総合評価の要約",
                  "key_strengths": ["強み1", "強み2", "強み3"],
                  "critical_improvements": ["改善点1", "改善点2"],
                  "next_steps": ["今後のアドバイス1", "アドバイス2"],
                  "detailed_feedback": {
                    "comprehension_feedback": "理解力に関する詳細なフィードバック（具体例引用を含む）",
                    "business_manner_feedback": "ビジネスマナーに関する詳細なフィードバック（具体例引用を含む）",
                    "politeness_feedback": "敬語に関する詳細なフィードバック（具体例引用を含む）",
                    "flow_of_response_feedback": "対応の流れに関する詳細なフィードバック（具体例引用を含む）",
                    "scenario_achievement_feedback": "シナリオ達成度に関する詳細なフィードバック（具体例引用を含む）"
                  },
                  "score_breakdown": {
                    "comprehension": 17,
                    "business_manner": 16,
                    "politeness": 15,
                    "flow_of_response": 18,
                    "scenario_achievement": 19
                  }
                }
                
                厳格かつ建設的な評価をお願いします。
                特に、**シナリオで設定された相手の要望（目的）を達成できなかった場合や、必要な情報を聞き取れなかった場合は、総合スコアに大きく影響する形で減点してください。**
                また、**各詳細フィードバックには、ユーザーの実際の発言内容を具体的に引用し、それに対する評価（良かった点、改善点）を詳しく記述してください。**
                """;

            // 会話履歴を評価用のテキストに変換
            StringBuilder conversationText = new StringBuilder();
            conversationText.append("【電話対応のシナリオ】\n").append(conversationState.getScenario()).append("\n\n");
            conversationText.append("【状況メモ】\n").append(conversationState.getMemo()).append("\n\n");
            conversationText.append("【会話履歴】\n");
            
            for (ConversationTurn turn : conversationState.getConversationHistory()) {
                String role = turn.getRole().equals("user") ? "ユーザー" : "相手";
                conversationText.append(role).append(": ").append(turn.getContent()).append("\n");
            }
            conversationText.append("\n【会話終了理由】: ").append(endReason);

            // Grok API のペイロード
            Map<String, Object> apiPayload = new HashMap<>();
            apiPayload.put("model", "llama-3.3-70b-versatile");
            
            List<Map<String, String>> messages = new ArrayList<>();
            messages.add(Map.of("role", "system", "content", systemPrompt));
            messages.add(Map.of("role", "user", "content", conversationText.toString()));
            
            apiPayload.put("messages", messages);
            apiPayload.put("max_tokens", 2000);
            apiPayload.put("temperature", 0.3);

            String apiKey = "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";

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(apiPayload, headers);

            SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
            requestFactory.setConnectTimeout(15000);
            requestFactory.setReadTimeout(30000);
            RestTemplate restTemplate = new RestTemplate(requestFactory);

            String grokUrl = "https://api.groq.com/openai/v1/chat/completions";

            logger.info("Calling Grok API for evaluation at {}", grokUrl);
            logger.debug("Grok API evaluation request payload: {}", mapper.writeValueAsString(apiPayload)); // 送信ペイロードをログ出力
            ResponseEntity<String> responseEntity = restTemplate.postForEntity(grokUrl, request, String.class);

            logger.info("Grok API evaluation response status: {}", responseEntity.getStatusCode());
            if (!responseEntity.getStatusCode().is2xxSuccessful()) {
                logger.error("Grok evaluation returned non-2xx: {} - Body: {}", responseEntity.getStatusCode(), responseEntity.getBody());
                return createDefaultEvaluation(conversationState, endReason);
            }
            String bodyText = responseEntity.getBody();

            logger.debug("Grok evaluation raw response: {}", bodyText); // ログ行を元に戻す
            JsonNode root = mapper.readTree(bodyText);
            String evaluationContent = "";

            if (root.has("choices") && root.get("choices").isArray() && root.get("choices").size() > 0) {
                JsonNode firstChoice = root.get("choices").get(0);
                if (firstChoice.has("message") && firstChoice.get("message").has("content")) {
                    evaluationContent = firstChoice.get("message").get("content").asText();
                    logger.debug("Extracted evaluation content from Grok: {}", evaluationContent);
                    logger.debug("Full Grok evaluation content: {}", evaluationContent); // 追加
                }
            }

            if (evaluationContent == null || evaluationContent.isBlank()) {
                logger.debug("Grok evaluation content is empty or null, using default evaluation. Raw body: {}", bodyText);
                return createDefaultEvaluation(conversationState, endReason);
            }

            // JSONのクリーニング
            evaluationContent = cleanContent(evaluationContent);
            JsonNode evaluationNode = parseJsonRobustly(evaluationContent);
            logger.debug("Parsed evaluation JSON node: {}", evaluationNode.toString()); // 追加
            
            if (evaluationNode == null) {
                logger.debug("Failed to parse evaluation JSON after cleaning, using default evaluation. Cleaned content: {}", evaluationContent);
                return createDefaultEvaluation(conversationState, endReason);
            }

            // 評価結果をDTOにマッピング
            PhonePracticeEvaluationDTO evaluation = new PhonePracticeEvaluationDTO();
            evaluation.setSessionId(conversationState.getScenario() + "_" + Instant.now().toEpochMilli());
            evaluation.setEvaluatedAt(Instant.now());
            
            if (evaluationNode.has("total_score")) {
                evaluation.setTotalScore(evaluationNode.get("total_score").asInt());
            }
            
            if (evaluationNode.has("summary")) {
                evaluation.setSummary(evaluationNode.get("summary").asText());
            }
            
            if (evaluationNode.has("key_strengths") && evaluationNode.get("key_strengths").isArray()) {
                List<String> strengths = new ArrayList<>();
                for (JsonNode strength : evaluationNode.get("key_strengths")) {
                    strengths.add(strength.asText());
                }
                evaluation.setKeyStrengths(strengths);
            }
            
            if (evaluationNode.has("critical_improvements") && evaluationNode.get("critical_improvements").isArray()) {
                List<String> improvements = new ArrayList<>();
                for (JsonNode improvement : evaluationNode.get("critical_improvements")) {
                    improvements.add(improvement.asText());
                }
                evaluation.setCriticalImprovements(improvements);
            }
            
            if (evaluationNode.has("next_steps") && evaluationNode.get("next_steps").isArray()) {
                List<String> nextSteps = new ArrayList<>();
                for (JsonNode step : evaluationNode.get("next_steps")) {
                    nextSteps.add(step.asText());
                }
                evaluation.setNextSteps(nextSteps);
            }
            
            // 詳細評価をMapとして保存
            Map<String, Object> detailedEval = new HashMap<>();
            if (evaluationNode.has("detailed_feedback")) {
                JsonNode feedback = evaluationNode.get("detailed_feedback");
                feedback.fields().forEachRemaining(entry -> {
                    detailedEval.put(entry.getKey(), entry.getValue().asText());
                });
            }
            
            if (evaluationNode.has("score_breakdown")) {
                JsonNode breakdown = evaluationNode.get("score_breakdown");
                breakdown.fields().forEachRemaining(entry -> {
                    detailedEval.put(entry.getKey(), entry.getValue().asText()); // detailedEvalにはフィードバックテキストを保存
                    // 新しいintフィールドにスコアを直接マッピング
                    switch (entry.getKey()) {
                        case "comprehension":
                            evaluation.setComprehensionScore(entry.getValue().asInt());
                            break;
                        case "business_manner":
                            evaluation.setBusinessMannerScore(entry.getValue().asInt());
                            break;
                        case "politeness":
                            evaluation.setPolitenessScore(entry.getValue().asInt());
                            break;
                        case "flow_of_response":
                            evaluation.setFlowOfResponseScore(entry.getValue().asInt());
                            break;
                        case "scenario_achievement":
                            evaluation.setScenarioAchievementScore(entry.getValue().asInt());
                            break;
                    }
                });
            }
            
            evaluation.setDetailedEvaluation(detailedEval);
            
            // DTOにマッピングされた内容をログ出力
            logger.info("評価DTOマッピング完了: totalScore={}, summary={}", evaluation.getTotalScore(), evaluation.getSummary());
            logger.info("Key Strengths: {}", evaluation.getKeyStrengths());
            logger.info("Critical Improvements: {}", evaluation.getCriticalImprovements());
            logger.info("Next Steps: {}", evaluation.getNextSteps());
            logger.info("Detailed Evaluation: {}", evaluation.getDetailedEvaluation());

            logger.info("評価完了: スコア {}点", evaluation.getTotalScore());
            return evaluation;

        } catch (Exception e) {
            logger.error("Error during conversation evaluation", e);
            return createDefaultEvaluation(conversationState, endReason);
        }
    }

    /**
     * デフォルト評価を作成（評価APIが失敗した場合用）
     */
    private PhonePracticeEvaluationDTO createDefaultEvaluation(ConversationState conversationState, String endReason) {
        logger.warn("createDefaultEvaluation: デフォルト評価を作成します。理由: {}", endReason);
        PhonePracticeEvaluationDTO evaluation = new PhonePracticeEvaluationDTO();
        String sessionId;

        if (conversationState != null && conversationState.getConversationHistory() != null && !conversationState.getConversationHistory().isEmpty()) {
            // 会話履歴がある場合、それに基づいた評価を生成
            sessionId = conversationState.getConversationHistory().get(0).getContent() + "_" + Instant.now().toEpochMilli();
            
            int totalScore = calculateScoreBasedOnConversation(conversationState);
            evaluation.setTotalScore(totalScore);
            evaluation.setSummary(generateSummary(conversationState, endReason));
            evaluation.setKeyStrengths(generateKeyStrengths(conversationState));
            evaluation.setCriticalImprovements(generateCriticalImprovements(conversationState));
            evaluation.setNextSteps(generateNextSteps(conversationState));
            
            // 各スコアとフィードバックも会話履歴に基づいて生成
            evaluation.setComprehensionScore(calculateComprehensionScore(conversationState));
            evaluation.setComprehensionFeedback(generateComprehensionFeedback(conversationState));
            
            evaluation.setBusinessMannerScore(calculateBusinessMannerScore(conversationState));
            evaluation.setBusinessMannerFeedback(generateBusinessMannerFeedback(conversationState));
            
            evaluation.setPolitenessScore(calculatePolitenessScore(conversationState));
            evaluation.setPolitenessFeedback(generatePolitenessFeedback(conversationState));
            
            evaluation.setFlowOfResponseScore(calculateFlowOfResponseScore(conversationState));
            evaluation.setFlowOfResponseFeedback(generateFlowOfResponseFeedback(conversationState));
            
            evaluation.setScenarioAchievementScore(calculateScenarioAchievementScore(conversationState));
            evaluation.setScenarioAchievementFeedback(generateScenarioAchievementFeedback(conversationState));

            Map<String, Object> detailedEval = new HashMap<>();
            detailedEval.put("comprehension_feedback", evaluation.getComprehensionFeedback());
            detailedEval.put("business_manner_feedback", evaluation.getBusinessMannerFeedback());
            detailedEval.put("politeness_feedback", evaluation.getPolitenessFeedback());
            detailedEval.put("flow_of_response_feedback", evaluation.getFlowOfResponseFeedback());
            detailedEval.put("scenario_achievement_feedback", evaluation.getScenarioAchievementFeedback());
            
            detailedEval.put("comprehension_score", evaluation.getComprehensionScore());
            detailedEval.put("business_manner_score", evaluation.getBusinessMannerScore());
            detailedEval.put("politeness_score", evaluation.getPolitenessScore());
            detailedEval.put("flow_of_response_score", evaluation.getFlowOfResponseScore());
            detailedEval.put("scenario_achievement_score", evaluation.getScenarioAchievementScore());

            evaluation.setDetailedEvaluation(detailedEval);


        } else {
            // 会話履歴がない場合、汎用的なデフォルト評価を生成
            sessionId = (conversationState != null && conversationState.getScenario() != null) ?
                                 conversationState.getScenario() + "_" + Instant.now().toEpochMilli() :
                                 "default_session_" + Instant.now().toEpochMilli();
            evaluation.setTotalScore(70); // 汎用的なデフォルトスコア
            evaluation.setSummary("電話対応は基本的に良好でした。評価システムに一時的な問題が発生しました。");
            evaluation.setKeyStrengths(List.of("基本的な電話対応マナー", "状況説明の明確さ"));
            evaluation.setCriticalImprovements(List.of("より詳細な評価のために再度練習してください"));
            evaluation.setNextSteps(List.of("様々なシナリオで練習を続ける", "ビジネス敬語の習得を深める"));
            
            Map<String, Object> detailedEval = new HashMap<>();
            detailedEval.put("politeness_feedback", "基本的な敬語は使用できています");
            detailedEval.put("appropriateness_feedback", "状況に応じた対応ができています");
            detailedEval.put("efficiency_feedback", "会話の流れは自然でした");
            detailedEval.put("business_manner_feedback", "基本的なビジネスマナーは守れています");
            
            evaluation.setDetailedEvaluation(detailedEval);
            
            evaluation.setComprehensionScore(15);
            evaluation.setBusinessMannerScore(14);
            evaluation.setPolitenessScore(16);
            evaluation.setFlowOfResponseScore(15);
            evaluation.setScenarioAchievementScore(10);

            evaluation.setComprehensionFeedback("評価システムで一時的な問題が発生したため、理解力に関する詳細なフィードバックを提供できません。");
            evaluation.setBusinessMannerFeedback("評価システムで一時的な問題が発生したため、ビジネスマナーに関する詳細なフィードバックを提供できません。");
            evaluation.setPolitenessFeedback("評価システムで一時的な問題が発生したため、敬語に関する詳細なフィードバックを提供できません。");
            evaluation.setFlowOfResponseFeedback("評価システムで一時的な問題が発生したため、対応の流れに関する詳細なフィードバックを提供できません。");
            evaluation.setScenarioAchievementFeedback("評価システムで一時的な問題が発生したため、シナリオ達成度に関する詳細なフィードバックを提供できません。");
            evaluation.setSessionId(sessionId);
            evaluation.setEvaluatedAt(Instant.now());
        }
        
        logger.info("createDefaultEvaluation: デフォルト評価を生成しました。sessionId: {}, totalScore: {}", evaluation.getSessionId(), evaluation.getTotalScore());
        return evaluation;
    }

    /**
     * 会話履歴に基づいて総合スコアを計算するメソッド
     */
    private int calculateScoreBasedOnConversation(ConversationState conversationState) {
        int score = 0;
        if (conversationState != null && conversationState.getConversationHistory() != null) {
            int turns = conversationState.getConversationHistory().size();
            // 会話ターン数に基づいて基本スコアを調整
            if (turns < 2) {
                score = 30; // ほとんど会話がない場合
            } else if (turns < 6) {
                score = 50; // 短い会話
            } else {
                score = 70; // ある程度の会話
            }

            // シナリオ達成度を考慮
            String purpose = extractDetailedPurposeFromMemo(conversationState.getMemo());
            if (!purpose.equals("ご連絡")) { // 汎用的な目的でなければ、達成度をスコアに反映
                boolean achieved = isPurposeAchieved(null, turns); // sessionIdはここでは使用しない
                if (achieved) {
                    score += 15;
                } else if (turns > 4) { // 途中終了でも、ある程度会話があれば減点しすぎない
                    score -= 10;
                }
            }
            
            // 不適切発言があった場合は大きく減点
            if (conversationState.getConversationHistory().stream()
                .anyMatch(turn -> turn.getRole().equals("user") && isAbusiveOrInappropriate(turn.getContent()))) {
                score -= 30;
            }

            // スコアが0を下回らないように、100を超えないように調整
            score = Math.max(0, score);
            score = Math.min(100, score);
        }
        return score;
    }

    /**
     * 会話履歴に基づいて要約を生成するメソッド
     */
    private String generateSummary(ConversationState conversationState, String endReason) {
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) {
            return "会話履歴がありません。";
        }
        StringBuilder summary = new StringBuilder();
        summary.append("今回の電話対応は");

        int turns = conversationState.getConversationHistory().size();
        if (turns < 2) {
            summary.append("開始直後に終了しました。");
        } else {
            summary.append("途中まで行われました。");
        }

        if (endReason != null && !endReason.isEmpty()) {
            summary.append("終了理由: ").append(endReason).append("。");
        }

        // 会話の最初の数ターンから要約を生成
        List<ConversationTurn> recentTurns = getRecentConversationTurns(conversationState.getConversationHistory(), 2);
        if (!recentTurns.isEmpty()) {
            summary.append("会話の冒頭では「").append(recentTurns.get(0).getContent()).append("」と始まり、");
            if (recentTurns.size() > 1) {
                summary.append("ユーザーは「").append(recentTurns.get(1).getContent()).append("」と応答しました。");
            }
        }
        return summary.toString();
    }

    /**
     * 会話履歴に基づいて強みを生成するメソッド
     */
    private List<String> generateKeyStrengths(ConversationState conversationState) {
        List<String> strengths = new ArrayList<>();
        if (conversationState != null && conversationState.getConversationHistory() != null) {
            long userTurns = conversationState.getConversationHistory().stream().filter(t -> t.getRole().equals("user")).count();
            if (userTurns > 0) {
                strengths.add("ユーザーの発言に耳を傾ける姿勢");
            }
            if (userTurns > 2 && conversationState.getConversationHistory().stream().anyMatch(t -> t.getRole().equals("user") && t.getContent().contains("確認"))) {
                strengths.add("不明点の確認を適切に行う能力");
            }
            if (userTurns > 3 && conversationState.getConversationHistory().stream().anyMatch(t -> t.getRole().equals("user") && t.getContent().contains("申し訳ございません"))) {
                 strengths.add("謝罪と配慮の表現");
            }
        }
        if (strengths.isEmpty()) {
            strengths.add("基本的な電話対応マナー");
        }
        return strengths;
    }

    /**
     * 会話履歴に基づいて改善点を生成するメソッド
     */
    private List<String> generateCriticalImprovements(ConversationState conversationState) {
        List<String> improvements = new ArrayList<>();
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) {
            improvements.add("会話が短すぎるため、より長く続ける練習をしましょう。");
            return improvements;
        }

        long userTurns = conversationState.getConversationHistory().stream().filter(t -> t.getRole().equals("user")).count();
        if (userTurns < 2) {
            improvements.add("まだ会話が十分ではありません。もっと積極的に会話を続けましょう。");
        }

        // 不適切発言のチェック
        if (conversationState.getConversationHistory().stream()
            .anyMatch(turn -> turn.getRole().equals("user") && isAbusiveOrInappropriate(turn.getContent()))) {
            improvements.add("不適切な発言がありました。ビジネスにふさわしい言葉遣いを心がけましょう。");
        }

        // 用件が達成されていない可能性
        String purpose = extractDetailedPurposeFromMemo(conversationState.getMemo());
        if (!purpose.equals("ご連絡") && !isPurposeAchieved(null, conversationState.getConversationHistory().size())) {
            improvements.add("相手の用件を最後まで聞き取れていない可能性があります。");
        }
        
        if (improvements.isEmpty()) {
            improvements.add("より詳細な評価のために再度練習してください。");
        }

        return improvements;
    }

    /**
     * 会話履歴に基づいて次のステップを生成するメソッド
     */
    private List<String> generateNextSteps(ConversationState conversationState) {
        List<String> nextSteps = new ArrayList<>();
        nextSteps.add("様々なシナリオで練習を続ける");
        nextSteps.add("ビジネス敬語の習得を深める");

        if (conversationState != null && conversationState.getConversationHistory() != null) {
            long userTurns = conversationState.getConversationHistory().stream().filter(t -> t.getRole().equals("user")).count();
            if (userTurns < 3) {
                nextSteps.add("会話を途中で終わらせず、相手の意図を汲み取る練習をしましょう。");
            }
        }
        return nextSteps;
    }

    /**
     * 会話履歴に基づいて理解力スコアを計算するメソッド
     */
    private int calculateComprehensionScore(ConversationState conversationState) {
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) return 0;
        int score = 10; // 基本点
        long userConfirmations = conversationState.getConversationHistory().stream()
            .filter(t -> t.getRole().equals("user") && (t.getContent().contains("承知いたしました") || t.getContent().contains("分かりました") || t.getContent().contains("確認いたします")))
            .count();
        score += Math.min(10, (int) userConfirmations * 3); // 確認回数に応じて加点

        // 相手の質問に答えられていない場合減点
        long unansweredQuestions = 0;
        for (int i = 0; i < conversationState.getConversationHistory().size() - 1; i++) {
            ConversationTurn current = conversationState.getConversationHistory().get(i);
            ConversationTurn next = conversationState.getConversationHistory().get(i + 1);
            if (current.getRole().equals("assistant") && current.getContent().contains("？") && next.getRole().equals("user") && (next.getContent().contains("はい") || next.getContent().length() < 5)) {
                unansweredQuestions++;
            }
        }
        score -= Math.min(10, (int) unansweredQuestions * 5);

        return Math.max(0, Math.min(20, score));
    }

    /**
     * 会話履歴に基づいて理解力フィードバックを生成するメソッド
     */
    private String generateComprehensionFeedback(ConversationState conversationState) {
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) {
            return "会話履歴が短いため、理解力に関する詳細なフィードバックを提供できません。";
        }
        StringBuilder feedback = new StringBuilder();
        int score = calculateComprehensionScore(conversationState);
        feedback.append("理解力: ");
        if (score >= 15) {
            feedback.append("相手の意図を正確に理解し、適切な応答ができていました。");
        } else if (score >= 10) {
            feedback.append("基本的な理解力はありますが、一部聞き返しや確認が不足している場面も見受けられました。");
        } else {
            feedback.append("相手の意図を把握するのに苦労したようです。積極的に質問をして確認しましょう。");
        }
        return feedback.toString();
    }

    /**
     * 会話履歴に基づいてビジネスマナースコアを計算するメソッド
     */
    private int calculateBusinessMannerScore(ConversationState conversationState) {
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) return 0;
        int score = 15; // 基本点
        
        // 挨拶の有無
        if (conversationState.getConversationHistory().get(0).getContent().contains("お世話になっております")) {
            score += 2;
        }

        // 不適切発言があった場合は大きく減点
        if (conversationState.getConversationHistory().stream()
            .anyMatch(turn -> turn.getRole().equals("user") && isAbusiveOrInappropriate(turn.getContent()))) {
            score -= 10;
        }

        return Math.max(0, Math.min(20, score));
    }

    /**
     * 会話履歴に基づいてビジネスマナーフィードバックを生成するメソッド
     */
    private String generateBusinessMannerFeedback(ConversationState conversationState) {
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) {
            return "会話履歴が短いため、ビジネスマナーに関する詳細なフィードバックを提供できません。";
        }
        StringBuilder feedback = new StringBuilder();
        int score = calculateBusinessMannerScore(conversationState);
        feedback.append("ビジネスマナー: ");
        if (score >= 15) {
            feedback.append("丁寧な言葉遣いと落ち着いた対応で、非常に良い印象を与えました。");
        } else if (score >= 10) {
            feedback.append("基本的なマナーは守れていますが、一部改善の余地があります。");
        } else {
            feedback.append("不適切な発言や、より丁寧な対応が必要な場面がありました。");
        }
        return feedback.toString();
    }

    /**
     * 会話履歴に基づいて敬語スコアを計算するメソッド
     */
    private int calculatePolitenessScore(ConversationState conversationState) {
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) return 0;
        int score = 15; // 基本点
        
        long inappropriatePoliteness = conversationState.getConversationHistory().stream()
            .filter(t -> t.getRole().equals("user") && (t.getContent().contains("ですけど") || t.getContent().contains("じゃなくて")))
            .count();
        score -= Math.min(10, (int) inappropriatePoliteness * 5);

        return Math.max(0, Math.min(20, score));
    }

    /**
     * 会話履歴に基づいて敬語フィードバックを生成するメソッド
     */
    private String generatePolitenessFeedback(ConversationState conversationState) {
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) {
            return "会話履歴が短いため、敬語に関する詳細なフィードバックを提供できません。";
        }
        StringBuilder feedback = new StringBuilder();
        int score = calculatePolitenessScore(conversationState);
        feedback.append("敬語: ");
        if (score >= 15) {
            feedback.append("尊敬語、謙譲語、丁寧語を適切に使用できていました。");
        } else if (score >= 10) {
            feedback.append("基本的な敬語は使えていますが、さらに自然な表現を目指しましょう。");
        } else {
            feedback.append("一部、不適切な敬語やタメ口が見受けられました。再確認が必要です。");
        }
        return feedback.toString();
    }

    /**
     * 会話履歴に基づいて対応の流れスコアを計算するメソッド
     */
    private int calculateFlowOfResponseScore(ConversationState conversationState) {
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) return 0;
        int score = 15; // 基本点
        
        // 会話の途切れ、沈黙が長すぎる場合を減点
        // (ここではログから直接判断できないため、会話ターン数である程度の推定)
        if (conversationState.getConversationHistory().size() < 4 && conversationState.getConversationHistory().stream().anyMatch(t -> t.getRole().equals("assistant") && t.getContent().length() < 5)) {
            score -= 5; // 短い会話でAIからの短い応答が多い場合
        }

        return Math.max(0, Math.min(20, score));
    }

    /**
     * 会話履歴に基づいて対応の流れフィードバックを生成するメソッド
     */
    private String generateFlowOfResponseFeedback(ConversationState conversationState) {
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) {
            return "会話履歴が短いため、対応の流れに関する詳細なフィードバックを提供できません。";
        }
        StringBuilder feedback = new StringBuilder();
        int score = calculateFlowOfResponseScore(conversationState);
        feedback.append("対応の流れ: ");
        if (score >= 15) {
            feedback.append("会話がスムーズに進み、相手を不必要に待たせることなく対応できていました。");
        } else if (score >= 10) {
            feedback.append("対応の流れは概ね良好ですが、一部間延びする場面や、もっと積極的に会話をリードできる場面がありました。");
        } else {
            feedback.append("会話の流れが途切れたり、相手を混乱させてしまう場面が見受けられました。スムーズな会話を心がけましょう。");
        }
        return feedback.toString();
    }

    /**
     * 会話履歴に基づいてシナリオ達成度スコアを計算するメソッド
     */
    private int calculateScenarioAchievementScore(ConversationState conversationState) {
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) return 0;
        int score = 10; // 基本点

        // 用件が達成されているか
        if (isPurposeAchieved(null, conversationState.getConversationHistory().size())) {
            score += 10;
        } else if (conversationState.getConversationHistory().size() >= 6) { // ある程度の会話があって未達成なら減点
            score -= 5;
        }

        // 担当者不在時の適切な対応
        String memo = conversationState.getMemo();
        String targetPerson = extractTargetPersonFromScenario(conversationState.getScenario());
        if (memo.contains(targetPerson) && memo.contains("不在") &&
            conversationState.getConversationHistory().stream().anyMatch(t -> t.getRole().equals("user") && (t.getContent().contains("折り返し") || t.getContent().contains("伝言")))) {
            score += 3; // 不在対応ができていれば加点
        }

        return Math.max(0, Math.min(20, score));
    }

    /**
     * 会話履歴に基づいてシナリオ達成度フィードバックを生成するメソッド
     */
    private String generateScenarioAchievementFeedback(ConversationState conversationState) {
        if (conversationState == null || conversationState.getConversationHistory().isEmpty()) {
            return "会話履歴が短いため、シナリオ達成度に関する詳細なフィードバックを提供できません。";
        }
        StringBuilder feedback = new StringBuilder();
        int score = calculateScenarioAchievementScore(conversationState);
        feedback.append("シナリオ達成度: ");
        if (score >= 15) {
            feedback.append("相手の用件を正確に把握し、必要な情報を聞き取ることができていました。");
        } else if (score >= 10) {
            feedback.append("用件の把握は概ね良好ですが、もう少し踏み込んだ確認ができるとより良いでしょう。");
        } else {
            feedback.append("相手の用件を完全に達成できていない可能性があります。会話の目的を常に意識しましょう。");
        }
        return feedback.toString();
    }

    /**
     * 評価結果を取得するエンドポイント
     */
    public PhonePracticeEvaluationDTO getEvaluation(String sessionId) {
        logger.info("PhonePracticeService.getEvaluation: セッションID {} の評価結果を取得試行", sessionId);
        if (evaluationCache.containsKey(sessionId)) {
            PhonePracticeEvaluationDTO evaluation = evaluationCache.get(sessionId);
            logger.info("PhonePracticeService.getEvaluation: セッションID {} の評価結果をキャッシュから発見: スコア {}", sessionId, evaluation.getTotalScore());
            return evaluation;
        } else {
            logger.warn("PhonePracticeService.getEvaluation: セッションID {} の評価結果がキャッシュに見つかりません。現在のキャッシュキー: {}", sessionId, evaluationCache.keySet());
            // キャッシュに見つからない場合でも、デフォルト評価を生成して返す
            logger.warn("PhonePracticeService.getEvaluation: セッションID {} の評価結果がキャッシュに見つかりません。デフォルト評価を生成します。", sessionId);
            // デフォルト評価には conversationState が必要だが、ここでは取得できないためnullを渡す
            return createDefaultEvaluation(null, "評価データが見つかりません。");
        }
    }
}
