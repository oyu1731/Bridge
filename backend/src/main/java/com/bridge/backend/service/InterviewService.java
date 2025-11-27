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
    public void saveAnswers(List<AnswerDTO> answers, String interviewType) {
    logger.info("受け取った解答: {}", answers);

    if (answers.isEmpty()) {
        logger.warn("回答リストが空です");
        return;
    }

    Map<String, String> companyInfo = new HashMap<>(answers.get(0).getCompanyInfo());

    Map<String, Object> payload = new HashMap<>();
    payload.put("model", "gpt-4.1-mini"); // 使用モデル

    // 強化されたシステムプロンプト
    String systemPrompt = """
    あなたは面接官歴10年以上のAIです。学生の面接回答を以下の観点で詳細に分析してください：
    【評価項目】
    1. 論理性 (Logic): 回答の構造、根拠、前提の妥当性
    2. 具体性 (Specificity): 具体例や実績の有無
    3. 企業適合性 (Company Fit): 会社の業界、規模、雰囲気への適合
    4. 表現力 (Expression): 言語の明瞭さ、簡潔さ、説得力
    5. 面接対応力 (Interview Response): 面接形式（normal, casual, pressure）への対応
    【企業情報に基づく重点ポイント】
    - 業界: 商社 → 交渉力、調整力、国際感覚
    - 業種・規模: 中小企業 → 実践力、柔軟性、責任感
    - 雰囲気: 堅実 → 信頼性、計画性、誠実さ
    【面接タイプ別評価】
    - normal: 基本スキルとバランス
    - casual: 親近感、社風への適合性、柔軟性
    - pressure: ストレス耐性、論理的思考、冷静さ
    【出力形式】
    JSON形式で出力：
    {
      "evaluations": [
        {
          "question": "質問文",
          "answer": "学生の回答",
          "scores": {
            "logic": 1-5,
            "specificity": 1-5,
            "company_fit": 1-5,
            "expression": 1-5,
            "interview_response": 1-5
          },
          "detailed_feedback": {
            "strengths": ["強み1", "強み2"],
            "weaknesses": ["弱み1", "弱み2"],
            "improvement_advice": "具体的改善アドバイス"
          }
        }
      ],
      "overall_assessment": {
        "total_score": "XX/25",
        "summary": "総合評価の要約",
        "key_strengths": ["強み1", "強み2"],
        "development_areas": ["改善すべき点1", "改善すべき点2"],
        "next_interview_tips": ["次回の面接での具体的アドバイス1", "アドバイス2"]
      }
    }
    学生が次回の面接で活かせる実践的かつ具体的なフィードバックを作成してください。
    """;

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

    String grokApiUrl = "https://console.groq.com/docs/"; // 仮URL
    String apiKey = "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";

    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    headers.set("Authorization", "Bearer " + apiKey);

    HttpEntity<Map<String, Object>> request = new HttpEntity<>(payload, headers);

    RestTemplate restTemplate = new RestTemplate();
    try {
        ResponseEntity<String> response = restTemplate.postForEntity(grokApiUrl, request, String.class);
        if (response.getStatusCode().is2xxSuccessful()) {
            logger.info("Grok AI 評価結果: {}", response.getBody());
        } else {
            logger.error("Grok AI 送信失敗: {} - {}", response.getStatusCode(), response.getBody());
        }
    } catch (Exception e) {
        logger.error("Grok AI API呼び出し中にエラー発生", e);
    }
}


}
