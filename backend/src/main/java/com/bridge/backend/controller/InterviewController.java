package com.bridge.backend.controller;

import com.bridge.backend.dto.AnswerDTO; // AnswerDTOをインポート
import com.bridge.backend.dto.InterviewDTO;
import com.bridge.backend.dto.InterviewRequestDTO;
import com.bridge.backend.entity.Interview;
import com.bridge.backend.service.InterviewService;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.JsonProcessingException;

import java.util.List;

/**
 * 🎤 InterviewController
 * 
 * このクラスは「面接質問(interview)」に関するAPIエンドポイントをまとめたコントローラーです。
 * Spring MVCの @RestController を使っており、JSON形式でリクエストとレスポンスを処理します。
 */
@RestController
@RequestMapping("/api/interview") // このコントローラーのURLプレフィックス
public class InterviewController {

    // ログ出力用のロガー（ログを出して動作確認・デバッグに利用）
    private static final Logger logger = LoggerFactory.getLogger(InterviewController.class);

    // JSON文字列変換用のヘルパー（ログ出力のために使用）
    private final ObjectMapper objectMapper = new ObjectMapper();

    // 面接質問関連のビジネスロジックを担当するサービスクラス
    private final InterviewService interviewService;

    // コンストラクタでサービスを注入（Springが自動的にDI）
    public InterviewController(InterviewService interviewService) {
        this.interviewService = interviewService;
    }

    /**
     * POSTリクエストで新しい面接質問リストを作成・取得するエンドポイント。
     * 
     * 例:
     * curl -X POST http://localhost:8080/api/interview \
     *      -H "Content-Type: application/json" \
     *      -d '{"questionType":"normal","questionCount":5}'
     *
     * @param interviewDTO - リクエストボディに含まれる質問タイプ・数などの情報
     * @return 指定条件に応じたInterviewのリストをJSONで返す
     */
    @PostMapping(produces = "application/json;charset=UTF-8")
    public List<Interview> createInterviewQuestions(@RequestBody InterviewDTO interviewDTO) {
        logger.info("Received InterviewDTO: {}", interviewDTO);
        logger.info("QuestionType from DTO: {}", interviewDTO.getQuestionType());
        logger.info("QuestionCount from DTO: {}", interviewDTO.getQuestionCount());

        // Service層に処理を委譲して、質問リストを作成・取得
        return interviewService.createInterviewQuestions(interviewDTO);
    }

    /**
     * Flutterから送られてきたJSON（例：{"questionType":"normal","questionCount":5}）を受け取り、
     * そのタイプの質問をデータベースからランダムに指定件数抽出して返すエンドポイント。
     *
     * 例:
     * curl -X POST http://localhost:8080/api/interview/random \
     *      -H "Content-Type: application/json" \
     *      -d '{"questionType":"normal","questionCount":5}'
     *
     * @param requestDTO - リクエストボディに含まれる質問タイプ・数などの情報
     * @return 指定条件に応じたInterviewのリストをJSONで返す
     */
    @PostMapping(value = "/random", produces = "application/json;charset=UTF-8")
    public List<Interview> getRandomInterviewQuestions(@RequestBody InterviewRequestDTO requestDTO) {
        logger.info("Received InterviewRequestDTO for random questions: {}", requestDTO);
        return interviewService.getRandomInterviewQuestions(requestDTO);
    }

    /**
     * GETリクエストで面接質問を取得するエンドポイント。
     * 
     * 使い方例:
     * - 全質問取得: GET http://localhost:8080/api/interview
     * - 特定タイプから5件取得: GET http://localhost:8080/api/interview?type=1&count=5
     *
     * @param type  (オプション) 質問タイプ (1=一般, 2=カジュアル, 3=圧迫)
     * @param count (オプション) 取得する質問数
     * @return InterviewのリストをJSONで返す
     */
    @GetMapping(produces = "application/json;charset=UTF-8")
    public List<Interview> getInterviewQuestions(@RequestParam(required = false) Integer type,
                                                 @RequestParam(required = false) Integer count) {
        List<Interview> interviews;

        // パラメータ指定がある場合はタイプと件数で絞り込み
        if (type != null && count != null) {
            interviews = interviewService.getQuestionsByType(type, count);
        } else {
            // パラメータがなければ全件取得
            interviews = interviewService.getAllInterviews();
        }

        // 取得データをJSON文字列としてログに出力（確認用）
        try {
            logger.info("取得したInterviewデータ(JSON): {}", objectMapper.writeValueAsString(interviews));
        } catch (JsonProcessingException e) {
            logger.error("InterviewデータのJSON変換中にエラーが発生しました", e);
        }

        // 各質問の詳細をループで出力（デバッグ用途）
        for (Interview interview : interviews) {
            logger.info("Interview ID={} | Question={} | Type={}",
                    interview.getId(),
                    interview.getQuestion(),
                    interview.getType());
        }

        return interviews;
    }
    @PostMapping(value = "/answers", produces = "application/json;charset=UTF-8")
    public String submitInterviewAnswers(
            @RequestBody List<AnswerDTO> answers,
            @RequestParam("questionType") String questionType // questionType を追加
    ) {
        logger.info("Received answers: {}", answers);
        logger.info("Received questionType: {}", questionType);
        // Service 層に処理を委譲し、評価結果を受け取る
        String evaluationResult = interviewService.saveAnswers(answers, questionType); // questionType を渡す
        return evaluationResult; // 評価結果をそのまま返す
   }
}


