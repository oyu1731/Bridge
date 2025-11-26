package com.bridge.backend.controller;

// import com.bridge.backend.dto.CompanyDTO;
// import com.bridge.backend.service.CompanyService;
// import com.bridge.backend.dto.CompanyRegistrationDto;
// import com.bridge.backend.service.CompanyAccountService;
import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.User;
import com.bridge.backend.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserService userService;

    @PostMapping
    public User createUser(@RequestBody UserDto userDto) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            System.out.println("受け取ったJSON: " + mapper.writeValueAsString(userDto));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return userService.createUser(userDto);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUserById(@PathVariable("id") Long id) {
        try {
            UserDto userDto = userService.getUserById(id);
            if (userDto != null) {
                return new ResponseEntity<>(userDto, HttpStatus.OK);
            } else {
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PutMapping("/{id}/profile")
    public ResponseEntity<UserDto> updateProfile(
            @PathVariable Integer id,
            @RequestBody UserDto userDto) {
        UserDto updatedUser = userService.updateUserProfile(id, userDto);
        return ResponseEntity.ok(updatedUser);
    }

    @PutMapping("/{id}/industries")
    public ResponseEntity<?> updateUserIndustries(
            @PathVariable Integer id,
            @RequestBody java.util.List<Integer> industryIds) {
        
        userService.updateUserIndustries(id, industryIds);
        return ResponseEntity.ok("Industries updated successfully");
    }

    @PutMapping("/{id}/password")
    public ResponseEntity<?> updatePassword(
            @PathVariable Integer id,
            @RequestBody Map<String, String> passwordMap) {
        try {
            String currentPassword = passwordMap.get("currentPassword");
            String newPassword = passwordMap.get("newPassword");
            userService.updatePassword(id, currentPassword, newPassword);
            return ResponseEntity.ok("Password updated successfully");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }
}