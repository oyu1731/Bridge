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
}