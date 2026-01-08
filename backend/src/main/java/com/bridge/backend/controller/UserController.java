package com.bridge.backend.controller;

import com.bridge.backend.dto.UserListDto;
import com.bridge.backend.dto.UserCommentHistoryDto;
import com.bridge.backend.dto.UserDetailDto;
import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.User;
import com.bridge.backend.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserService userService;

    @GetMapping(value = "/list", produces = "application/json; charset=UTF-8")
    public ResponseEntity<List<UserListDto>> getUsers() {
        try {
            List<UserListDto> users = userService.getUsers();
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping(value = "/search", produces = "application/json; charset=UTF-8")
    public ResponseEntity<List<UserListDto>> searchUsers(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer type
    ) {
        return ResponseEntity.ok(userService.searchUsers(keyword, type));
    }

    @GetMapping(value = "/{id}", produces = "application/json; charset=UTF-8")
    public ResponseEntity<UserDetailDto> getUserById(@PathVariable Integer id) {
        try {
            UserDetailDto dto = userService.getUserDetail(id);
            return ResponseEntity.ok(dto);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/{id}/comments")
    public List<UserCommentHistoryDto> getUserCommentHistory(@PathVariable Integer id) {
        return userService.getUserCommentHistory(id);
    }

    @PostMapping(produces = "application/json; charset=UTF-8")
    public User createUser(@RequestBody UserDto userDto) {
        return userService.createUser(userDto);
    }

    @PutMapping("/{id}/delete")
    public ResponseEntity<Void> deleteUser(@PathVariable Integer id) {
        userService.deleteUser(id);
        return ResponseEntity.ok().build();
    }
}
