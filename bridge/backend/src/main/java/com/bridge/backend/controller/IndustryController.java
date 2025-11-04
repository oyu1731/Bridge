package com.bridge.backend.controller;

import com.bridge.backend.entity.Industry;
import com.bridge.backend.repository.IndustryRepository;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.JsonProcessingException;

import java.util.List;

@RestController
@RequestMapping("/api/industries")
@CrossOrigin(origins = "*")
public class IndustryController {

    private static final Logger logger = LoggerFactory.getLogger(IndustryController.class);
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final IndustryRepository industryRepository;

    public IndustryController(IndustryRepository industryRepository) {
        this.industryRepository = industryRepository;
    }

    @GetMapping(produces = "application/json;charset=UTF-8")
    public List<Industry> getAllIndustries() {
        // MySQLからデータをそのまま取得
        List<Industry> industries = industryRepository.findAll();

        // ログ出力（取得確認）
        try {
            logger.info("取得したIndustryデータ(JSON): {}", objectMapper.writeValueAsString(industries));
        } catch (JsonProcessingException e) {
            logger.error("IndustryデータのJSON変換中にエラーが発生しました", e);
        }

        // Flutter側でデコード確認ができるよう、データ型を明示して出力
        for (Industry industry : industries) {
            logger.info("Industry ID={} | Value={} | Type={}",
                    industry.getId(),
                    industry.getIndustry(),
                    (industry.getIndustry() != null ? industry.getIndustry().getClass().getName() : "null"));
        }

        return industries;
    }
}
