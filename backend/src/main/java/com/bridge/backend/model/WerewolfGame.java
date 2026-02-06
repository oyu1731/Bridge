package com.bridge.backend.model;

import java.util.*;

/**
 * 人狼ゲームの状態を管理するクラス
 */
public class WerewolfGame {
    
    // ゲームフェーズ
    public enum Phase {
        SETUP,          // ルール設定中
        ROLE_ASSIGNMENT, // 役職配分
        NIGHT,          // 夜フェーズ
        DISCUSSION,     // 議論フェーズ
        VOTING,         // 投票フェーズ
        ENDED           // ゲーム終了
    }
    
    // 役職
    public enum Role {
        VILLAGER,   // 村人
        WEREWOLF,   // 人狼
        SEER,       // 占い師
        KNIGHT,     // 騎士
        MEDIUM      // 霊媒師
    }
    
    private Integer threadId;                    // 専用スレッドID
    private Integer gameMasterId;                // ゲームマスターのユーザーID
    private List<Integer> participants;          // 参加者のユーザーIDリスト
    private Phase currentPhase;                  // 現在のフェーズ
    
    // ゲーム設定
    private Integer werewolfCount;               // 人狼の人数
    private Integer discussionTimeMinutes;       // 議論時間（分）
    private boolean hasSpecialRoles;             // 特殊役職の有無
    
    // 設定フロー用
    private String setupStep;                    // 現在の設定ステップ (werewolf_count, discussion_time, special_roles, complete)
    
    // ゲーム進行用
    private Map<Integer, Role> playerRoles;      // userId -> 役職
    private Map<Integer, Boolean> playerAlive;   // userId -> 生存状態
    private int currentCycle;                    // 現在のサイクル数（日数）
    private Map<Integer, Integer> nightActions;  // 夜の行動 (userId -> targetUserId)
    private Integer lastExecutedUserId;          // 直近の処刑ユーザーID
    private Integer lastKilledUserId;            // 直近の襲撃ユーザーID
    private Integer lastProtectedUserId;         // 直近の護衛ユーザーID
    
    public WerewolfGame(Integer threadId, Integer gameMasterId, List<Integer> participants) {
        this.threadId = threadId;
        this.gameMasterId = gameMasterId;
        this.participants = new ArrayList<>(participants);
        this.currentPhase = Phase.SETUP;
        
        // 5人以下の場合は人狼を1人に固定し、議論時間から開始
        if (participants.size() <= 5) {
            this.werewolfCount = 1;
            this.setupStep = "discussion_time";
        } else {
            this.setupStep = "werewolf_count";
        }
        
        this.playerRoles = new HashMap<>();
        this.playerAlive = new HashMap<>();
        this.currentCycle = 0;
        this.nightActions = new HashMap<>();
        
        // 全員を生存状態で初期化
        for (Integer userId : participants) {
            playerAlive.put(userId, true);
        }
    }
    
    // Getters and Setters
    public Integer getThreadId() {
        return threadId;
    }
    
    public Integer getGameMasterId() {
        return gameMasterId;
    }
    
    public List<Integer> getParticipants() {
        return participants;
    }
    
    public Phase getCurrentPhase() {
        return currentPhase;
    }
    
    public void setCurrentPhase(Phase currentPhase) {
        this.currentPhase = currentPhase;
    }
    
    public Integer getWerewolfCount() {
        return werewolfCount;
    }
    
    public void setWerewolfCount(Integer werewolfCount) {
        this.werewolfCount = werewolfCount;
    }
    
    public Integer getDiscussionTimeMinutes() {
        return discussionTimeMinutes;
    }
    
    public void setDiscussionTimeMinutes(Integer discussionTimeMinutes) {
        this.discussionTimeMinutes = discussionTimeMinutes;
    }
    
    public boolean isHasSpecialRoles() {
        return hasSpecialRoles;
    }
    
    public void setHasSpecialRoles(boolean hasSpecialRoles) {
        this.hasSpecialRoles = hasSpecialRoles;
    }
    
    public String getSetupStep() {
        return setupStep;
    }
    
    public void setSetupStep(String setupStep) {
        this.setupStep = setupStep;
    }
    
    public Map<Integer, Role> getPlayerRoles() {
        return playerRoles;
    }
    
    public Map<Integer, Boolean> getPlayerAlive() {
        return playerAlive;
    }
    
    public int getCurrentCycle() {
        return currentCycle;
    }
    
    public void setCurrentCycle(int currentCycle) {
        this.currentCycle = currentCycle;
    }
    
    public Map<Integer, Integer> getNightActions() {
        return nightActions;
    }

    public Integer getLastExecutedUserId() {
        return lastExecutedUserId;
    }

    public void setLastExecutedUserId(Integer lastExecutedUserId) {
        this.lastExecutedUserId = lastExecutedUserId;
    }

    public Integer getLastKilledUserId() {
        return lastKilledUserId;
    }

    public void setLastKilledUserId(Integer lastKilledUserId) {
        this.lastKilledUserId = lastKilledUserId;
    }

    public Integer getLastProtectedUserId() {
        return lastProtectedUserId;
    }

    public void setLastProtectedUserId(Integer lastProtectedUserId) {
        this.lastProtectedUserId = lastProtectedUserId;
    }
    
    public int getParticipantCount() {
        return participants.size();
    }
    
    public int getAliveCount() {
        return (int) playerAlive.values().stream().filter(alive -> alive).count();
    }
    
    public int getAliveWerewolfCount() {
        return (int) playerRoles.entrySet().stream()
            .filter(e -> e.getValue() == Role.WEREWOLF && playerAlive.get(e.getKey()))
            .count();
    }
    
    public int getAliveVillagerCount() {
        return (int) playerRoles.entrySet().stream()
            .filter(e -> e.getValue() != Role.WEREWOLF && playerAlive.get(e.getKey()))
            .count();
    }
    
    public Role getPlayerRole(Integer userId) {
        return playerRoles.get(userId);
    }
    
    public boolean isPlayerAlive(Integer userId) {
        return playerAlive.getOrDefault(userId, false);
    }
    
    public void killPlayer(Integer userId) {
        playerAlive.put(userId, false);
    }
}
