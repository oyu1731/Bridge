import 'package:flutter/material.dart';

/// プレイヤー選択ウィジェット
/// 占い師、騎士、人狼の夜フェーズや投票フェーズで使用
class PlayerSelectionWidget extends StatefulWidget {
  final List<Map<String, dynamic>> players; // プレイヤーリスト {userId, nickname, isAlive}
  final String title; // 選択画面のタイトル
  final String? description; // 説明文
  final Function(int selectedUserId) onPlayerSelected; // 選択完了コールバック
  final int? currentUserId; // 現在のユーザー（自分自身を除外する場合に使用）
  final bool canSelectSelf; // 自分自身を選択可能か
  
  const PlayerSelectionWidget({
    required this.players,
    required this.title,
    required this.onPlayerSelected,
    this.description,
    this.currentUserId,
    this.canSelectSelf = false,
    Key? key,
  }) : super(key: key);
  
  @override
  _PlayerSelectionWidgetState createState() => _PlayerSelectionWidgetState();
}

class _PlayerSelectionWidgetState extends State<PlayerSelectionWidget> {
  int? _selectedUserId;
  
  @override
  Widget build(BuildContext context) {
    // 生存者のみをフィルタリング
    final alivePlayers = widget.players
        .where((p) => p['isAlive'] == true)
        .toList();
    
    // 自分自身を除外する場合
    final selectablePlayers = widget.canSelectSelf
        ? alivePlayers
        : alivePlayers.where((p) => p['userId'] != widget.currentUserId).toList();
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // タイトル
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (widget.description != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // プレイヤーリスト
          ...selectablePlayers.map((player) {
            final userId = player['userId'] as int;
            final nickname = player['nickname'] as String;
            final isSelected = _selectedUserId == userId;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedUserId = userId;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          nickname,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          
          const SizedBox(height: 16),
          
          // 確定ボタン
          ElevatedButton(
            onPressed: _selectedUserId != null
                ? () {
                    widget.onPlayerSelected(_selectedUserId!);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '決定',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
