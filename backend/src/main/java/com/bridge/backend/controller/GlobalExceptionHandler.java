package com.bridge.backend.controller;

import com.fasterxml.jackson.databind.exc.InvalidFormatException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.http.converter.HttpMessageNotReadableException;
import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(HttpMessageNotReadableException.class)
    @ResponseBody
    public ResponseEntity<?> handleHttpMessageNotReadable(HttpMessageNotReadableException ex) {
        Map<String, Object> response = new HashMap<>();
        Map<String, String> errors = new HashMap<>();
        Throwable cause = ex.getCause();
        if (cause instanceof InvalidFormatException) {
            InvalidFormatException ife = (InvalidFormatException) cause;
            String field = ife.getPath().size() > 0 ? ife.getPath().get(0).getFieldName() : "unknown";
            response.put("input", Map.of(field, ife.getValue()));
            // スネークケース変換＋address特例
            String snake = field.replaceAll("([A-Z])", "_$1").toLowerCase();
            if ("company_address".equals(snake)) snake = "address";
            errors.put(snake, "入力されていない項目か不正な入力値があります");
        } else {
            response.put("input", null);
            errors.put("system", "入力値エラー");
        }
        response.put("errors", errors);
        return ResponseEntity.badRequest().body(response);
    }
}
