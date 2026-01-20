package com.bridge.backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import com.bridge.backend.entity.ForumThread; // 自作Thread

@Repository
public interface ThreadRepository extends JpaRepository<ForumThread, Integer> {
    // 削除されていないスレッドを取得
    List<ForumThread> findByIsDeletedFalse();

    @Modifying
    @Query("UPDATE ForumThread t SET t.isDeleted = true WHERE t.id = :id")
    void softDelete(Integer id);
}