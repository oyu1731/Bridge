package com.bridge.backend.controller;

import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.User;
import com.bridge.backend.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserService userService;

    @PostMapping
    public User createUser(@RequestBody UserDto userDto) {
        return userService.createUser(userDto);
    }
 
    /**
     * IDに基づいてユーザー情報を取得するエンドポイント
     * 例: GET /api/users/1
     * @param id ユーザーID
     * @return Userオブジェクト (存在しない場合は404 Not Found)
     */
    @GetMapping("/{id}")
    public User getUserById(@PathVariable Integer id) {
        return userService.getUserById(id);
    }

    /**
     * ユーザーのトークン数を減らすエンドポイント
     * 例: PUT /api/users/{id}/deduct-tokens
     * @param id ユーザーID
     * @param tokensToDeduct 減らすトークン数
     * @return 更新後のUserオブジェクト
     */
    @PutMapping("/{id}/deduct-tokens")
    public User deductTokens(@PathVariable Integer id, @RequestParam int tokensToDeduct) {
        return userService.deductUserTokens(id, tokensToDeduct);
    }
}
