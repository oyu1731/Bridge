package com.bridge.backend.controller;

import com.bridge.backend.entity.ForumThread;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
// import com.bridge.backend.repository.ThreadRepository;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
// import org.slf4j.Logger;
// import org.slf4j.LoggerFactory;
// import com.fasterxml.jackson.databind.ObjectMapper;
// import com.fasterxml.jackson.core.JsonProcessingException;
import java.util.List;
import java.util.Map;
import com.bridge.backend.service.ThreadService;
//ログでエラーを表示
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
//403エラー用
import org.springframework.security.access.AccessDeniedException;
//500エラー用
import org.springframework.dao.DataAccessException;

@RestController
@RequestMapping("/api/threads")
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class ThreadController {

    //エラーログ
    private static final Logger log = LoggerFactory.getLogger(ThreadController.class);
    private final ThreadService threadService;

    public ThreadController(ThreadService threadService) {
        this.threadService = threadService;
    }

    @GetMapping(produces = "application/json;charset=UTF-8")
    public List<ForumThread> getThreads() {
        return threadService.getAllThreads();
    }


    @PostMapping("/unofficial")
    public ForumThread createUnofficialThread(@RequestBody Map<String, Object> payload) {
        // userId が null または空文字なら 403
        if (!payload.containsKey("userId") || payload.get("userId") == null || payload.get("userId").toString().isBlank()) {
            throw new AccessDeniedException("サインインしてください");
        }

        // ここで String → Integer に変換して渡す
        try {
            payload.put("userId", Integer.valueOf(payload.get("userId").toString()));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("入力されていない項目か不正な入力値があります");
        }

        return threadService.createUnofficialThread(payload);
    }

    // @PostMapping("/unofficial")
    // public ForumThread createUnofficialThread(@RequestBody Map<String, Object> payload) {
    //     Object userIdObj = payload.get("userId");
    //     if (userIdObj == null || userIdObj.toString().isBlank()) {
    //         throw new ResponseStatusException(HttpStatus.FORBIDDEN, "ログインしてください");
    //     }
    //     return threadService.createUnofficialThread(payload);
    // }
    //エラーメッセージオブジェクトに保存する
    public class ErrorResponse {
        private String code;
        private String message;

        public ErrorResponse(String code, String message) {
            this.code = code;
            this.message = message;
        }

        public String getCode() { return code; }
        public String getMessage() { return message; }
    }


    //400
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> handleBadRequest(IllegalArgumentException ex) {

        ErrorResponse error = new ErrorResponse(
            "BAD_REQUEST",
            ex.getMessage()
        );

        log.warn("{}", error);

        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(error);
    }


    //403
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleForbidden(AccessDeniedException ex) {

        ErrorResponse error = new ErrorResponse(
            "FORBIDDEN",
            ex.getMessage()
        );

        log.warn("{}", error);

        return ResponseEntity
            .status(HttpStatus.FORBIDDEN)
            .body(error);
    }


    //500
    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<ErrorResponse> handleDbError(DataAccessException ex) {

        ErrorResponse error = new ErrorResponse(
            "DB_ERROR",
            "500 Internal Server Error"
        );

        log.error("{}", error, ex);

        return ResponseEntity
            .status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(error);
    }

    // // ここで Controller 内に例外ハンドリング
    // @ExceptionHandler(IllegalArgumentException.class)
    // public ResponseEntity<Map<String, String>> handleBadRequest(IllegalArgumentException ex) {
    //     Map<String, String> body = new HashMap<>();
    //     body.put("error", ex.getMessage());
    //     return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    // }

    // @ExceptionHandler(Exception.class)
    // public ResponseEntity<Map<String, String>> handleAllExceptions(Exception ex) {
    //     Map<String, String> body = new HashMap<>();
    //     body.put("error", "サーバーでエラーが発生しました");
    //     return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    // }
    
    @GetMapping("/admin/threads/reported")
    public List<Map<String, Object>> getReportedThreads() {
        return threadService.getThreadsOrderByLastReportedAt();
    }

    @PutMapping("admin/delete/{id}")
    public ResponseEntity<Void> deleteThread(@PathVariable Integer id) {
        threadService.deleteThread(id);
        return ResponseEntity.ok().build();
    }
}


// @RestController
// @RequestMapping("/api/threads")
// //@CrossOrigin(origins = "*") // FlutterからのCORS対応
// //@CrossOrigin(allowedOriginPatterns = "*", allowCredentials = "true") ←バージョンが古くて使えないワイルドカード
// //ここはデプロイした後に変わるかもしれないンゴ～
// @CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
// public class ThreadController {

//     private static final Logger logger = LoggerFactory.getLogger(ThreadController.class);
//     private final ObjectMapper objectMapper = new ObjectMapper();
//     private final ThreadRepository threadRepository;

//     public ThreadController(ThreadRepository threadRepository) {
//         this.threadRepository = threadRepository;
//     }

//     @GetMapping(produces = "application/json;charset=UTF-8")
//     public List<ForumThread> getThreads() {
//         List<com.bridge.backend.entity.ForumThread> threads = threadRepository.findByIsDeletedFalse();

//         // ログ出力（取得確認用）
//         try {
//             logger.info("取得したThreadデータ(JSON): {}", objectMapper.writeValueAsString(threads));
//         } catch (JsonProcessingException e) {
//             logger.error("ThreadデータのJSON変換中にエラーが発生しました", e);
//         }

//         // 各スレッド情報の確認ログ
//         for (ForumThread thread : threads) {
//             logger.info("Thread ID={} | Title={} | Type={} | Deleted={}",
//             thread.getId(),
//             thread.getTitle(),
//             thread.getType(),
//             thread.getIsDeleted());
//         }

//         return threads;
//     }
//     @PostMapping("/unofficial")
//     public ForumThread createUnofficialThread(@RequestBody Map<String, Object> payload) {
//         String title = (String) payload.get("title");
//         String description = (String) payload.get("description");
//         String condition = (String) payload.get("condition");
//         Integer userId = (Integer) payload.get("userId");

//         ForumThread thread = new ForumThread();
//         thread.setUserId(userId); // ←セットする
//         thread.setTitle(title);
//         thread.setDescription(description);

//         switch (condition) {
//             case "学生":
//                 thread.setEntryCriteria(2);
//                 break;
//             case "社会人":
//                 thread.setEntryCriteria(3);
//                 break;
//             default:
//                 thread.setEntryCriteria(1);
//         }

//         thread.setType(2); // 非公式スレッド
//         thread.setIndustry(null); // 一旦null、本来ならこの項目は存在しないので後でDB修正後削除

//         return threadRepository.save(thread);
//     }
// }