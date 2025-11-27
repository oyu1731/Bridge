package com.bridge.backend.repository;

import com.bridge.backend.entity.Notice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

// import java.util.List;

@Repository
public interface NoticeRepository extends JpaRepository<Notice, Integer>  {

    /**
     * 削除されていない通報を全取得
    List<Notice> findByIsDeletedFalse();
    */
}
