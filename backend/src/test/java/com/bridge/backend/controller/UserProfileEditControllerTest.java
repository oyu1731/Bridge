package com.bridge.backend.controller;

import com.bridge.backend.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
@org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc(addFilters = false)
class UserProfileEditControllerTest {
    @Autowired
    private MockMvc mockMvc;
    @MockBean
    private UserService userService;
        @MockBean
        private com.bridge.backend.repository.IndustryRepository industryRepository;
    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    @DisplayName("idが数値型でない場合、型エラー")
    void idNotInteger() throws Exception {
        Map<String, Object> req = Map.of(
                "nickname", "test",
                "email", "test@example.com",
                "phone_number", "09012345678",
                "industry_ids", List.of(1,2),
                "image_path", "img.png"
        );
        mockMvc.perform(put("/api/users/abc/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input.nickname").value("test"))
                .andExpect(jsonPath("$.errors.message").value("入力されていない項目か不正な入力値があります"));
    }

    @Test
    @DisplayName("nicknameが文字列型でない場合、型エラー")
    void nicknameNotString() throws Exception {
        Map<String, Object> req = Map.of(
                "nickname", 123,
                "email", "test@example.com",
                "phone_number", "09012345678",
                "industry_ids", List.of(1,2),
                "image_path", "img.png"
        );
        mockMvc.perform(put("/api/users/1/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input.nickname").value(123))
                .andExpect(jsonPath("$.errors.message").value("入力されていない項目か不正な入力値があります"));
    }

    @Test
    @DisplayName("emailが文字列型でない場合、型エラー")
    void emailNotString() throws Exception {
        Map<String, Object> req = Map.of(
                "nickname", "test",
                "email", 123,
                "phone_number", "09012345678",
                "industry_ids", List.of(1,2),
                "image_path", "img.png"
        );
        mockMvc.perform(put("/api/users/1/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input.email").value(123))
                .andExpect(jsonPath("$.errors.message").value("入力されていない項目か不正な入力値があります"));
    }

    @Test
    @DisplayName("phone_numberが文字列型でない場合、型エラー")
    void phoneNumberNotString() throws Exception {
        Map<String, Object> req = Map.of(
                "nickname", "test",
                "email", "test@example.com",
                "phone_number", 123,
                "industry_ids", List.of(1,2),
                "image_path", "img.png"
        );
        mockMvc.perform(put("/api/users/1/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input.phone_number").value(123))
                .andExpect(jsonPath("$.errors.message").value("入力されていない項目か不正な入力値があります"));
    }

    @Test
    @DisplayName("industry_idsが数値型配列でない場合、型エラー")
    void industryIdsNotIntArray() throws Exception {
        Map<String, Object> req = Map.of(
                "nickname", "test",
                "email", "test@example.com",
                "phone_number", "09012345678",
                "industry_ids", List.of("a", 2),
                "image_path", "img.png"
        );
        mockMvc.perform(put("/api/users/1/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input.industry_ids[0]").value("a"))
                .andExpect(jsonPath("$.errors.message").value("入力されていない項目か不正な入力値があります"));
    }

    @Test
    @DisplayName("image_pathが文字列型でない場合、型エラー")
    void imagePathNotString() throws Exception {
        Map<String, Object> req = Map.of(
                "nickname", "test",
                "email", "test@example.com",
                "phone_number", "09012345678",
                "industry_ids", List.of(1,2),
                "image_path", 123
        );
        mockMvc.perform(put("/api/users/1/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input.image_path").value(123))
                .andExpect(jsonPath("$.errors.message").value("入力されていない項目か不正な入力値があります"));
    }

    @Test
    @DisplayName("email重複時のエラー")
    void emailDuplicate() throws Exception {
        Map<String, Object> req = Map.of(
                "nickname", "test",
                "email", "dup@example.com",
                "phone_number", "09012345678",
                "industry_ids", List.of(1,2),
                "image_path", "img.png"
        );
        Mockito.when(userService.existsByEmail("dup@example.com", 1)).thenReturn(true);
        mockMvc.perform(put("/api/users/1/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input.email").value("dup@example.com"))
                .andExpect(jsonPath("$.errors.message").value("すでに登録されているアカウントがあるのでこの情報は使えません"));
    }

    @Test
    @DisplayName("phone_number重複時のエラー")
    void phoneNumberDuplicate() throws Exception {
        Map<String, Object> req = Map.of(
                "nickname", "test",
                "email", "test@example.com",
                "phone_number", "09099999999",
                "industry_ids", List.of(1,2),
                "image_path", "img.png"
        );
        Mockito.when(userService.existsByPhoneNumber("09099999999", 1)).thenReturn(true);
        mockMvc.perform(put("/api/users/1/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input.phone_number").value("09099999999"))
                .andExpect(jsonPath("$.errors.message").value("すでに登録されているアカウントがあるのでこの情報は使えません"));
    }

    @Test
    @DisplayName("idに該当ユーザーがいない場合")
    void userNotFound() throws Exception {
        Map<String, Object> req = Map.of(
                "nickname", "test",
                "email", "test@example.com",
                "phone_number", "09012345678",
                "industry_ids", List.of(1,2),
                "image_path", "img.png"
        );
        Mockito.doThrow(new RuntimeException("User not found"))
                .when(userService)
                .updateUserProfile(Mockito.eq(99), Mockito.any(com.bridge.backend.dto.UserDto.class), Mockito.eq(req));
        mockMvc.perform(put("/api/users/99/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input.nickname").value("test"))
                .andExpect(jsonPath("$.errors.message").value("ユーザーの登録情報がありません"));
    }

    @Test
    @DisplayName("DBエラー時は500")
    void dbError() throws Exception {
        Map<String, Object> req = Map.of(
                "nickname", "test",
                "email", "test@example.com",
                "phone_number", "09012345678",
                "industry_ids", List.of(1,2),
                "image_path", "img.png"
        );
        Mockito.doThrow(new RuntimeException("DB error"))
                .when(userService)
                .updateUserProfile(Mockito.eq(1), Mockito.any(com.bridge.backend.dto.UserDto.class), Mockito.eq(req));
        mockMvc.perform(put("/api/users/1/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.errors.message").value("Internal Server Error"));
    }

    @Test
    @DisplayName("正常系: プロフィール編集成功")
    void updateProfileSuccess() throws Exception {
        Map<String, Object> req = Map.of(
                "nickname", "test",
                "email", "test@example.com",
                "phone_number", "09012345678",
                "industry_ids", List.of(1,2),
                "image_path", "img.png"
        );
        Mockito.when(
                userService.updateUserProfile(
                        Mockito.eq(1),
                        Mockito.any(com.bridge.backend.dto.UserDto.class),
                        Mockito.eq(req)))
                .thenReturn(new com.bridge.backend.dto.UserDto());
        mockMvc.perform(put("/api/users/1/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());
    }
}
