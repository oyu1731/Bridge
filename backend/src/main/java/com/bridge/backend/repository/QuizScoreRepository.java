package com.bridge.backend.repository;

import com.bridge.backend.entity.QuizScore;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

import java.util.Optional;

@Repository
public interface QuizScoreRepository extends JpaRepository<QuizScore, Integer> {
    Optional<QuizScore> findByUserId(Integer userId);
    List<QuizScore> findAllByOrderByScoreDesc(); // スコア降順で全件取得するメソッドを追加
}