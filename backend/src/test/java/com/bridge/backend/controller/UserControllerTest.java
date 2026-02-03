package com.bridge.backend.controller;

import com.bridge.backend.dto.UserDto;
import com.bridge.backend.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import com.bridge.backend.config.TestSecurityConfig;
import com.bridge.backend.repository.UserRepository;
import com.bridge.backend.repository.IndustryRepository;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
@Import(TestSecurityConfig.class)
public class UserControllerTest {
        @Test
        void testCompanyPhoneNumberDuplicate() throws Exception {
        UserDto dto = new UserDto();
        dto.setType(3); // 企業ユーザー
        dto.setPhoneNumber("09099999999");
        Mockito.when(userService.existsByPhoneNumber("09099999999")).thenReturn(true);
        mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(dto)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.input.phoneNumber").value("09099999999"))
            .andExpect(jsonPath("$.errors.phone_number").value("すでに登録されている項目があります"));
        }

        @Test
        void testCompanyNameNotString() throws Exception {
        String json = "{" +
            "\"type\":3," +
            "\"companyName\":12345" +
            "}";
        mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(json))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.input.companyName").value(12345))
            .andExpect(jsonPath("$.errors.company_name").value("入力されていない項目か不正な入力値があります"));
        }

        @Test
        void testCompanyNameTooLong() throws Exception {
        UserDto dto = new UserDto();
        dto.setType(3);
        dto.setCompanyName("a".repeat(101));
        mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(dto)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.input.companyName").value("a".repeat(101)))
            .andExpect(jsonPath("$.errors.company_name").value("文字数が長すぎます"));
        }

        @Test
        void testCompanyPasswordNotString() throws Exception {
        String json = "{" +
            "\"type\":3," +
            "\"password\":12345" +
            "}";
        mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(json))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.input.password").value(12345))
            .andExpect(jsonPath("$.errors.password").value("入力されていない項目か不正な入力値があります"));
        }

        @Test
        void testCompanyPasswordTooLong() throws Exception {
        UserDto dto = new UserDto();
        dto.setType(3);
        dto.setPassword("a".repeat(256));
        mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(dto)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.input.password").value("a".repeat(256)))
            .andExpect(jsonPath("$.errors.password").value("文字数が長すぎます"));
        }

        @Test
        void testCompanyEmailNotString() throws Exception {
        String json = "{" +
            "\"type\":3," +
            "\"email\":12345" +
            "}";
        mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(json))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.input.email").value(12345))
            .andExpect(jsonPath("$.errors.email").value("入力されていない項目か不正な入力値があります"));
        }

        @Test
        void testCompanyAddressNotString() throws Exception {
        String json = "{" +
            "\"type\":3," +
            "\"companyAddress\":12345" +
            "}";
        mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(json))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.input.companyAddress").value(12345))
            .andExpect(jsonPath("$.errors.address").value("入力されていない項目か不正な入力値があります"));
        }

        @Test
        void testCompanyDbError() throws Exception {
        UserDto dto = new UserDto();
        dto.setType(3);
        dto.setNickname("test");
        dto.setCompanyName("testcompany");
        dto.setPassword("testpass");
        dto.setPhoneNumber("09099999999");
        dto.setEmail("test@example.com");
        dto.setCompanyAddress("tokyo");
        Mockito.doThrow(new RuntimeException("DB error")).when(userService).createUser(Mockito.any());
        mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(dto)))
            .andExpect(status().isInternalServerError())
            .andExpect(jsonPath("$.errors.system").value("Internal Server Error"));
        }
    @Autowired
    private MockMvc mockMvc;
    @MockBean
    private UserService userService;
    @MockBean
    private IndustryRepository industryRepository;

    private ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void testPhoneNumberDuplicate() throws Exception {
        UserDto dto = new UserDto();
        dto.setPhoneNumber("09012345678");
        Mockito.when(userService.existsByPhoneNumber("09012345678")).thenReturn(true);
        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input.phoneNumber").value("09012345678"))
                .andExpect(jsonPath("$.errors.phone_number").value("すでに登録されている項目があります"));
    }

    // 他のバリデーション異常系・正常系テストはこの後追加
}
