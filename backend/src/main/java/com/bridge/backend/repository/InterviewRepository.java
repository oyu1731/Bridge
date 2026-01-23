package com.bridge.backend.repository;

import com.bridge.backend.entity.Interview;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface InterviewRepository extends JpaRepository<Interview, Long> {
    List<Interview> findByType(int type);

    @Query(value = "SELECT * FROM interview WHERE type = ?1 ORDER BY RAND() LIMIT ?2", nativeQuery = true)
    List<Interview> findRandomByType(int type, int count);
}
