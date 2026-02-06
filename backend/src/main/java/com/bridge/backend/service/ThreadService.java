package com.bridge.backend.service;

import com.bridge.backend.entity.ForumThread;
import com.bridge.backend.repository.ThreadRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ThreadService {

    private final ThreadRepository threadRepository;

    public ThreadService(ThreadRepository threadRepository) {
        this.threadRepository = threadRepository;
    }

    public List<ForumThread> getAllThreads() {
        return threadRepository.findByIsDeletedFalse();
    }

    public ForumThread createUnofficialThread(Map<String, Object> payload) {
        String title = (String) payload.get("title");
        String description = (String) payload.get("description");
        String condition = (String) payload.get("condition");
        // Integer userId = (Integer) payload.get("userId");
        //数字以外の文字列だと５００番エラー
        Integer userId = Integer.valueOf(payload.get("userId").toString());

        // バリデーション
        if (title == null || title.trim().isEmpty()) {
            throw new IllegalArgumentException("タイトルは必須です");
        }
        if (title.length() > 255) {
            throw new IllegalArgumentException("タイトルは255文字以内で入力してください");
        }
        if (condition == null || condition.trim().isEmpty()) {
            throw new IllegalArgumentException("参加条件は必須です");
        }

        ForumThread thread = new ForumThread();
        thread.setUserId(userId);
        thread.setTitle(title);
        thread.setDescription(description);

        switch (condition) {
            case "学生":
                thread.setEntryCriteria(2);
                break;
            case "社会人":
                thread.setEntryCriteria(3);
                break;
            default:
                thread.setEntryCriteria(1);
        }

        thread.setType(2); // 非公式スレッド
        thread.setIndustry(null);

        return threadRepository.save(thread);
    }

    public List<Map<String, Object>> getThreadsOrderByLastReportedAt() {
        List<Object[]> rows = threadRepository.findThreadsOrderByLastReportedAt();

        return rows.stream().map(row -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", row[0]);
            map.put("userId", row[1]);
            map.put("title", row[2]);
            map.put("type", row[3]);
            map.put("description", row[4]);
            map.put("entryCriteria", row[5]);
            map.put("lastUpdateDate", row[6]);
            map.put("lastReportedAt", row[7]);
            return map;
        }).toList();
    }

    @Transactional
    public void deleteThread(Integer threadId) {
        threadRepository.softDelete(threadId);
    }

    @Transactional
    public void deleteThreadHard(Integer threadId) {
        threadRepository.hardDelete(threadId);
    }
    
    /**
     * 汎用スレッド保存メソッド
     */
    public ForumThread saveThread(ForumThread thread) {
        return threadRepository.save(thread);
    }
}