package com.bridge.backend.repository;

import com.bridge.backend.entity.TempCompanySignup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TempCompanySignupRepository extends JpaRepository<TempCompanySignup, Integer> {
}
