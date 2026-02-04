package com.bridge.backend.controller;

import com.bridge.backend.service.PaymentService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import java.util.Map;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(PaymentController.class)
@org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc(addFilters = false)
class PaymentControllerTest {
    @Autowired
    private MockMvc mockMvc;
    @MockBean
    private PaymentService paymentService;


        @Test
        @DisplayName("idが数値型でない場合、空オブジェクト返却（現状仕様）")
        void sessionIdNotString() throws Exception {
                mockMvc.perform(get("/api/v1/payment/session/!@#")
                                .contentType(MediaType.APPLICATION_JSON))
                                .andExpect(status().isOk())
                                .andExpect(content().json("{}"));
        }

    @Test
    @DisplayName("idと一致するレコードがない場合、404+user_not_found返却（現状仕様）")
    void userNotFound() throws Exception {
        Mockito.when(paymentService.getUserInfoFromSession("notfound"))
                .thenReturn(null);
        mockMvc.perform(get("/api/v1/payment/session/notfound")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("user_not_found"));
    }

    @Test
    @DisplayName("DB接続エラー時は500+error返却（現状仕様）")
    void dbError() throws Exception {
        Mockito.when(paymentService.getUserInfoFromSession("dbfail"))
                .thenThrow(new RuntimeException("DB error"));
        mockMvc.perform(get("/api/v1/payment/session/dbfail")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").value("DB error"));
    }
}
