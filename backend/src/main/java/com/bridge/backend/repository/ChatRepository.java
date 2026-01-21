package com.bridge.backend.repository;

import com.bridge.backend.entity.Chat;       // ← Chat エンティティ
import org.springframework.data.jpa.repository.JpaRepository; // ← JpaRepository
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ChatRepository extends JpaRepository<Chat, Integer> {
    List<Chat> findByThreadIdOrderByCreatedAtAsc(Integer threadId);
    List<Chat> findByUserIdOrderByCreatedAtDesc(Integer userId);
    @Modifying
    @Query("UPDATE Chat c SET c.isDeleted = true WHERE c.id = :id")
    void softDelete(Integer id);
    List<Chat> findByThreadIdAndIsDeletedFalseOrderByCreatedAtAsc(Integer threadId);
}