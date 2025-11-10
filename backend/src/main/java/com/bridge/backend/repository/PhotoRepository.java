package com.bridge.backend.repository;

import com.bridge.backend.entity.Photo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Photoリポジトリ
 * 写真データへのアクセスを管理するリポジトリです。
 */
@Repository
public interface PhotoRepository extends JpaRepository<Photo, Integer> {
    
    /**
     * IDで写真を取得
     * 
     * @param id 写真ID
     * @return Photo（存在しない場合はnull）
     */
    Photo findByIdAndUserIdIsNotNull(Integer id);
}