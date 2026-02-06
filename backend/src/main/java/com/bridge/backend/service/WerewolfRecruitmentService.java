package com.bridge.backend.service;

import com.bridge.backend.model.WerewolfRecruitment;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 人狼ゲーム募集を管理するサービス
 */
@Service
public class WerewolfRecruitmentService {

    // chatId -> WerewolfRecruitment のマップ
    private final Map<Integer, WerewolfRecruitment> recruitments = new ConcurrentHashMap<>();
    
    // ユーザーのアクティブ状態管理 (userId -> threadId)
    private final Map<Integer, Integer> activeUsers = new ConcurrentHashMap<>();
    
    private final ObjectMapper objectMapper;
    private static final String DATA_FILE = "werewolf_recruitments.json";

    public WerewolfRecruitmentService() {
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
    }

    /**
     * 募集を開始する
     */
    public WerewolfRecruitment startRecruitment(Integer chatId, Integer threadId, Integer hostUserId) {
        WerewolfRecruitment recruitment = new WerewolfRecruitment(chatId, threadId, hostUserId);
        recruitments.put(chatId, recruitment);
        setUserActive(hostUserId, threadId);
        saveToFile();
        return recruitment;
    }

    /**
     * 募集情報を取得
     */
    public WerewolfRecruitment getRecruitment(Integer chatId) {
        WerewolfRecruitment recruitment = recruitments.get(chatId);
        if (recruitment != null && recruitment.isExpired() && recruitment.isActive()) {
            // 期限切れの場合は自動終了
            endRecruitment(chatId);
        }
        return recruitment;
    }

    /**
     * 参加する（スレッドIDチェック付き）
     */
    public boolean joinRecruitment(Integer chatId, Integer userId, Integer threadId) {
        WerewolfRecruitment recruitment = recruitments.get(chatId);
        // 同じスレッド内の募集のみ参加可能
        if (recruitment != null && 
            recruitment.getThreadId().equals(threadId) && 
            recruitment.isActive() && 
            !recruitment.isExpired()) {
            boolean joined = recruitment.addParticipant(userId);
            if (joined) {
                setUserActive(userId, threadId);
                saveToFile();
            }
            return joined;
        }
        return false;
    }

    /**
     * 参加を取り消す
     */
    public boolean leaveRecruitment(Integer chatId, Integer userId) {
        WerewolfRecruitment recruitment = recruitments.get(chatId);
        if (recruitment != null) {
            boolean left = recruitment.removeParticipant(userId);
            if (left) {
                removeUserActive(userId);
                saveToFile();
            }
            return left;
        }
        return false;
    }

    /**
     * 募集を終了する（主催者または自動）
     */
    public WerewolfRecruitment endRecruitment(Integer chatId) {
        WerewolfRecruitment recruitment = recruitments.get(chatId);
        if (recruitment != null) {
            recruitment.setActive(false);
            saveToFile();
            return recruitment;
        }
        return null;
    }

    /**
     * ユーザーをアクティブ状態にする
     */
    public void setUserActive(Integer userId, Integer threadId) {
        activeUsers.put(userId, threadId);
    }

    /**
     * ユーザーのアクティブ状態を解除
     */
    public void removeUserActive(Integer userId) {
        activeUsers.remove(userId);
    }

    /**
     * ユーザーが非アクティブになった場合の処理
     */
    public void handleUserInactive(Integer userId) {
        removeUserActive(userId);
        
        // 参加中の募集から削除
        for (WerewolfRecruitment recruitment : recruitments.values()) {
            if (recruitment.isActive()) {
                // 主催者が非アクティブになった場合は強制終了
                if (recruitment.getHostUserId().equals(userId)) {
                    endRecruitment(recruitment.getChatId());
                } else {
                    recruitment.removeParticipant(userId);
                }
            }
        }
        saveToFile();
    }

    /**
     * 全ての募集を取得（デバッグ用）
     */
    public List<WerewolfRecruitment> getAllRecruitments() {
        return new ArrayList<>(recruitments.values());
    }

    /**
     * 募集データをJSONファイルに保存
     */
    private void saveToFile() {
        try {
            Map<String, Object> data = new HashMap<>();
            data.put("recruitments", recruitments);
            data.put("activeUsers", activeUsers);
            objectMapper.writeValue(new File(DATA_FILE), data);
        } catch (IOException e) {
            System.err.println("Failed to save werewolf recruitment data: " + e.getMessage());
        }
    }

    /**
     * JSONファイルから募集データを読み込み
     */
    @SuppressWarnings("unchecked")
    public void loadFromFile() {
        File file = new File(DATA_FILE);
        if (file.exists()) {
            try {
                Map<String, Object> data = objectMapper.readValue(file, Map.class);
                // データの復元処理（必要に応じて実装）
            } catch (IOException e) {
                System.err.println("Failed to load werewolf recruitment data: " + e.getMessage());
            }
        }
    }

    /**
     * 募集データをクリア（全参加者が非アクティブになった場合）
     */
    public void clearRecruitmentData(Integer chatId) {
        WerewolfRecruitment recruitment = recruitments.get(chatId);
        if (recruitment != null) {
            // 全参加者が非アクティブかチェック
            boolean allInactive = recruitment.getParticipants().stream()
                .noneMatch(activeUsers::containsKey);
            
            if (allInactive) {
                recruitments.remove(chatId);
                saveToFile();
            }
        }
    }
    
    /**
     * ゲーム専用スレッドIDを設定
     */
    public void setGameThreadId(Integer chatId, Integer gameThreadId) {
        WerewolfRecruitment recruitment = recruitments.get(chatId);
        if (recruitment != null) {
            recruitment.setGameThreadId(gameThreadId);
            saveToFile();
            System.out.println("[募集] ゲームスレッドID設定: chatId=" + chatId + ", gameThreadId=" + gameThreadId);
        }
    }
}
