package com.bridge.backend.controller;

import com.bridge.backend.service.PasswordResetService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Map;

import static org.mockito.ArgumentMatchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(PasswordResetController.class)
@org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc(addFilters = false)
class PasswordResetControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private PasswordResetService passwordResetService;

    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    @DisplayName("id(=email)が存在しない場合、null返却＋エラー")
    void reset_userNotFound() throws Exception {
        Mockito.when(passwordResetService.userExistsByEmail(anyString())).thenReturn(false);
        Map<String, Object> req = Map.of("email", "notfound@example.com", "otp", "123456", "newPassword", "pass");
        mockMvc.perform(post("/api/password/reset")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.message").value("ユーザーの登録情報がありません"));
    }

    @Test
    @DisplayName("idが数値型でない場合、型エラー")
    void reset_idNotString() throws Exception {
        Map<String, Object> req = Map.of("email", 123, "otp", "123456", "newPassword", "pass");
        mockMvc.perform(post("/api/password/reset")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.message").value("メールアドレスかパスワードが違います"));
    }

    @Test
    @DisplayName("passwordが文字列型でない場合、型エラー")
    void reset_passwordNotString() throws Exception {
        Map<String, Object> req = Map.of("email", "user@example.com", "otp", "123456", "newPassword", 12345);
        mockMvc.perform(post("/api/password/reset")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.message").value("メールアドレスかパスワードが違います"));
    }

    @Test
    @DisplayName("DB接続不可時は500エラー")
    void reset_dbError() throws Exception {
        Mockito.when(passwordResetService.userExistsByEmail(anyString())).thenThrow(new RuntimeException("DB error"));
        Map<String, Object> req = Map.of("email", "user@example.com", "otp", "123456", "newPassword", "pass");
        mockMvc.perform(post("/api/password/reset")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.errors.message").value("Internal Server Error"));
    }

    @Test
    @DisplayName("正常系: パスワードリセット成功")
    void reset_success() throws Exception {
        Mockito.when(passwordResetService.userExistsByEmail(anyString())).thenReturn(true);
        Mockito.when(passwordResetService.resetPassword(anyString(), anyString(), anyString())).thenReturn(true);
        Map<String, Object> req = Map.of("email", "user@example.com", "otp", "123456", "newPassword", "pass");
        mockMvc.perform(post("/api/password/reset")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("password-updated"));
    }
}
