package com.bridge.backend.service;

import com.bridge.backend.dto.IndustryDTO;
import com.bridge.backend.entity.Industry;
import com.bridge.backend.repository.IndustryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Industryサービス
 * 業界のビジネスロジックを担当するサービスです。
 */
@Service
public class IndustryService {

    @Autowired
    private IndustryRepository industryRepository;

    /**
     * 全ての業界を取得
     * 
     * @return IndustryDTOのリスト
     */
    public List<IndustryDTO> getAllIndustries() {
        List<Industry> industries = industryRepository.findAll();
        return industries.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * EntityをDTOに変換
     * 
     * @param industry Industry entity
     * @return IndustryDTO
     */
    private IndustryDTO convertToDTO(Industry industry) {
        return new IndustryDTO(
                industry.getId(),
                industry.getIndustry()
        );
    }
}