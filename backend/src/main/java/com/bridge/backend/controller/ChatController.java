package com.bridge.backend.controller;
// import com.bridge.backend.entity.User;
import com.bridge.backend.entity.Chat;
import com.bridge.backend.repository.ChatRepository;
// import com.bridge.backend.entity.ForumThread;
// import com.bridge.backend.repository.ThreadRepository;
// import com.bridge.backend.repository.UserRepository;
// import com.bridge.backend.repository.ChatRepository;
import com.bridge.backend.service.ChatService;
import com.bridge.backend.service.WerewolfRecruitmentService;
import com.bridge.backend.service.WerewolfGameService;
import com.bridge.backend.service.ThreadService;
import com.bridge.backend.model.WerewolfRecruitment;
import com.bridge.backend.model.WerewolfGame;

import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.transaction.annotation.Transactional;

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
public class ChatController {

    private final ChatService chatService;
    private final ChatRepository chatRepository;
    private final WerewolfRecruitmentService werewolfService;
    private final WerewolfGameService werewolfGameService;
    private final ThreadService threadService;

    public ChatController(ChatService chatService, ChatRepository chatRepository, 
                         WerewolfRecruitmentService werewolfService,
                         WerewolfGameService werewolfGameService,
                         ThreadService threadService) {
        this.chatService = chatService;
        this.chatRepository = chatRepository;
        this.werewolfService = werewolfService;
        this.werewolfGameService = werewolfGameService;
        this.threadService = threadService;
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
    // 管理者用：チャット論理削除
    @PutMapping("/{chatId}/delete")
    @Transactional
    public ResponseEntity<Void> deleteChat(@PathVariable Integer chatId) {
        chatRepository.softDelete(chatId);
        return ResponseEntity.ok().build();
    }

    // 人狼ゲーム募集メッセージ物理削除（完全削除）
    @DeleteMapping("/werewolf/{chatId}/delete")
    @Transactional
    public ResponseEntity<Void> deleteWerewolfChat(@PathVariable Integer chatId) {
        chatRepository.deleteById(chatId);
        return ResponseEntity.ok().build();
    }

    // ====== 人狼ゲーム募集関連エンドポイント ======
    
    /**
     * 人狼ゲーム募集を開始
     */
    @PostMapping("/werewolf/start")
    public ResponseEntity<Map<String, Object>> startWerewolfRecruitment(@RequestBody Map<String, Integer> request) {
        Integer chatId = request.get("chatId");
        Integer threadId = request.get("threadId");
        Integer hostUserId = request.get("userId");
        
        WerewolfRecruitment recruitment = werewolfService.startRecruitment(chatId, threadId, hostUserId);
        
        Map<String, Object> response = new HashMap<>();
        response.put("chatId", recruitment.getChatId());
        response.put("threadId", recruitment.getThreadId());
        response.put("isActive", recruitment.isActive());
        response.put("participantCount", recruitment.getParticipantCount());
        response.put("remainingSeconds", recruitment.getRemainingSeconds());
        response.put("canStartGame", recruitment.canStartGame());
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * 募集情報を取得
     */
    @GetMapping("/werewolf/{chatId}")
    public ResponseEntity<Map<String, Object>> getWerewolfRecruitment(@PathVariable Integer chatId) {
        WerewolfRecruitment recruitment = werewolfService.getRecruitment(chatId);
        
        if (recruitment == null) {
            return ResponseEntity.notFound().build();
        }
        
        Map<String, Object> response = new HashMap<>();
        response.put("chatId", recruitment.getChatId());
        response.put("threadId", recruitment.getThreadId());
        response.put("hostUserId", recruitment.getHostUserId());
        response.put("gameThreadId", recruitment.getGameThreadId()); // ゲーム専用スレッドID
        response.put("isActive", recruitment.isActive());
        response.put("participantCount", recruitment.getParticipantCount());
        response.put("participants", recruitment.getParticipants());
        response.put("remainingSeconds", recruitment.getRemainingSeconds());
        response.put("canStartGame", recruitment.canStartGame());
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * 募集に参加
     */
    @PostMapping("/werewolf/{chatId}/join")
    public ResponseEntity<Map<String, Object>> joinWerewolfRecruitment(
            @PathVariable Integer chatId, 
            @RequestBody Map<String, Integer> request) {
        Integer userId = request.get("userId");
        Integer threadId = request.get("threadId");
        
        boolean success = werewolfService.joinRecruitment(chatId, userId, threadId);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", success);
        
        if (success) {
            WerewolfRecruitment recruitment = werewolfService.getRecruitment(chatId);
            response.put("participantCount", recruitment.getParticipantCount());
        }
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * 募集から離脱
     */
    @PostMapping("/werewolf/{chatId}/leave")
    public ResponseEntity<Map<String, Object>> leaveWerewolfRecruitment(
            @PathVariable Integer chatId, 
            @RequestBody Map<String, Integer> request) {
        Integer userId = request.get("userId");
        
        System.out.println("=========================================");
        System.out.println("人狼募集離脱リクエスト受信");
        System.out.println("chatId: " + chatId);
        System.out.println("userId: " + userId);
        System.out.println("=========================================");
        
        // 募集情報を取得
        WerewolfRecruitment recruitment = werewolfService.getRecruitment(chatId);
        Map<String, Object> response = new HashMap<>();
        
        if (recruitment == null) {
            response.put("success", false);
            response.put("message", "募集が見つかりません");
            System.out.println("離脱失敗: 募集が見つかりません");
            return ResponseEntity.ok(response);
        }
        
        // 主催者が離脱する場合
        if (userId.equals(recruitment.getHostUserId())) {
            System.out.println("主催者の離脱を検出 - 募集を強制終了してチャットを削除");
            
            // 募集を終了
            werewolfService.endRecruitment(chatId);
            
            // チャットを物理削除
            try {
                chatRepository.deleteById(chatId);
                System.out.println("チャット削除成功: chatId=" + chatId);
            } catch (Exception e) {
                System.err.println("チャット削除エラー: " + e.getMessage());
            }
            
            response.put("success", true);
            response.put("hostLeft", true);
            response.put("message", "主催者が離脱したため募集を終了しました");
            System.out.println("主催者離脱処理完了");
            
            return ResponseEntity.ok(response);
        }
        
        // 通常の参加者の離脱処理
        boolean success = werewolfService.leaveRecruitment(chatId, userId);
        
        response.put("success", success);
        response.put("hostLeft", false);
        
        if (success) {
            WerewolfRecruitment updatedRecruitment = werewolfService.getRecruitment(chatId);
            response.put("participantCount", updatedRecruitment.getParticipantCount());
            System.out.println("離脱成功 - 残り参加者: " + updatedRecruitment.getParticipantCount());
        } else {
            System.out.println("離脱失敗");
        }
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * 募集を終了
     */
    @PostMapping("/werewolf/{chatId}/end")
    public ResponseEntity<Map<String, Object>> endWerewolfRecruitment(
            @PathVariable Integer chatId,
            @RequestBody Map<String, Integer> request) {
        Integer userId = request.get("userId");
        
        WerewolfRecruitment recruitment = werewolfService.getRecruitment(chatId);
        
        // 主催者のみ終了可能
        if (recruitment == null || !recruitment.getHostUserId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        
        boolean canStartGame = recruitment.canStartGame();
        werewolfService.endRecruitment(chatId);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("canStartGame", canStartGame);
        response.put("participantCount", recruitment.getParticipantCount());
        response.put("participants", recruitment.getParticipants());
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * ユーザーの非アクティブ通知
     */
    @PostMapping("/werewolf/user/inactive")
    public ResponseEntity<Void> notifyUserInactive(@RequestBody Map<String, Integer> request) {
        Integer userId = request.get("userId");
        werewolfService.handleUserInactive(userId);
        return ResponseEntity.ok().build();
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

    /**
     * 人狼ゲーム開始（ルール設定のステップを開始）
     * @param threadId ゲームスレッドのID
     * @param request gameMasterId, participants
     * @return 最初のボットメッセージ
     */
    @PostMapping("/werewolf/game/{threadId}/start")
    public ResponseEntity<Map<String, Object>> startWerewolfGame(
            @PathVariable Integer threadId,
            @RequestBody Map<String, Object> request) {
        
        try {
            Integer gameMasterId = (Integer) request.get("gameMasterId");
            @SuppressWarnings("unchecked")
            List<Integer> participants = (List<Integer>) request.get("participants");
            
            System.out.println("[/start呼び出し] threadId=" + threadId + ", リクエストGM=" + gameMasterId + ", participants=" + participants);
            
            // ゲームマスターは必ずparticipants[0]（募集の主催者）に固定
            if (participants != null && !participants.isEmpty()) {
                gameMasterId = participants.get(0);
                System.out.println("[/start呼び出し] GMをparticipants[0]に固定: " + gameMasterId);
            }
            
            // ゲーム開始（既に存在する場合は既存のものを取得）
            WerewolfGame game = werewolfGameService.startGame(threadId, gameMasterId, participants);
            System.out.println("[/start結果] ゲームGM=" + game.getGameMasterId());
            
            // 初回ボットメッセージを取得（全員に送信）
            boolean isGM = gameMasterId.equals(gameMasterId); // 常にtrue（GM向け）
            String botMessage = werewolfGameService.getInitialBotMessage(threadId, isGM);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("botMessage", botMessage);
            response.put("phase", game.getCurrentPhase().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    /**
     * ゲームマスターからのメッセージ送信（ルール設定のステップ処理）
     * @param threadId ゲームスレッドのID
     * @param request userId, message
     * @return 次のボットメッセージ
     */
    @PostMapping("/werewolf/game/{threadId}/setup")
    public ResponseEntity<Map<String, Object>> processSetup(
            @PathVariable Integer threadId,
            @RequestBody Map<String, String> request) {
        
        try {
            Integer userId = Integer.parseInt(request.get("userId"));
            String message = request.get("message");
            
            // ゲームマスターかチェック
            if (!werewolfGameService.isGameMaster(threadId, userId)) {
                Map<String, Object> error = new HashMap<>();
                error.put("success", false);
                error.put("message", "ゲームマスターのみが設定できます");
                return ResponseEntity.status(403).body(error);
            }
            
            // ステップ処理
            String botResponse = werewolfGameService.processSetupStep(threadId, message);
            
            WerewolfGame game = werewolfGameService.getGame(threadId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("botMessage", botResponse);
            response.put("setupStep", game.getSetupStep());
            response.put("setupComplete", "complete".equals(game.getSetupStep()));
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    /**
     * ゲーム情報を取得
     * @param threadId ゲームスレッドのID
     * @param userId リクエストしたユーザーのID（オプション）
     * @return ゲーム情報
     */
    @GetMapping("/werewolf/game/{threadId}")
    public ResponseEntity<Map<String, Object>> getWerewolfGame(
            @PathVariable Integer threadId,
            @RequestParam(required = false) Integer userId) {
        try {
            WerewolfGame game = werewolfGameService.getGame(threadId);
            
            if (game == null) {
                Map<String, Object> error = new HashMap<>();
                error.put("success", false);
                error.put("message", "ゲームが見つかりません");
                return ResponseEntity.status(404).body(error);
            }
            
            boolean isGM = userId != null && game.getGameMasterId().equals(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("phase", game.getCurrentPhase().toString());
            response.put("setupStep", game.getSetupStep());
            response.put("gameMasterId", game.getGameMasterId());
            response.put("participantCount", game.getParticipantCount());
            response.put("currentCycle", game.getCurrentCycle());
            response.put("discussionTimeMinutes", game.getDiscussionTimeMinutes());
                response.put("aliveUserIds", game.getPlayerAlive().entrySet().stream()
                    .filter(e -> Boolean.TRUE.equals(e.getValue()))
                    .map(Map.Entry::getKey)
                    .toList());
                response.put("deadUserIds", game.getPlayerAlive().entrySet().stream()
                    .filter(e -> !Boolean.TRUE.equals(e.getValue()))
                    .map(Map.Entry::getKey)
                    .toList());
            
            // 非GMの場合は待機メッセージを含める
            if (!isGM && "SETUP".equals(game.getCurrentPhase().toString())) {
                String waitMessage = werewolfGameService.getInitialBotMessage(threadId, false);
                response.put("waitMessage", waitMessage);
            }
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    /**
     * 役職を配分してゲームを開始
     */
    @PostMapping("/werewolf/game/{threadId}/assign-roles")
    public ResponseEntity<Map<String, Object>> assignRoles(@PathVariable Integer threadId) {
        try {
            werewolfGameService.assignRolesAndStart(threadId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "役職を配分しました");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    /**
     * プレイヤーの役職情報を取得
     */
    @GetMapping("/werewolf/game/{threadId}/role")
    public ResponseEntity<Map<String, Object>> getPlayerRole(
            @PathVariable Integer threadId,
            @RequestParam Integer userId) {
        try {
            String roleMessage = werewolfGameService.getRoleNotificationMessage(threadId, userId);
            
            if (roleMessage == null) {
                Map<String, Object> error = new HashMap<>();
                error.put("success", false);
                error.put("message", "役職情報が見つかりません");
                return ResponseEntity.status(404).body(error);
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("roleMessage", roleMessage);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    /**
     * 夜の行動を記録
     */
    @PostMapping("/werewolf/game/{threadId}/night-action")
    public ResponseEntity<Map<String, Object>> recordNightAction(
            @PathVariable Integer threadId,
            @RequestBody Map<String, Integer> request) {
        try {
            Integer userId = request.get("userId");
            Integer targetUserId = request.get("targetUserId");
            
            werewolfGameService.recordNightAction(threadId, userId, targetUserId);
            
            // 全員完了したか確認
            boolean isComplete = werewolfGameService.isNightComplete(threadId);
            String seerResult = werewolfGameService.getSeerResultMessage(threadId, userId, targetUserId);
            String knightResult = werewolfGameService.getKnightResultMessage(threadId, userId, targetUserId);
            String mediumResult = werewolfGameService.getMediumResultMessage(threadId, userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("nightComplete", isComplete);
            if (seerResult != null) {
                response.put("seerResult", seerResult);
            }
            if (knightResult != null) {
                response.put("knightResult", knightResult);
            }
            if (mediumResult != null) {
                response.put("mediumResult", mediumResult);
            }
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }

    /**
     * 夜の行動が完了しているか確認
     */
    @GetMapping("/werewolf/game/{threadId}/night-complete")
    public ResponseEntity<Map<String, Object>> checkNightComplete(@PathVariable Integer threadId) {
        try {
            boolean isComplete = werewolfGameService.isNightComplete(threadId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("nightComplete", isComplete);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }

    /**
     * 非アクティブなプレイヤーを静観状態にする
     */
    @PostMapping("/werewolf/game/{threadId}/inactive")
    public ResponseEntity<Map<String, Object>> markInactive(
            @PathVariable Integer threadId,
            @RequestBody Map<String, Integer> request) {
        try {
            Integer userId = request.get("userId");
            werewolfGameService.markPlayerInactive(threadId, userId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }

    /**
     * ゲームを強制終了（GM非アクティブ時）
     */
    @PostMapping("/werewolf/game/{threadId}/force-end")
    public ResponseEntity<Map<String, Object>> forceEndGame(@PathVariable Integer threadId) {
        try {
            werewolfGameService.forceEndGame(threadId);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    /**
     * 夜フェーズを実行
     */
    @PostMapping("/werewolf/game/{threadId}/execute-night")
    public ResponseEntity<Map<String, Object>> executeNight(@PathVariable Integer threadId) {
        try {
            String resultMessage = werewolfGameService.executeNightPhase(threadId);
            WerewolfGame game = werewolfGameService.getGame(threadId);
            Integer killedUserId = game != null ? game.getLastKilledUserId() : null;
            Integer protectedUserId = game != null ? game.getLastProtectedUserId() : null;
            String winner = werewolfGameService.checkWinner(threadId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", resultMessage);
            response.put("killedUserId", killedUserId);
            response.put("protectedUserId", protectedUserId);
            response.put("winner", winner);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    /**
     * 議論フェーズを終了して投票へ
     */
    @PostMapping("/werewolf/game/{threadId}/end-discussion")
    public ResponseEntity<Map<String, Object>> endDiscussion(@PathVariable Integer threadId) {
        try {
            WerewolfGame game = werewolfGameService.getGame(threadId);
            if (game == null) {
                Map<String, Object> error = new HashMap<>();
                error.put("success", false);
                error.put("message", "ゲームが見つかりません");
                return ResponseEntity.status(404).body(error);
            }
            
            game.setCurrentPhase(WerewolfGame.Phase.VOTING);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "投票フェーズを開始します");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    /**
     * 投票を記録
     */
    @PostMapping("/werewolf/game/{threadId}/vote")
    public ResponseEntity<Map<String, Object>> recordVote(
            @PathVariable Integer threadId,
            @RequestBody Map<String, Integer> request) {
        try {
            Integer voterId = request.get("voterId");
            Integer targetId = request.get("targetId");
            
            werewolfGameService.recordVote(threadId, voterId, targetId);
            
            // 全員投票したか確認
            boolean isComplete = werewolfGameService.isVoteComplete(threadId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("voteComplete", isComplete);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    /**
     * 投票を集計して処刑を実行
     */
    @PostMapping("/werewolf/game/{threadId}/execute-vote")
    public ResponseEntity<Map<String, Object>> executeVote(@PathVariable Integer threadId) {
        try {
            Integer executed = werewolfGameService.executeVoting(threadId);
            String winner = werewolfGameService.checkWinner(threadId);

            // 当日の議論チャットを物理削除
            chatService.deleteChatsByThreadId(threadId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("executedUserId", executed);
            response.put("winner", winner);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }

    /**
     * ゲーム専用スレッドと関連チャットを物理削除
     */
    @PostMapping("/werewolf/game/{threadId}/cleanup")
    public ResponseEntity<Map<String, Object>> cleanupGameThread(@PathVariable Integer threadId) {
        try {
            chatService.deleteChatsByThreadId(threadId);
            threadService.deleteThreadHard(threadId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    /**
     * 勝敗判定
     */
    @GetMapping("/werewolf/game/{threadId}/winner")
    public ResponseEntity<Map<String, Object>> checkWinner(@PathVariable Integer threadId) {
        try {
            String winner = werewolfGameService.checkWinner(threadId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("winner", winner);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    /**
     * ゲーム専用スレッドIDを募集に保存
     */
    @PutMapping("/werewolf/recruitment/{chatId}/game-thread")
    public ResponseEntity<Map<String, Object>> setGameThreadId(
            @PathVariable Integer chatId,
            @RequestBody Map<String, Integer> request) {
        try {
            Integer gameThreadId = request.get("gameThreadId");
            werewolfService.setGameThreadId(chatId, gameThreadId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
}
