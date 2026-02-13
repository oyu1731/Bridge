package com.bridge.backend.controller;

import com.bridge.backend.entity.Industry;
import com.bridge.backend.entity.IndustryRelation;
import com.bridge.backend.repository.IndustryRepository;
import com.bridge.backend.repository.IndustryRelationRepository;

import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.JsonProcessingException;

import java.util.List;

@RestController
@RequestMapping("/api/industries")

public class IndustryController {

    private static final Logger logger = LoggerFactory.getLogger(IndustryController.class);
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final IndustryRepository industryRepository;
    private final IndustryRelationRepository industryRelationRepository;

    public IndustryController(IndustryRepository industryRepository,
                              IndustryRelationRepository industryRelationRepository) {
        this.industryRepository = industryRepository;
        this.industryRelationRepository = industryRelationRepository;
    }

    // ====== 全業界一覧取得API ======
    @GetMapping(produces = "application/json;charset=UTF-8")
    public List<Industry> getAllIndustries() {
        List<Industry> industries = industryRepository.findAll();

        // ログ出力（取得確認）
        try {
            logger.info("取得したIndustryデータ(JSON): {}", objectMapper.writeValueAsString(industries));
        } catch (JsonProcessingException e) {
            logger.error("IndustryデータのJSON変換中にエラーが発生しました", e);
        }

        for (Industry industry : industries) {
            logger.info("Industry ID={} | Value={} | Type={}",
                    industry.getId(),
                    industry.getIndustry(),
                    (industry.getIndustry() != null ? industry.getIndustry().getClass().getName() : "null"));
        }

        return industries;
    }

    // ====== ユーザー別業界取得API ======
    @GetMapping("/user/{userId}")
    public List<Industry> getIndustriesByUser(@PathVariable Integer userId) {
        List<IndustryRelation> relations = industryRelationRepository.findByUserId(userId);

        return relations.stream()
                .map(IndustryRelation::getIndustry)
                .toList();
    }

}