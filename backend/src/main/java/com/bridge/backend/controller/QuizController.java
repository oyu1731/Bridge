package com.bridge.backend.controller;

import com.bridge.backend.service.QuizService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.bridge.backend.entity.QuizScore;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/quiz")
@RequiredArgsConstructor
public class QuizController {

    private final QuizService quizService;

    @PostMapping("/correct")
    public ResponseEntity<?> correctQuiz(@RequestBody Map<String, Object> body) {
        try {
            int userId = (int) body.get("userId");
            int scoreToAdd = (int) body.getOrDefault("scoreToAdd", 1); // デフォルト値を1とする

            quizService.addScore(userId, scoreToAdd);

            return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "スコア+" + scoreToAdd + "しました",
                "userId", userId
            ));

        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of(
                "status", "error",
                "message", e.getMessage()
            ));
        }
    }

    @GetMapping("/ranking")
    public ResponseEntity<List<QuizScore>> getRanking() {
        List<QuizScore> ranking = quizService.getRanking();
        return ResponseEntity.ok(ranking);
    }
}
