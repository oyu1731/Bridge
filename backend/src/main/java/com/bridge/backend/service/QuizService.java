package com.bridge.backend.service;

import com.bridge.backend.entity.QuizScore;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.QuizScoreRepository;
import com.bridge.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class QuizService {

    private final QuizScoreRepository quizScoreRepository;
    private final UserRepository userRepository;

    public void addScore(int userId, int scoreToAdd) {
        Optional<User> userOptional = userRepository.findById(userId);
        if (userOptional.isEmpty()) {
            throw new RuntimeException("User not found with ID: " + userId);
        }
        User user = userOptional.get();
        String nickname = user.getNickname();

        Optional<QuizScore> existingQuizScore = quizScoreRepository.findByUserId(userId);

        QuizScore quizScore;
        if (existingQuizScore.isPresent()) {
            quizScore = existingQuizScore.get();
            quizScore.setScore(quizScore.getScore() + scoreToAdd);
            quizScore.setNickname(nickname); // ニックネームも更新されるようにする
        } else {
            quizScore = new QuizScore();
            quizScore.setUserId(userId);
            quizScore.setNickname(nickname);
            quizScore.setScore(scoreToAdd);
        }
        quizScoreRepository.save(quizScore);
    }

    public List<QuizScore> getRanking() {
        return quizScoreRepository.findAllByOrderByScoreDesc();
    }
}