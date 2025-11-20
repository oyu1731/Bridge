package com.bridge.backend.service;

import com.bridge.backend.dto.TagDTO;
import com.bridge.backend.entity.Tag;
import com.bridge.backend.repository.TagRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Tagサービス
 * タグのビジネスロジックを担当するサービスです。
 */
@Service
public class TagService {

    @Autowired
    private TagRepository tagRepository;

    /**
     * 全てのタグを取得
     * 
     * @return TagDTOのリスト
     */
    public List<TagDTO> getAllTags() {
        List<Tag> tags = tagRepository.findAll();
        return tags.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * EntityをDTOに変換
     * 
     * @param tag Tag entity
     * @return TagDTO
     */
    private TagDTO convertToDTO(Tag tag) {
        return new TagDTO(
                tag.getId(),
                tag.getTag()
        );
    }
}