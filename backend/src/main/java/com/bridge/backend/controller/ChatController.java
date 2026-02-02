package com.bridge.backend.controller;
// import com.bridge.backend.entity.User;
import com.bridge.backend.entity.Chat;
// import com.bridge.backend.entity.ForumThread;
// import com.bridge.backend.repository.ThreadRepository;
// import com.bridge.backend.repository.UserRepository;
// import com.bridge.backend.repository.ChatRepository;
import com.bridge.backend.service.ChatService;

import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

// import org.slf4j.Logger;
// import org.slf4j.LoggerFactory;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
// import org.springframework.stereotype.Service;
// import java.time.LocalDateTime;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    //全取得
    @GetMapping("/{threadId}")
    public List<Chat> all_chat(@PathVariable Integer threadId) {
        return chatService.getMessagesByThreadId(threadId);
    }

    //is_deletedが0（論理削除されていない）メッセージのみ取得
    @GetMapping("/{threadId}/active")
    public List<Chat> thread_chat(@PathVariable Integer threadId) {
        return chatService.getActiveChatsByThreadId(threadId);
    }

    //チャットを保存
    @PostMapping("/{threadId}")
    public Chat chat_creating(@PathVariable Integer threadId, @RequestBody Chat chat) {
        return chatService.postMessage(threadId, chat);
    }

    //チャットのユーザー情報の取得（名前とか）
    @GetMapping("/user/{userId}")
    public Map<String, String> getUser(@PathVariable Integer userId) {
        return chatService.getUserInfo(userId);
    }

    //エラーメッセージオブジェクトに保存する
    public class ErrorResponse {
        private String code;
        private String message;

        public ErrorResponse(String code, String message) {
            this.code = code;
            this.message = message;
        }

        public String getCode() {
            return code;
        }

        public String getMessage() {
            return message;
        }
    }
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleForbidden(AccessDeniedException ex) {
        return ResponseEntity
                .status(HttpStatus.FORBIDDEN)
                .body(new ErrorResponse(
                    "FORBIDDEN",
                    ex.getMessage()
                ));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ErrorResponse> handleResponseStatusException(ResponseStatusException ex) {
        return ResponseEntity
                .status(ex.getStatusCode())
                .body(new ErrorResponse(
                    ex.getStatusCode().toString(), // or 固定文字列でもOK
                    ex.getReason()
                ));
    }

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<ErrorResponse> handleDbError(DataAccessException ex) {
        ex.printStackTrace();
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse(
                    "DB_ERROR",
                    "500 Internal Server Error"
                ));
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTypeMismatch(
            MethodArgumentTypeMismatchException ex) {

        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse(
                    "INVALID_PARAMETER",
                    "入力されていない項目か不正な入力値があります"
                ));
    }
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleAll(Exception ex) {
        ex.printStackTrace();
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse(
                    "INTERNAL_ERROR",
                    "500 Internal Server Error"
                ));
    }






    // //400
    // @ExceptionHandler(IllegalArgumentException.class)
    // public ResponseEntity<Map<String, String>> handleBadRequest(IllegalArgumentException ex) {
    //     return ResponseEntity
    //             .status(HttpStatus.BAD_REQUEST)
    //             .body(Map.of("error", ex.getMessage()));
    // }

    // //403
    // @ExceptionHandler(AccessDeniedException.class)
    // public ResponseEntity<Map<String, String>> handleForbidden(AccessDeniedException ex) {
    //     return ResponseEntity
    //             .status(HttpStatus.FORBIDDEN)
    //             .body(Map.of("error", ex.getMessage()));
    // }

    // // 401 Unauthorized
    // @ExceptionHandler(org.springframework.web.server.ResponseStatusException.class)
    // public ResponseEntity<Map<String, String>> handleResponseStatusException(ResponseStatusException ex) {
    //     return ResponseEntity
    //             .status(ex.getStatusCode())
    //             .body(Map.of("error", ex.getReason()));
    // }

    // //500
    // @ExceptionHandler(DataAccessException.class)
    // public ResponseEntity<Map<String, String>> handleDbError(DataAccessException ex) {
    //     ex.printStackTrace();
    //     return ResponseEntity
    //             .status(HttpStatus.INTERNAL_SERVER_ERROR)
    //             .body(Map.of("error", "DB接続エラー"));
    // }

    // //400数値型チェック（コントローラーに入る前）
    // @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    // public ResponseEntity<Map<String, String>> handleTypeMismatch(
    //         MethodArgumentTypeMismatchException ex) {

    //     return ResponseEntity
    //             .status(HttpStatus.BAD_REQUEST)
    //             .body(Map.of(
    //                 "error", "入力されていない項目か不正な入力値があります"
    //             ));
    // }
}






// @RestController
// @RequestMapping("/api/chat") // threads とは独立
// //ここはデプロイした後に変わるかもしれない～
// @CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
// public class ChatController {

//     private static final Logger logger = LoggerFactory.getLogger(ChatController.class);

//     private final ChatRepository chatRepository;
//     private final UserRepository userRepository;
//     private final ThreadRepository threadRepository;

//     public ChatController(ChatRepository chatRepository, UserRepository userRepository, ThreadRepository threadRepository) {
//         this.chatRepository = chatRepository;
//         this.userRepository = userRepository;
//         this.threadRepository = threadRepository;
//     }

//     /**
//      * 指定スレッドIDのメッセージ一覧取得
//      */
//     @GetMapping("/{threadId}")
//     public List<Chat> getMessages(@PathVariable("threadId") Integer threadId) {
//         System.out.println("getMessages が呼ばれました: threadId=" + threadId);

//         List<Chat> messages = chatRepository.findByThreadIdOrderByCreatedAtAsc(threadId);
//         System.out.println("DBから取得したメッセージ数: " + messages.size());

//         // メッセージ内容も確認
//         for (Chat chat : messages) {
//             System.out.println("ChatID=" + chat.getId() + ", content=" + chat.getContent());
//         }

//         return messages;
//     }

//     /**
//      * 指定スレッドIDにメッセージ投稿
//      */
//     @PostMapping("/{threadId}")
//     public Chat postMessage(@PathVariable("threadId") Integer threadId, @RequestBody Chat chat) {
//         // コメント情報セット
//         chat.setThreadId(threadId);
//         chat.setCreatedAt(java.time.LocalDateTime.now());
//         Chat saved = chatRepository.save(chat);
//         logger.info("postMessage: threadId={} savedId={}", threadId, saved.getId());

//         // スレッドの最終更新日時を更新
//         ForumThread thread = threadRepository.findById(threadId)
//                                 .orElseThrow(() -> new RuntimeException("スレッドが見つかりません"));
//         thread.setLastUpdateDate(java.time.LocalDateTime.now());
//         threadRepository.save(thread);

//         return saved;
//     }


//     // ユーザーidを指定して情報を取得（本来はUserContollerに書くべきだが競合が怖いので一旦こちらに記述by髙橋）
//     @GetMapping("/user/{userId}")
//     public Map<String, String> getUser(@PathVariable Integer userId) {
//         // userRepository を注入している前提
//         User user = userRepository.findById(userId).orElse(null);

//         Map<String, String> result = new HashMap<>();
//         if (user != null) {
//             result.put("nickname", user.getNickname());
//             result.put("email", user.getEmail()); // 必要なら他情報も追加可能
//         } else {
//             result.put("nickname", "Unknown");
//         }
//         return result;
//     }
// }
