package com.bridge.backend.service;

import com.bridge.backend.dto.AnswerDTO;
import com.bridge.backend.dto.InterviewDTO;
import com.bridge.backend.dto.InterviewRequestDTO;
import com.bridge.backend.entity.Interview;
import com.bridge.backend.repository.InterviewRepository;
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
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

@Service
public class InterviewService {

    private static final Logger logger = LoggerFactory.getLogger(InterviewService.class);

    private final InterviewRepository interviewRepository;

    public InterviewService(InterviewRepository interviewRepository) {
        this.interviewRepository = interviewRepository;
    }

    // --------------------------------------
    // 質問取得
    // --------------------------------------
    public List<Interview> createInterviewQuestions(InterviewDTO interviewDTO) {
        int type = convertType(interviewDTO.getQuestionType());
        int count = interviewDTO.getQuestionCount();

        List<Interview> allQuestions = interviewRepository.findByType(type);
        Collections.shuffle(allQuestions, new Random());

        if (allQuestions.size() > count) {
            allQuestions = allQuestions.subList(0, count);
        }

        return allQuestions;
    }

    public List<Interview> getRandomInterviewQuestions(InterviewRequestDTO requestDTO) {
        int questionType = convertType(requestDTO.getQuestionType());
        int questionCount = requestDTO.getQuestionCount();
        return interviewRepository.findRandomByType(questionType, questionCount);
    }

    public List<Interview> getQuestionsByType(int type, int count) {
        List<Interview> allQuestions = interviewRepository.findByType(type);
        Collections.shuffle(allQuestions);
        return allQuestions.subList(0, Math.min(count, allQuestions.size()));
    }

    public List<Interview> getAllInterviews() {
        return interviewRepository.findAll();
    }

    // --------------------------------------
    // DTO文字列 → タイプ番号
    // --------------------------------------
    private int convertType(String type) {
        switch (type.toLowerCase()) {
            case "normal": return 1;
            case "casual": return 2;
            case "pressure": return 3;
            default: return 1;
        }
    }

    // --------------------------------------
    // 回答を受け取り、Grok AI APIに送信して評価
    // --------------------------------------
    public String saveAnswers(List<AnswerDTO> answers, String interviewType) {
    logger.info("受け取った解答: {}", answers);

    if (answers.isEmpty()) {
        logger.warn("回答リストが空です");
        return "{}"; // 空のJSONを返すか、適切なエラーメッセージを返す
    }

    Map<String, String> companyInfo = new HashMap<>(answers.get(0).getCompanyInfo());

    Map<String, Object> payload = new HashMap<>();
    payload.put("model", "llama-3.3-70b-versatile");

    // 強化されたシステムプロンプト
    StringBuilder systemPromptBuilder = new StringBuilder();
    systemPromptBuilder.append("あなたは非常に厳格で優秀な面接官です。学生の回答を徹底的に評価し、100点満点で採点します。以下の指示に厳密に従ってください。\n");
    systemPromptBuilder.append("\n");
    systemPromptBuilder.append("【評価のポイント】\n");
    systemPromptBuilder.append("1. 論理性 (30点): 回答は常に論理的でなければなりません。具体例は必須であり、根拠が不明確な場合は大幅に減点します。\n");
    systemPromptBuilder.append("2. 企業適合性 (30点): 業界・規模・雰囲気に完全に合致した内容である必要があります。商社なら交渉力・調整力、中小企業なら柔軟性・実践力、堅実な雰囲気なら信頼性・計画性を強く重視します。適合しない場合は厳しく減点します。\n");
    systemPromptBuilder.append("3. 表現力 (20点): 言語表現は完璧でなければなりません。敬語の誤用、不適切な専門用語の扱いは許容しません。\n");
    systemPromptBuilder.append("4. 面接対応力 (20点): 面接タイプ（normal/casual/pressure）に完全に適切に対応しているか。不適切な対応は厳しく減点します。\n");
    systemPromptBuilder.append("\n");
    systemPromptBuilder.append("【評価方法】\n");
    systemPromptBuilder.append("- 総合評価を100点満点で採点。甘い採点は厳禁です。\n");
    systemPromptBuilder.append("- 各質問に対して、回答の具体的な部分を引用し、「～～」これは良かった、「～～」ここは改善が必要、と詳細かつ厳しくレビュー。\n");
    systemPromptBuilder.append("- ダメな点ははっきりと、かつ容赦なく指摘し、なぜダメなのか理由を明確に説明。改善の余地がない場合はその旨も伝える。\n");
    systemPromptBuilder.append("- 改善のための具体的なアドバイスを提供。ただし、学生が自力で考える余地を残しつつ、厳しさを忘れないこと。\n");
    systemPromptBuilder.append("\n");
    systemPromptBuilder.append("【出力形式】\n");
    systemPromptBuilder.append("以下のJSON形式で出力してください：\n");
    systemPromptBuilder.append("\n");
    systemPromptBuilder.append("{\n");
    systemPromptBuilder.append("  \"evaluations\": [\n");
    systemPromptBuilder.append("    {\n");
    systemPromptBuilder.append("      \"question\": \"質問文\",\n");
    systemPromptBuilder.append("      \"answer\": \"学生の回答\",\n");
    systemPromptBuilder.append("      \"score_breakdown\": {\n");
    systemPromptBuilder.append("        \"logic\": 点数,\n");
    systemPromptBuilder.append("        \"company_fit\": 点数,\n");
    systemPromptBuilder.append("        \"expression\": 点数,\n");
    systemPromptBuilder.append("        \"interview_response\": 点数\n");
    systemPromptBuilder.append("      },\n");
    systemPromptBuilder.append("      \"detailed_feedback\": {\n");
    systemPromptBuilder.append("        \"good_points\": [\"良い点の具体的引用と説明\", ...],\n");
    systemPromptBuilder.append("        \"bad_points\": [\"悪い点の具体的引用と説明\", ...],\n");
    systemPromptBuilder.append("        \"specific_advice\": \"具体的な改善アドバイス\"\n");
    systemPromptBuilder.append("      }\n");
    systemPromptBuilder.append("    }\n");
    systemPromptBuilder.append("  ],\n");
    systemPromptBuilder.append("  \"overall_assessment\": {\n");
    systemPromptBuilder.append("    \"total_score\": 100点満点の総合点,\n");
    systemPromptBuilder.append("    \"summary\": \"総合評価の要約\",\n");
    systemPromptBuilder.append("    \"key_strengths\": [\"強み1\", \"強み2\"],\n");
    systemPromptBuilder.append("    \"critical_improvements\": [\"優先改善点1\", \"優先改善点2\"],\n");
    systemPromptBuilder.append("    \"next_steps\": [\"次回の面接でのアドバイス1\", \"アドバイス2\"]\n");
    systemPromptBuilder.append("  }\n");
    systemPromptBuilder.append("}\n");
    systemPromptBuilder.append("\n");
    systemPromptBuilder.append("学生が次回の面接で確実に改善できるよう、実践的で具体的なフィードバックを作成してください。ただし、厳しさを忘れず、改善の余地が少ない場合はその旨も明確に伝えてください。\n");
    String systemPrompt = systemPromptBuilder.toString();

    List<Map<String, String>> messages = new ArrayList<>();

    messages.add(Map.of(
        "role", "system",
        "content", systemPrompt
    ));

    StringBuilder userContent = new StringBuilder();
    userContent.append("面接タイプ: ").append(interviewType).append("\n");
    userContent.append("会社情報: ").append(companyInfo.toString()).append("\n\n");

    for (AnswerDTO a : answers) {
        userContent.append("質問: ").append(a.getQuestion()).append("\n");
        userContent.append("回答: ").append(a.getAnswer()).append("\n\n");
    }

    messages.add(Map.of(
        "role", "user",
        "content", userContent.toString()
    ));

    payload.put("messages", messages);

    String grokApiUrl = "https://api.groq.com/openai/v1/chat/completions"; // 仮URL
    String apiKey = "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";

    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    headers.set("Authorization", "Bearer " + apiKey);

    HttpEntity<Map<String, Object>> request = new HttpEntity<>(payload, headers);

    // RestTemplate の設定（タイムアウト追加）
    RestTemplate restTemplate = new RestTemplate();
    SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
    factory.setConnectTimeout(5000); // 接続タイムアウト 5秒
    factory.setReadTimeout(10000); // 読み取りタイムアウト 10秒
    restTemplate.setRequestFactory(factory);

    try {
        ResponseEntity<String> response = restTemplate.postForEntity(grokApiUrl, request, String.class);
        if (response.getStatusCode().is2xxSuccessful()) {
            logger.info("Grok AI 評価結果: {}", response.getBody());
            return response.getBody(); // 評価結果を返す
        } else {
            logger.error("Grok AI 送信失敗: {} - {}", response.getStatusCode(), response.getBody());
            return "{\"error\": \"Grok AI 送信失敗: " + response.getStatusCode() + " - " + response.getBody() + "\"}"; // エラーメッセージを返す
        }
    } catch (Exception e) {
        logger.error("Grok AI API呼び出し中にエラー発生", e);
        return "{\"error\": \"Grok AI API呼び出し中にエラー発生: " + e.getMessage() + "\"}"; // エラーメッセージを返す
    }
}


}
