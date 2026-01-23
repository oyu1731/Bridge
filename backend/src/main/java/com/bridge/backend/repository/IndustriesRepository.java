package com.bridge.backend.repository;

import com.bridge.backend.entity.Industry;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IndustriesRepository extends JpaRepository<Industry, Integer> {
}
