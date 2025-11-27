package com.bridge.backend.repository;

import com.bridge.backend.entity.Tag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Tagリポジトリ
 * タグデータへのアクセスを管理するリポジトリです。
 */
@Repository
public interface TagRepository extends JpaRepository<Tag, Integer> {
    
    /**
     * タグ名でタグを検索
     * 
     * @param tag タグ名
     * @return Tag（存在しない場合はnull）
     */
    Tag findByTag(String tag);
}