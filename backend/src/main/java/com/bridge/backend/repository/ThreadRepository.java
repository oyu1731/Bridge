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

    @Modifying(clearAutomatically = true)
    @Query("UPDATE ForumThread t SET t.isDeleted = true WHERE t.id = :id")
    void softDelete(Integer id);

    @Query(value = """
        SELECT
            t.id,
            t.user_id,
            t.title,
            t.type,
            t.description,
            t.entry_criteria,
            t.last_update_date,
            MAX(n.created_at) AS lastReportedAt
        FROM threads t
        INNER JOIN notices n
            ON n.thread_id = t.id
        WHERE t.is_deleted = FALSE
        GROUP BY
            t.id,
            t.user_id,
            t.title,
            t.type,
            t.description,
            t.entry_criteria,
            t.last_update_date
        ORDER BY lastReportedAt DESC
        """, nativeQuery = true)
    List<Object[]> findThreadsOrderByLastReportedAt();
}