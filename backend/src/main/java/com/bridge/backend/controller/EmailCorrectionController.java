package com.bridge.backend.controller;

import com.bridge.backend.dto.EmailCorrectionRequestDTO;
import com.bridge.backend.dto.EmailCorrectionResponseDTO;
import com.bridge.backend.service.EmailCorrectionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

/**
 * 📧 EmailCorrectionController
 *
 * このクラスは「メール添削」に関するAPIエンドポイントをまとめたコントローラーです。
 * Spring MVCの @RestController を使っており、JSON形式でリクエストとレスポンスを処理します。
 */
@RestController
@RequestMapping("/api/email-correction") // このコントローラーのURLプレフィックス
public class EmailCorrectionController {

    private static final Logger logger = LoggerFactory.getLogger(EmailCorrectionController.class);

    private final EmailCorrectionService emailCorrectionService;

    public EmailCorrectionController(EmailCorrectionService emailCorrectionService) {
        this.emailCorrectionService = emailCorrectionService;
    }

    /**
     * POSTリクエストでメール添削を行うエンドポイント。
     *
     * 例:
     * curl -X POST http://localhost:8080/api/email-correction \
     *      -H "Content-Type: application/json" \
     *      -d '{"originalEmail":"お世話になります。先日の件ですが、資料送ってください。よろしくお願いします。"}'
     *
     * @param requestDTO - リクエストボディに含まれる添削したいメール本文
     * @return 添削後のメールと添削内容の詳細をJSONで返す
     */
    @PostMapping(produces = "application/json;charset=UTF-8")
    public EmailCorrectionResponseDTO correctEmail(@RequestBody EmailCorrectionRequestDTO requestDTO) {
        logger.info("Received request for email correction: {}", requestDTO.getOriginalEmail());
        return emailCorrectionService.correctEmail(requestDTO);
    }
}