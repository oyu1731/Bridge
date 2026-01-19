package com.bridge.backend.service;

import com.bridge.backend.entity.ForumThread;
import com.bridge.backend.repository.ThreadRepository;
import org.springframework.stereotype.Service;

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
        Integer userId = (Integer) payload.get("userId");

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
}