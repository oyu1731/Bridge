package com.bridge.backend.service;

import com.bridge.backend.model.WerewolfGame;
import com.bridge.backend.model.WerewolfGame.Phase;
import com.bridge.backend.model.WerewolfGame.Role;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 人狼ゲームの状態とフローを管理するサービス
 */
@Service
public class WerewolfGameService {
    
    // threadId -> WerewolfGame
    private final Map<Integer, WerewolfGame> games = new ConcurrentHashMap<>();
    
    /**
     * 新しいゲームを開始（既に存在する場合は既存のものを返す）
     */
    public WerewolfGame startGame(Integer threadId, Integer gameMasterId, List<Integer> participants) {
        // 既にゲームが存在する場合は既存のものを返す
        WerewolfGame existingGame = games.get(threadId);
        if (existingGame != null) {
            System.out.println("[ゲーム作成] 既存ゲームを返す: threadId=" + threadId + ", GM=" + existingGame.getGameMasterId());
            return existingGame;
        }
        
        // 新規作成
        System.out.println("[ゲーム作成] 新規作成: threadId=" + threadId + ", GM=" + gameMasterId + ", participants=" + participants);
        WerewolfGame game = new WerewolfGame(threadId, gameMasterId, participants);
        games.put(threadId, game);
        return game;
    }
    
    /**
     * ゲーム情報を取得
     */
    public WerewolfGame getGame(Integer threadId) {
        return games.get(threadId);
    }
    
    /**
     * ゲームマスターかどうか確認
     */
    public boolean isGameMaster(Integer threadId, Integer userId) {
        WerewolfGame game = games.get(threadId);
        return game != null && game.getGameMasterId().equals(userId);
    }
    
    /**
     * ルール設定のステップを処理
     * @return 次のボットメッセージ
     */
    public String processSetupStep(Integer threadId, String userInput) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            return "ゲームが見つかりません";
        }
        
        String currentStep = game.getSetupStep();
        
        switch (currentStep) {
            case "werewolf_count":
                return handleWerewolfCountInput(game, userInput);
            case "discussion_time":
                return handleDiscussionTimeInput(game, userInput);
            case "special_roles":
                return handleSpecialRolesInput(game, userInput);
            case "complete":
                return "設定が完了しました。ゲームを開始します...";
            default:
                return "不明なステップです";
        }
    }
    
    /**
     * 人狼の人数の入力を処理
     */
    private String handleWerewolfCountInput(WerewolfGame game, String input) {
        try {
            int count = Integer.parseInt(input.trim());
            int playerCount = game.getParticipantCount();
            
            // 5人以下の場合は自動で1人
            if (playerCount <= 5) {
                game.setWerewolfCount(1);
                game.setSetupStep("discussion_time");
                return "参加者が5人以下のため、人狼の人数は自動的に1人に設定されました。\n\n昼の議論時間を設定してください（1～10分）";
            }
            
            // バリデーション
            if (count < 1 || count >= playerCount) {
                return "人狼の人数は1人以上、参加者数未満である必要があります。もう一度入力してください。";
            }
            
            game.setWerewolfCount(count);
            game.setSetupStep("discussion_time");
            return String.format("人狼の人数を%d人に設定しました。\n\n昼の議論時間を設定してください（1～10分）", count);
            
        } catch (NumberFormatException e) {
            return "数字を入力してください。";
        }
    }
    
    /**
     * 議論時間の入力を処理
     */
    private String handleDiscussionTimeInput(WerewolfGame game, String input) {
        try {
            int minutes = Integer.parseInt(input.trim());
            
            // バリデーション
            if (minutes < 1 || minutes > 10) {
                return "議論時間は1～10分の範囲で入力してください。";
            }
            
            game.setDiscussionTimeMinutes(minutes);
            
            // 5人以上の場合のみ特殊役職の設定を聞く
            if (game.getParticipantCount() >= 5) {
                game.setSetupStep("special_roles");
                return String.format("議論時間を%d分に設定しました。\n\n特殊役職を使用しますか？（有 または 無）", minutes);
            } else {
                // 4人以下は強制的に特殊役職なし
                game.setHasSpecialRoles(false);
                game.setSetupStep("complete");
                return completeSetup(game);
            }
            
        } catch (NumberFormatException e) {
            return "数字を入力してください。";
        }
    }
    
    /**
     * 特殊役職の有無の入力を処理
     */
    private String handleSpecialRolesInput(WerewolfGame game, String input) {
        String trimmed = input.trim();
        
        if (trimmed.equals("有") || trimmed.equalsIgnoreCase("yes") || trimmed.equals("y")) {
            game.setHasSpecialRoles(true);
            game.setSetupStep("complete");
            return completeSetup(game);
        } else if (trimmed.equals("無") || trimmed.equalsIgnoreCase("no") || trimmed.equals("n")) {
            game.setHasSpecialRoles(false);
            game.setSetupStep("complete");
            return completeSetup(game);
        } else {
            return "「有」または「無」で答えてください。";
        }
    }
    
    /**
     * 設定完了時の処理
     */
    private String completeSetup(WerewolfGame game) {
        StringBuilder sb = new StringBuilder();
        sb.append("=== ゲーム設定完了 ===\n");
        sb.append(String.format("・参加者数: %d人\n", game.getParticipantCount()));
        sb.append(String.format("・人狼の人数: %d人\n", game.getWerewolfCount() != null ? game.getWerewolfCount() : 1));
        sb.append(String.format("・議論時間: %d分\n", game.getDiscussionTimeMinutes()));
        sb.append(String.format("・特殊役職: %s\n", game.isHasSpecialRoles() ? "有" : "無"));
        sb.append("\nこれから役職を配分します...");
        
        return sb.toString();
    }
    
    /**
     * 最初のボットメッセージを取得
     * @param isGameMaster ゲームマスターかどうか
     */
    public String getInitialBotMessage(Integer threadId, boolean isGameMaster) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            return "ゲームが見つかりません";
        }
        
        int playerCount = game.getParticipantCount();
        
        // 非GMの場合は待機メッセージ
        if (!isGameMaster) {
            return "人狼ゲームを開始します。\n\nゲームマスターがルールを設定しています...\nしばらくお待ちください。";
        }
        
        // GMの場合は設定メッセージ
        if (playerCount <= 5) {
            return String.format("人狼ゲームを開始します。\n参加者は%d人です。\n\n5人以下のため、人狼の人数は自動的に1人に設定されました。\n\n昼の議論時間を設定してください（1～10分）", playerCount);
        } else {
            return String.format("人狼ゲームを開始します。\n参加者は%d人です。\n\n人狼の人数を設定してください（1～%d人）", playerCount, playerCount - 1);
        }
    }
    
    /**
     * ゲームを削除
     */
    public void deleteGame(Integer threadId) {
        games.remove(threadId);
    }

    /**
     * 非アクティブなプレイヤーを静観状態にする
     */
    public void markPlayerInactive(Integer threadId, Integer userId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            throw new RuntimeException("ゲームが見つかりません");
        }
        game.killPlayer(userId);
        System.out.println("[非アクティブ] threadId=" + threadId + ", userId=" + userId);
    }

    /**
     * ゲームを強制終了
     */
    public void forceEndGame(Integer threadId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            throw new RuntimeException("ゲームが見つかりません");
        }
        game.setCurrentPhase(Phase.ENDED);
        System.out.println("[強制終了] threadId=" + threadId);
    }
    
    /**
     * 役職を配分してゲームを開始
     */
    public void assignRolesAndStart(Integer threadId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            throw new RuntimeException("ゲームが見つかりません");
        }
        
        List<Integer> players = new ArrayList<>(game.getParticipants());
        Collections.shuffle(players); // ランダムに並び替え
        
        Map<Integer, Role> roles = new HashMap<>();
        int index = 0;
        
        // 人狼を配分
        int werewolfCount = game.getWerewolfCount() != null ? game.getWerewolfCount() : 1;
        for (int i = 0; i < werewolfCount && index < players.size(); i++) {
            roles.put(players.get(index++), Role.WEREWOLF);
        }
        
        // 特殊役職を配分（7人以下の場合は占い師のみ）
        if (game.isHasSpecialRoles() && index < players.size()) {
            // 占い師（必須）
            roles.put(players.get(index++), Role.SEER);
            
            // 8人以上の場合のみ騎士と霊媒師を追加
            if (players.size() >= 8 && index < players.size()) {
                roles.put(players.get(index++), Role.KNIGHT);
            }
            if (players.size() >= 8 && index < players.size()) {
                roles.put(players.get(index++), Role.MEDIUM);
            }
        }
        
        // 残りは村人
        while (index < players.size()) {
            roles.put(players.get(index++), Role.VILLAGER);
        }
        
        game.getPlayerRoles().putAll(roles);
        game.setCurrentPhase(Phase.NIGHT);
        game.setCurrentCycle(1);
        
        System.out.println("[役職配分] threadId=" + threadId + ", roles=" + roles);
    }
    
    /**
     * 各プレイヤーの役職通知メッセージを取得
     */
    public String getRoleNotificationMessage(Integer threadId, Integer userId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            return null;
        }
        
        Role role = game.getPlayerRole(userId);
        if (role == null) {
            return null;
        }
        
        StringBuilder sb = new StringBuilder();
        sb.append("=== あなたの役職 ===\n");
        
        switch (role) {
            case WEREWOLF:
                sb.append("🐺 人狼\n\n");
                sb.append("あなたは人狼です。\n");
                sb.append("夜のフェーズで村人を襲撃できます。\n");
                
                // 仲間の人狼を表示
                List<Integer> werewolves = game.getPlayerRoles().entrySet().stream()
                    .filter(e -> e.getValue() == Role.WEREWOLF && !e.getKey().equals(userId))
                    .map(Map.Entry::getKey)
                    .toList();
                if (!werewolves.isEmpty()) {
                    sb.append("\n仲間の人狼: ");
                    sb.append("ユーザーID " + String.join(", ", werewolves.stream().map(String::valueOf).toList()));
                }
                break;
                
            case SEER:
                sb.append("🔮 占い師\n\n");
                sb.append("あなたは占い師です。\n");
                sb.append("夜のフェーズで1人のプレイヤーを占い、その役職を知ることができます。");
                break;
                
            case KNIGHT:
                sb.append("🛡️ 騎士\n\n");
                sb.append("あなたは騎士です。\n");
                sb.append("夜のフェーズで1人のプレイヤーを護衛し、人狼の襲撃から守ることができます。");
                break;
                
            case MEDIUM:
                sb.append("👻 霊媒師\n\n");
                sb.append("あなたは霊媒師です。\n");
                sb.append("夜のフェーズで前日に処刑されたプレイヤーが人狼かどうかを知ることができます。");
                break;
                
            case VILLAGER:
            default:
                sb.append("👤 村人\n\n");
                sb.append("あなたは村人です。\n");
                sb.append("特殊能力はありませんが、議論と投票で人狼を見つけ出しましょう。");
                break;
        }
        
        return sb.toString();
    }
    
    /**
     * 夜の行動を記録
     */
    public void recordNightAction(Integer threadId, Integer userId, Integer targetUserId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            throw new RuntimeException("ゲームが見つかりません");
        }
        
        game.getNightActions().put(userId, targetUserId);
        System.out.println("[夜行動] threadId=" + threadId + ", userId=" + userId + " -> targetUserId=" + targetUserId);
    }

    /**
     * 占い師の結果メッセージを取得
     */
    public String getSeerResultMessage(Integer threadId, Integer seerId, Integer targetUserId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            return null;
        }
        if (game.getPlayerRole(seerId) != Role.SEER) {
            return null;
        }
        Role targetRole = game.getPlayerRole(targetUserId);
        if (targetRole == null) {
            return null;
        }
        String isWerewolf = targetRole == Role.WEREWOLF ? "人狼" : "人狼ではない";
        return String.format("🔮 占い結果: ユーザーID %d は %s です。", targetUserId, isWerewolf);
    }

    /**
     * 騎士の護衛メッセージを取得
     */
    public String getKnightResultMessage(Integer threadId, Integer knightId, Integer targetUserId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            return null;
        }
        if (game.getPlayerRole(knightId) != Role.KNIGHT) {
            return null;
        }
        return String.format("🛡️ 護衛対象: ユーザーID %d を護衛しました。", targetUserId);
    }

    /**
     * 霊媒師の結果メッセージを取得
     */
    public String getMediumResultMessage(Integer threadId, Integer mediumId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            return null;
        }
        if (game.getPlayerRole(mediumId) != Role.MEDIUM) {
            return null;
        }
        Integer lastExecuted = game.getLastExecutedUserId();
        if (lastExecuted == null) {
            return "👻 霊媒結果: まだ処刑者がいません。";
        }
        Role targetRole = game.getPlayerRole(lastExecuted);
        if (targetRole == null) {
            return null;
        }
        String isWerewolf = targetRole == Role.WEREWOLF ? "人狼" : "人狼ではない";
        return String.format("👻 霊媒結果: ユーザーID %d は %s です。", lastExecuted, isWerewolf);
    }
    
    /**
     * 全員が夜の行動を完了したか確認
     */
    public boolean isNightComplete(Integer threadId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            return false;
        }
        
        // 1日目の夜は人狼は襲撃しない（仲間確認のみ）
        if (game.getCurrentCycle() == 1) {
            // 占い師、騎士がいる場合はその行動が必要
            for (Map.Entry<Integer, Role> entry : game.getPlayerRoles().entrySet()) {
                if (!game.isPlayerAlive(entry.getKey())) continue;
                
                Role role = entry.getValue();
                if (role == Role.SEER || role == Role.KNIGHT) {
                    if (!game.getNightActions().containsKey(entry.getKey())) {
                        return false;
                    }
                }
            }
            return true;
        }
        
        // 2日目以降：人狼、占い師、騎士、霊媒師の行動が必要
        for (Map.Entry<Integer, Role> entry : game.getPlayerRoles().entrySet()) {
            if (!game.isPlayerAlive(entry.getKey())) continue;
            
            Role role = entry.getValue();
            if (role == Role.WEREWOLF || role == Role.SEER || 
                role == Role.KNIGHT || role == Role.MEDIUM) {
                if (!game.getNightActions().containsKey(entry.getKey())) {
                    return false;
                }
            }
        }
        return true;
    }
    
    /**
     * 夜の処理を実行（襲撃、占い、護衛）
     * @return 結果メッセージ
     */
    public String executeNightPhase(Integer threadId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            throw new RuntimeException("ゲームが見つかりません");
        }
        
        // 1日目は襲撃なし
        if (game.getCurrentCycle() == 1) {
            game.getNightActions().clear();
            game.setLastKilledUserId(null);
            game.setCurrentPhase(Phase.DISCUSSION);
            return "1日目の夜が明けました。議論を開始してください。";
        }
        
        // 人狼の襲撃対象を決定（複数いる場合は多数決、同数ならランダム）
        Map<Integer, Long> attackVotes = game.getNightActions().entrySet().stream()
            .filter(e -> game.getPlayerRole(e.getKey()) == Role.WEREWOLF)
            .collect(java.util.stream.Collectors.groupingBy(Map.Entry::getValue, java.util.stream.Collectors.counting()));
        
        Integer attackTarget = null;
        if (!attackVotes.isEmpty()) {
            long maxVotes = Collections.max(attackVotes.values());
            List<Integer> candidates = attackVotes.entrySet().stream()
                .filter(e -> e.getValue() == maxVotes)
                .map(Map.Entry::getKey)
                .toList();
            attackTarget = candidates.get(new Random().nextInt(candidates.size()));
        }
        
        // 騎士の護衛対象
        Integer protectedTarget = game.getNightActions().entrySet().stream()
            .filter(e -> game.getPlayerRole(e.getKey()) == Role.KNIGHT)
            .map(Map.Entry::getValue)
            .findFirst()
            .orElse(null);
        
        // 襲撃実行
        StringBuilder result = new StringBuilder();
        result.append("夜が明けました。\n\n");
        
        game.setLastKilledUserId(null);
        if (attackTarget != null) {
            if (attackTarget.equals(protectedTarget)) {
                result.append("昨夜、誰も死にませんでした。\n（騎士の護衛が成功しました）");
            } else {
                game.killPlayer(attackTarget);
                game.setLastKilledUserId(attackTarget);
                result.append(String.format("ユーザーID %d が人狼に襲撃されました。", attackTarget));
            }
        } else {
            result.append("昨夜、誰も死にませんでした。");
        }
        
        game.getNightActions().clear();

        // 勝敗判定（夜襲撃で決着する場合）
        String winner = checkWinner(threadId);
        if (winner != null) {
            game.setCurrentPhase(Phase.ENDED);
            result.append("\n\nゲーム終了: ")
                  .append("villager".equals(winner) ? "村人陣営の勝利" : "人狼陣営の勝利");
        } else {
            game.setCurrentPhase(Phase.DISCUSSION);
        }

        return result.toString();
    }
    
    /**
     * 勝敗判定
     * @return 勝者（"werewolf", "villager", null=継続）
     */
    public String checkWinner(Integer threadId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            return null;
        }
        
        int aliveWerewolves = game.getAliveWerewolfCount();
        int aliveVillagers = game.getAliveVillagerCount();
        
        if (aliveWerewolves == 0) {
            return "villager";
        }
        if (aliveWerewolves >= aliveVillagers) {
            return "werewolf";
        }
        return null;
    }
    
    /**
     * 投票を記録
     */
    private Map<Integer, Map<Integer, Integer>> votes = new ConcurrentHashMap<>(); // threadId -> (voterId -> targetId)
    
    public void recordVote(Integer threadId, Integer voterId, Integer targetId) {
        votes.computeIfAbsent(threadId, k -> new HashMap<>()).put(voterId, targetId);
        System.out.println("[投票] threadId=" + threadId + ", voter=" + voterId + " -> target=" + targetId);
    }
    
    /**
     * 全員が投票したか確認
     */
    public boolean isVoteComplete(Integer threadId) {
        WerewolfGame game = games.get(threadId);
        if (game == null) {
            return false;
        }
        
        Map<Integer, Integer> threadVotes = votes.get(threadId);
        if (threadVotes == null) {
            return false;
        }
        
        // 生存しているプレイヤー全員が投票したか
        for (Integer userId : game.getParticipants()) {
            if (game.isPlayerAlive(userId) && !threadVotes.containsKey(userId)) {
                return false;
            }
        }
        return true;
    }
    
    /**
     * 投票を集計して処刑を実行
     * @return 処刑されたプレイヤーのID
     */
    public Integer executeVoting(Integer threadId) {
        WerewolfGame game = games.get(threadId);
        Map<Integer, Integer> threadVotes = votes.get(threadId);
        
        if (game == null || threadVotes == null) {
            return null;
        }
        
        // 得票数を集計
        Map<Integer, Long> voteCount = threadVotes.values().stream()
            .collect(java.util.stream.Collectors.groupingBy(id -> id, java.util.stream.Collectors.counting()));
        
        // 最多得票者を決定（同数の場合はランダム）
        long maxVotes = Collections.max(voteCount.values());
        List<Integer> candidates = voteCount.entrySet().stream()
            .filter(e -> e.getValue() == maxVotes)
            .map(Map.Entry::getKey)
            .toList();
        
        Integer executed = candidates.get(new Random().nextInt(candidates.size()));
        game.killPlayer(executed);
        game.setLastExecutedUserId(executed);
        
        // 投票をクリア
        votes.remove(threadId);
        
        // 次のサイクルへ
        game.setCurrentCycle(game.getCurrentCycle() + 1);
        game.setCurrentPhase(Phase.NIGHT);
        
        System.out.println("[処刑] threadId=" + threadId + ", executed=" + executed);
        return executed;
    }
}
