package com.bridge.backend.controller;

import com.bridge.backend.entity.User;
import com.bridge.backend.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.util.Optional;

import static org.mockito.ArgumentMatchers.anyString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AuthController.class)
@org.springframework.context.annotation.Import(TestSecurityConfig.class)
public class AuthControllerTest {
    @Autowired
    private MockMvc mockMvc;
    @MockBean
    private UserRepository userRepository;
    @MockBean
    private com.bridge.backend.service.AuthService authService;

    private ObjectMapper objectMapper = new ObjectMapper();

    private User testUser;

    @BeforeEach
    void setup() {
        testUser = new User();
        testUser.setId(1);
        testUser.setEmail("test@example.com");
        testUser.setPassword("hashedpassword");
        testUser.setNickname("tester");
        testUser.setType(1);
        testUser.setIsWithdrawn(false);
    }

    @Test
    void サインイン成功() throws Exception {
        Mockito.when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(testUser));
        Mockito.when(authService.signin(anyString(), anyString())).thenReturn(null); // 実際のDTOは不要
        mockMvc.perform(post("/api/auth/signin")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"test@example.com\",\"password\":\"password\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void email型エラー() throws Exception {
        mockMvc.perform(post("/api/auth/signin")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":123,\"password\":\"password\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.email").value("入力されていない項目か不正な入力値があります"));
    }

    @Test
    void 認証失敗_メールかパスワード不一致() throws Exception {
        Mockito.when(authService.signin(anyString(), anyString())).thenThrow(new IllegalArgumentException());
        mockMvc.perform(post("/api/auth/signin")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"wrong@example.com\",\"password\":\"wrong\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errors.auth").value("メールアドレスかパスワードが違います"));
    }

    @Test
    void DBエラー_500() throws Exception {
        Mockito.when(authService.signin(anyString(), anyString())).thenThrow(new RuntimeException());
        mockMvc.perform(post("/api/auth/signin")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"test@example.com\",\"password\":\"password\"}"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.errors.system").value("Internal Server Error"));
    }
}
