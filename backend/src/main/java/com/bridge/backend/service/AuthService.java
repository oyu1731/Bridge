package com.bridge.backend.service;

import com.bridge.backend.dto.UserDto;
import com.bridge.backend.entity.User;
import com.bridge.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    // 既存の場所と同じエンコーダを使う
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    /**
     * サインイン: email/password を検証してユーザー情報を返す（トークンは未実装）
     */
    public UserDto signin(String email, String password) {
        Optional<User> opt = userRepository.findByEmail(email);
        if (opt.isEmpty()) {
            throw new IllegalArgumentException("メールアドレスが登録されていません。サインアップからアカウントを作成してください。");
        }
        User user = opt.get();

        if (Boolean.TRUE.equals(user.getIsWithdrawn())) {
            throw new IllegalArgumentException("このアカウントは退会済みです。");
        }

        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません");
        }

    // サインアップと同じ DTO を返す
        UserDto userDto = new UserDto();
        userDto.setId(user.getId());
        userDto.setNickname(user.getNickname());
        userDto.setEmail(user.getEmail());
        user.setPassword(userDto.getPassword()); 
        userDto.setPhoneNumber(user.getPhoneNumber());
        userDto.setSocietyHistory(user.getSocietyHistory());
        userDto.setType(user.getType() == null ? 0 : user.getType());

        return userDto;
    }
}
