package com.bridge.backend.repository;

import com.bridge.backend.entity.Notice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
//Notice=使うテーブル、Integer=主キーの型
public interface NoticeRepository extends JpaRepository<Notice, Integer> {
    //重複通報チェックメソッド(通報元ユーザーidとチャットid)
    boolean existsByFromUserIdAndChatId(Integer fromUserId, Integer chatId);
    // ユーザーが通報された回数をカウント
    int countByToUserId(Integer toUserId);

    @Query(value = """
    SELECT 
        n.id,
        n.from_user_id,
        n.to_user_id,
        n.type,
        n.thread_id,
        n.chat_id,
        n.created_at,

        t.title,
        c.content,

        t.is_deleted AS threadDeleted,
        c.is_deleted AS chatDeleted,

        CASE 
            WHEN n.type = 1 THEN COALESCE(
                (SELECT COUNT(*) FROM notices x WHERE x.type = 1 AND x.thread_id = n.thread_id), 0
            )
            ELSE COALESCE(
                (SELECT COUNT(*) FROM notices x WHERE x.type = 2 AND x.chat_id = n.chat_id), 0
            )
        END AS totalCount,

        uf.is_deleted AS fromUserDeleted,
        ut.is_deleted AS toUserDeleted

    FROM notices n
    LEFT JOIN threads t ON n.thread_id = t.id
    LEFT JOIN chats   c ON n.chat_id = c.id

    LEFT JOIN users uf ON n.from_user_id = uf.id
    LEFT JOIN users ut ON n.to_user_id   = ut.id
    ORDER BY n.created_at DESC
    """, nativeQuery = true)
    List<Object[]> findAdminNoticeLogs();
}
