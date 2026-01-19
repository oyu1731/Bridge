package com.bridge.backend.repository;

import com.bridge.backend.entity.Chat;       // ← Chat エンティティ
import org.springframework.data.jpa.repository.JpaRepository; // ← JpaRepository
import org.springframework.stereotype.Repository;
import java.util.List;

public interface ChatRepository extends JpaRepository<Chat, Integer> {
    List<Chat> findByThreadIdOrderByCreatedAtAsc(Integer threadId);
    List<Chat> findByThreadIdAndIsDeletedFalseOrderByCreatedAtAsc(Integer threadId);
}