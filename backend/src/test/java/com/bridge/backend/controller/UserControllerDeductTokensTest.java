package com.bridge.backend.controller;

import com.bridge.backend.entity.User;
import com.bridge.backend.service.UserService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
@org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc(addFilters = false)
class UserControllerDeductTokensTest {
    @Autowired
    private MockMvc mockMvc;
    @MockBean
    private UserService userService;
    @MockBean
    private com.bridge.backend.repository.IndustryRepository industryRepository;

    @Test
    @DisplayName("idが数値型でない場合、400+エラー返却")
    void deductTokens_idNotInteger() throws Exception {
        mockMvc.perform(put("/api/users/abc/deduct-tokens?tokensToDeduct=10")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input").value("abc"))
                .andExpect(jsonPath("$.errors.message").value("入力されていない項目か不正な入力値があります"));
    }

    @Test
    @DisplayName("idと一致するレコードがない場合、200+null+エラー返却")
    void deductTokens_userNotFound() throws Exception {
        Mockito.when(userService.deductUserTokens(99, 10)).thenThrow(new RuntimeException("User not found"));
        mockMvc.perform(put("/api/users/99/deduct-tokens?tokensToDeduct=10")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").value((Object) null))
                .andExpect(jsonPath("$.errors.message").value("ユーザーの登録情報がありません"));
    }

    @Test
    @DisplayName("DBエラー時は500+エラー返却")
    void deductTokens_dbError() throws Exception {
        Mockito.when(userService.deductUserTokens(1, 10)).thenThrow(new RuntimeException("DB error"));
        mockMvc.perform(put("/api/users/1/deduct-tokens?tokensToDeduct=10")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.errors.message").value("Internal Server Error"));
    }

    @Test
    @DisplayName("正常系: トークン減算成功")
    void deductTokens_success() throws Exception {
        User user = new User();
        user.setId(2);
        Mockito.when(userService.deductUserTokens(2, 10)).thenReturn(user);
        mockMvc.perform(put("/api/users/2/deduct-tokens?tokensToDeduct=10")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(2));
    }
}
