package com.bridge.backend.controller;

import com.bridge.backend.service.UserService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import jakarta.servlet.http.HttpSession;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
@org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc(addFilters = false)
class UserControllerDeleteUserTest {
    @Autowired
    private MockMvc mockMvc;
    @MockBean
    private UserService userService;
    @MockBean
    private com.bridge.backend.repository.IndustryRepository industryRepository;
    @MockBean
    private HttpSession session;

    @Test
    @DisplayName("idが数値型でない場合、400+エラー返却")
    void deleteUser_idNotInteger() throws Exception {
        mockMvc.perform(delete("/api/users/abc")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.input").value("abc"))
                .andExpect(jsonPath("$.errors.message").value("入力されていない項目か不正な入力値があります"));
    }

    @Test
    @DisplayName("idと一致するレコードがない場合、200+null+エラー返却")
    void deleteUser_userNotFound() throws Exception {
        Mockito.doThrow(new RuntimeException("User not found")).when(userService).deleteUser(99);
        mockMvc.perform(delete("/api/users/99")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").value((Object) null))
                .andExpect(jsonPath("$.errors.message").value("ユーザーの登録情報がありません"));
    }

    @Test
    @DisplayName("DBエラー時は500+エラー返却")
    void deleteUser_dbError() throws Exception {
        Mockito.doThrow(new RuntimeException("DB error")).when(userService).deleteUser(1);
        mockMvc.perform(delete("/api/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.errors.message").value("Internal Server Error"));
    }

    @Test
    @DisplayName("正常系: 削除成功")
    void deleteUser_success() throws Exception {
        Mockito.doNothing().when(userService).deleteUser(2);
        mockMvc.perform(delete("/api/users/2")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").value("User deleted successfully and session invalidated"));
    }
}
