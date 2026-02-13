package com.bridge.backend.controller;

import com.bridge.backend.dto.IndustryDTO;
import com.bridge.backend.dto.TagDTO;
import com.bridge.backend.service.IndustryService;
import com.bridge.backend.service.TagService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * FilterController
 * フィルタ用のAPI（業界・タグ）を提供するコントローラーです。
 */
@RestController
@RequestMapping("/api/filters")
public class FilterController {

    @Autowired
    private IndustryService industryService;

    @Autowired
    private TagService tagService;

    /**
     * 全業界を取得
     * GET /api/filters/industries
     * 
     * @return 業界一覧
     */
    @GetMapping("/industries")
    public ResponseEntity<List<IndustryDTO>> getAllIndustries() {
        try {
            List<IndustryDTO> industries = industryService.getAllIndustries();
            return ResponseEntity.ok(industries);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * 全タグを取得
     * GET /api/filters/tags
     * 
     * @return タグ一覧
     */
    @GetMapping("/tags")
    public ResponseEntity<List<TagDTO>> getAllTags() {
        try {
            List<TagDTO> tags = tagService.getAllTags();
            return ResponseEntity.ok(tags);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}