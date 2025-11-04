package com.bridge.backend.controller;

import com.bridge.backend.entity.Industry;
import com.bridge.backend.repository.IndustryRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/industries")
@CrossOrigin(origins = "*")
public class IndustryController {

    private final IndustryRepository industryRepository;

    public IndustryController(IndustryRepository industryRepository) {
        this.industryRepository = industryRepository;
    }

    @GetMapping(produces = "application/json;charset=UTF-8")
    public List<Industry> getAllIndustries() {
        return industryRepository.findAll();
    }
}