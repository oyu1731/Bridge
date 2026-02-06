package com.bridge.backend.model;

import java.time.LocalDateTime;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 人狼ゲーム募集情報を管理するクラス
 */
public class WerewolfRecruitment {
    public static final int MIN_PLAYERS = 3;  // ゲーム開始に必要な最小人数
    
    private Integer chatId;              // 募集チャットID
    private Integer threadId;            // スレッドID
    private Integer hostUserId;          // 主催者ID
    private Integer gameThreadId;        // ゲーム専用スレッドID（募集終了後に作成される）
    private LocalDateTime startTime;     // 募集開始時刻
    private LocalDateTime endTime;       // 募集終了時刻（開始から2分後）
    private Set<Integer> participants;   // 参加者IDリスト
    private boolean isActive;            // 募集中かどうか

    public WerewolfRecruitment(Integer chatId, Integer threadId, Integer hostUserId) {
        this.chatId = chatId;
        this.threadId = threadId;
        this.hostUserId = hostUserId;
        this.startTime = LocalDateTime.now();
        this.endTime = startTime.plusMinutes(2);
        this.participants = ConcurrentHashMap.newKeySet();
        this.participants.add(hostUserId); // 主催者を自動追加
        this.isActive = true;
    }

    // Getters
    public Integer getChatId() {
        return chatId;
    }

    public Integer getThreadId() {
        return threadId;
    }

    public Integer getHostUserId() {
        return hostUserId;
    }

    public LocalDateTime getStartTime() {
        return startTime;
    }

    public LocalDateTime getEndTime() {
        return endTime;
    }

    public Set<Integer> getParticipants() {
        return participants;
    }

    public boolean isActive() {
        return isActive;
    }

    public Integer getGameThreadId() {
        return gameThreadId;
    }

    public int getParticipantCount() {
        return participants.size();
    }

    // Setters
    public void setActive(boolean active) {
        isActive = active;
    }

    public void setGameThreadId(Integer gameThreadId) {
        this.gameThreadId = gameThreadId;
    }

    // Methods
    public boolean addParticipant(Integer userId) {
        if (isActive && !participants.contains(userId)) {
            return participants.add(userId);
        }
        return false;
    }

    public boolean removeParticipant(Integer userId) {
        return participants.remove(userId);
    }

    public boolean isExpired() {
        return LocalDateTime.now().isAfter(endTime);
    }

    public long getRemainingSeconds() {
        LocalDateTime now = LocalDateTime.now();
        if (now.isAfter(endTime)) {
            return 0;
        }
        return java.time.Duration.between(now, endTime).getSeconds();
    }

    /**
     * ゲーム開始可能かどうか（参加者が3人以上）
     */
    public boolean canStartGame() {
        return participants.size() >= MIN_PLAYERS;
    }
}
