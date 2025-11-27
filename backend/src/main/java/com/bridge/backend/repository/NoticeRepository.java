package com.bridge.backend.repository;

import com.bridge.backend.entity.Notice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
//Notice=使うテーブル、Integer=主キーの型
public interface NoticeRepository extends JpaRepository<Notice, Integer> {
    //重複通報チェックメソッド(通報元ユーザーidとチャットid)
    boolean existsByFromUserIdAndChatId(Integer fromUserId, Integer chatId);
}