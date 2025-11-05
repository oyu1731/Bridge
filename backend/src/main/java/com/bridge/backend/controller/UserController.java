package com.bridge.backend.controller;

import com.bridge.backend.entity.User;
import com.bridge.backend.repository.UserRepository;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.JsonProcessingException;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    private static final Logger logger = LoggerFactory.getLogger(UserController.class);
    private final ObjectMapper objectMapper = new ObjectMapper();

    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping(produces = "application/json;charset=UTF-8")
    public List<User> getAllUsers() {
        List<User> users = userRepository.findAll();
        try {
            logger.info("取得したUserデータ: {}", objectMapper.writeValueAsString(users));
        } catch (JsonProcessingException e) {
            logger.error("UserデータのJSON変換中にエラーが発生しました", e);
        }
        // テストデータを追加 (Userエンティティのコンストラクタ変更に伴いコメントアウト)
        // users.add(new User(999, "テストユーザー１"));
        // users.add(new User(1000, "テストユーザー２"));
        return users;
    }

    @PostMapping(consumes = "application/json;charset=UTF-8", produces = "application/json;charset=UTF-8")
    public User createUser(@RequestBody User user) {
        try {
            logger.info("受信したUserデータ: {}", objectMapper.writeValueAsString(user));
        } catch (JsonProcessingException e) {
            logger.error("UserデータのJSON変換中にエラーが発生しました", e);
        }
        return userRepository.save(user);
    }
}