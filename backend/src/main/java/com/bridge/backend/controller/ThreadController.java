package com.bridge.backend.controller;

import com.bridge.backend.entity.ForumThread;
// import com.bridge.backend.repository.ThreadRepository;
import org.springframework.web.bind.annotation.*;
// import org.slf4j.Logger;
// import org.slf4j.LoggerFactory;
// import com.fasterxml.jackson.databind.ObjectMapper;
// import com.fasterxml.jackson.core.JsonProcessingException;
import java.util.List;
import java.util.Map;
import com.bridge.backend.service.ThreadService;

@RestController
@RequestMapping("/api/threads")
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class ThreadController {

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
        return threadService.createUnofficialThread(payload);
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