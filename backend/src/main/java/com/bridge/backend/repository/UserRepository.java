package com.bridge.backend.repository;

import com.bridge.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

// User エンティティを操作するための Repository
public interface UserRepository extends JpaRepository<User, Integer> {
}
