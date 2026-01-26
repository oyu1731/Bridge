package com.bridge.backend.controller;

import com.bridge.backend.dto.PhonePracticeContinueRequestDTO;
import com.bridge.backend.dto.PhonePracticeRequestDTO;
import com.bridge.backend.dto.PhonePracticeResponseDTO;
import com.bridge.backend.service.PhonePracticeService;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.util.UriUtils;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import com.bridge.backend.dto.PhonePracticeEvaluationDTO;

@RestController
@RequestMapping("/api/phone")
public class PhonePracticeController {

    private final PhonePracticeService phonePracticeService;

    public PhonePracticeController(PhonePracticeService phonePracticeService) {
        this.phonePracticeService = phonePracticeService;
    }

    @PostMapping("/practice")
    public PhonePracticeResponseDTO startPhonePractice(@RequestBody PhonePracticeRequestDTO requestDTO) {

        System.out.println("=== /api/phone/practice 受信 ===");
        System.out.println(requestDTO);  // DTOの内容をログ出力
        System.out.println("=================================");

        // DTO をそのままサービスに渡す
        return phonePracticeService.startPractice(requestDTO);
    }

    @PostMapping("/continue")
    public PhonePracticeResponseDTO continuePhonePractice(@RequestBody PhonePracticeContinueRequestDTO requestDTO) {
        System.out.println("=== /api/phone/continue 受信 ===");
        System.out.println("SessionId: " + requestDTO.getSessionId() + ", Message: " + requestDTO.getMessage());
        System.out.println("=================================");
        return phonePracticeService.continuePractice(requestDTO);
    }

    @PostMapping("/end")
    public ResponseEntity<String> endPhonePractice(@RequestBody Map<String, String> payload) {
        String sessionId = payload.get("sessionId");
        if (sessionId == null || sessionId.isEmpty()) {
            return ResponseEntity.badRequest().body("Session ID is required.");
        }
        PhonePracticeResponseDTO response = phonePracticeService.endPracticeAndEvaluate(sessionId);
        if (response.getIsConversationEnd() && response.getEvaluation() != null) {
            return ResponseEntity.ok("Session ended, conversation cleared, and evaluation saved for " + sessionId);
        } else {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to end session or save evaluation for " + sessionId);
        }
    }

    @GetMapping("/evaluation/{sessionId}")
    public ResponseEntity<PhonePracticeEvaluationDTO> getPhonePracticeEvaluation(@PathVariable String sessionId) {
        String decodedSessionId = UriUtils.decode(sessionId, StandardCharsets.UTF_8);
        System.out.println("=== /api/phone/evaluation/ 受信 ===");
        System.out.println("評価リクエストのエンコード済みセッションID: " + sessionId);
        System.out.println("評価リクエストのデコード済みセッションID: " + decodedSessionId);
        System.out.println("=================================");

        PhonePracticeEvaluationDTO evaluation = phonePracticeService.getEvaluation(decodedSessionId);
        System.out.println("評価結果の取得状況 - sessionId: " + decodedSessionId);
        System.out.println("評価結果オブジェクト: " + evaluation);
        if (evaluation != null) {
            System.out.println("評価結果の合計スコア: " + evaluation.getTotalScore());
        }

        if (evaluation != null && evaluation.getTotalScore() != 0) {
            System.out.println("評価結果が存在し、合計スコアが0ではないためOKを返します。");
            return ResponseEntity.ok(evaluation);
        } else {
            System.out.println("評価結果が存在しないか、合計スコアが0のためNotFoundを返します。");
            return ResponseEntity.notFound().build();
        }
    }
}
