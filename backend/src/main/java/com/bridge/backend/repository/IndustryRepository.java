package com.bridge.backend.repository;
import java.util.Optional;

import com.bridge.backend.entity.Industry;
import com.bridge.backend.entity.IndustryRelation;

import org.springframework.data.jpa.repository.JpaRepository;

public interface IndustryRepository extends JpaRepository<Industry, Integer> {
    Optional<Industry> findByIndustry(String industry);
}
