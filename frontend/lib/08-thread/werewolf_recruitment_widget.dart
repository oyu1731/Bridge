import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show window, document, Event, HttpRequest;
import 'package:bridge/EX-werewolf/werewolf_game_screen.dart';

/// 人狼ゲーム募集チャット用ウィジェット
class WerewolfRecruitmentWidget extends StatefulWidget {
  final Map<String, dynamic> message;
  final String currentUserId;
  final VoidCallback onRecruitmentEnd;

  const WerewolfRecruitmentWidget({
    required this.message,
    required this.currentUserId,
    required this.onRecruitmentEnd,
    Key? key,
  }) : super(key: key);

  @override
  _WerewolfRecruitmentWidgetState createState() =>
      _WerewolfRecruitmentWidgetState();
}

class _WerewolfRecruitmentWidgetState
    extends State<WerewolfRecruitmentWidget> {
  static const int MIN_PLAYERS = 3;  // ゲーム開始に必要な最小人数
  static final Set<int> _endedRecruitments = {};  // 終了済み募集のchatIdを保存
  
  bool isActive = true;
  int participantCount = 0;
  int remainingSeconds = 120;
  bool isParticipating = false;
  bool isHost = false;
  Timer? _timer;
  Timer? _countdownTimer;
  Timer? _visibilityTimer;  // 非表示状態監視用タイマー
  DateTime? _becameHiddenAt;  // 非表示になった時刻

  @override
  void initState() {
    super.initState();
    isHost = widget.message['user_id'] == widget.currentUserId;
    _fetchRecruitmentStatus();
    _startCountdown();
    _startPolling();
    
    // Webの場合、複数のページ離脱イベントを監視
    if (kIsWeb) {
      html.window.addEventListener('beforeunload', _handleBeforeUnload);
      html.window.addEventListener('pagehide', _handlePageHide);
      html.document.addEventListener('visibilitychange', _handleVisibilityChange);
    }
  }

  @override
  void dispose() {
    print("========================================");
    print("dispose()呼び出し");
    print("isParticipating=$isParticipating, isActive=$isActive");
    print("========================================");
    
    _timer?.cancel();
    _countdownTimer?.cancel();
    _visibilityTimer?.cancel();
    
    // 全てのイベントリスナーを削除
    if (kIsWeb) {
      html.window.removeEventListener('beforeunload', _handleBeforeUnload);
      html.window.removeEventListener('pagehide', _handlePageHide);
      html.document.removeEventListener('visibilitychange', _handleVisibilityChange);
    }
    
    // 参加中の場合は自動的に参加取り消し（同期的に送信）
    if (isParticipating && isActive) {
      print("dispose内で参加取り消しを実行します");
      _leaveRecruitmentAsync();
    } else {
      print("dispose内での参加取り消しはスキップ（参加していないか募集終了済み）");
    }
    
    super.dispose();
  }
  
  /// beforeunloadイベントハンドラ
  void _handleBeforeUnload(html.Event event) {
    print("beforeunloadイベント発火: isParticipating=$isParticipating, isActive=$isActive");
    if (isParticipating && isActive) {
      print("beforeunloadで参加取り消しを実行します");
      _leaveRecruitmentAsync();
    }
  }
  
  /// pagehideイベントハンドラ（ページが完全にアンロードされる直前）
  void _handlePageHide(html.Event event) {
    print("pagehideイベント発火: isParticipating=$isParticipating, isActive=$isActive");
    if (isParticipating && isActive) {
      print("pagehideで参加取り消しを実行します");
      _leaveRecruitmentAsync();
    }
  }
  
  /// visibilitychangeイベントハンドラ（ページが非表示になったとき）
  void _handleVisibilityChange(html.Event event) {
    if (html.document.hidden == true) {
      // ページが非表示になったとき
      print("ページが非表示になりました: isParticipating=$isParticipating, isActive=$isActive");
      
      // 参加中かつ募集がアクティブな場合、3秒後に離脱処理を実行
      if (isParticipating && isActive) {
        _becameHiddenAt = DateTime.now();
        print("3秒後に自動離脱チェックを開始します");
        
        _visibilityTimer?.cancel();
        _visibilityTimer = Timer(const Duration(seconds: 3), () {
          // 3秒後もまだ非表示なら離脱処理を実行
          if (html.document.hidden == true && isParticipating && isActive) {
            print("3秒間非表示が継続 → 自動離脱処理を実行");
            _leaveRecruitmentAsync();
            
            // 状態を更新
            if (mounted) {
              setState(() {
                isParticipating = false;
              });
            }
          } else {
            print("3秒以内に再表示されたか、既に離脱済み");
          }
        });
      }
    } else {
      // ページが再表示されたとき
      _visibilityTimer?.cancel();
      _becameHiddenAt = null;
      
      // すぐに戻ってきた場合は離脱処理をキャンセル
      print("ページが再表示されました - 自動離脱をキャンセル");
      
      if (isActive) {
        _fetchRecruitmentStatus();
      }
    }
  }

  /// 募集状態を取得
  Future<void> _fetchRecruitmentStatus() async {
    try {
      final chatId = widget.message['id'];
      print("人狼募集状態取得開始: chatId=$chatId");
      final response = await http.get(
        Uri.parse(ApiConfig.werewolfRecruitmentUrl(chatId)),
      );

      print("人狼募集状態取得レスポンス: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("人狼募集データ: $data");
        
        final fetchedIsActive = data['isActive'] ?? false;
        final chatId = widget.message['id'] as int;
        
        if (mounted) {
          setState(() {
            isActive = fetchedIsActive;
            participantCount = data['participantCount'] ?? 0;
            remainingSeconds = data['remainingSeconds'] ?? 0;
            
            final participants = List<int>.from(data['participants'] ?? []);
            isParticipating = participants.contains(
              int.tryParse(widget.currentUserId) ?? 0,
            );
            print("参加状態: isParticipating=$isParticipating, count=$participantCount");
          });
        }

        // 募集終了時の処理（サーバー側でisActive=falseになった場合）
        if (!fetchedIsActive || remainingSeconds <= 0) {
          if (!_endedRecruitments.contains(chatId)) {  // まだ終了処理をしていない場合のみ
            print("募集終了を検出 - _handleRecruitmentEndを呼び出します");
            final canStartGame = data['canStartGame'] ?? false;
            _handleRecruitmentEnd(
              canStartGame: canStartGame, 
              participantCount: participantCount,
            );
          } else {
            print("募集終了済み - _handleRecruitmentEndをスキップ (chatId=$chatIdは終了済み)");
          }
        }
      } else if (response.statusCode == 404) {
        print("募集が見つかりません（404）- ポーリング停止");
        // 募集が存在しない場合はポーリングを停止
        _timer?.cancel();
        _countdownTimer?.cancel();
        if (mounted) {
          setState(() {
            isActive = false;
          });
        }
      } else {
        print("募集状態取得失敗: ${response.statusCode}, body: ${response.body}");
      }
    } catch (e) {
      print("募集状態の取得エラー: $e");
    }
  }

  /// カウントダウンタイマー
  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            remainingSeconds--;
          });
        }
      } else {
        timer.cancel();
        if (isHost && isActive) {
          _endRecruitment();
        }
      }
    });
  }

  /// ポーリングで状態を定期更新
  void _startPolling() {
    final chatId = widget.message['id'] as int;
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (isActive && !_endedRecruitments.contains(chatId)) {
        _fetchRecruitmentStatus();
      } else {
        timer.cancel();
      }
    });
  }

  /// 参加する
  Future<void> _joinRecruitment() async {
    try {
      final chatId = widget.message['id'];
      final threadId = widget.message['thread_id'];
      print("人狼募集参加開始: chatId=$chatId, userId=${widget.currentUserId}, threadId=$threadId");
      final response = await http.post(
        Uri.parse(ApiConfig.werewolfJoinUrl(chatId)),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': int.parse(widget.currentUserId),
          'threadId': threadId,
        }),
      );

      print("人狼募集参加レスポンス: ${response.statusCode}, body: ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && mounted) {
          setState(() {
            isParticipating = true;
            participantCount = data['participantCount'] ?? participantCount;
          });
        }
      }
    } catch (e) {
      print("参加エラー: $e");
    }
  }

  /// 参加取り消し（非同期送信 - ページ離脱時用）
  Future<void> _leaveRecruitmentAsync() async {
    try {
      final chatId = widget.message['id'];
      final userId = int.parse(widget.currentUserId);
      print("========================================");
      print("人狼募集参加取り消し開始");
      print("chatId=$chatId, userId=$userId");
      print("========================================");
      
      final url = ApiConfig.werewolfLeaveUrl(chatId);
      print("URL: $url");
      
      // 非同期HTTPリクエストを使用（awaitしない = fire-and-forget）
      http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      ).then((response) {
        print("参加取り消しレスポンス: ${response.statusCode}");
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['hostLeft'] == true) {
            print("主催者が離脱したため募集が終了しました");
          }
        }
      }).catchError((error) {
        print("参加取り消しエラー: $error");
      });
      
      print("参加取り消しリクエスト送信完了");
      print("========================================");
      
      // 状態を即座に更新
      if (mounted) {
        setState(() {
          isParticipating = false;
        });
      }
    } catch (e) {
      print("同期参加取り消しエラー: $e");
    }
  }
  
  /// 参加取り消し
  Future<void> _leaveRecruitment() async {
    try {
      final chatId = widget.message['id'];
      print("人狼募集参加取り消し: chatId=$chatId, userId=${widget.currentUserId}");
      final response = await http.post(
        Uri.parse(ApiConfig.werewolfLeaveUrl(chatId)),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': int.parse(widget.currentUserId),
        }),
      );

      print("人狼募集参加取り消しレスポンス: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 主催者が離脱した場合
        if (data['hostLeft'] == true) {
          print("主催者が離脱 - 募集終了");
          if (mounted) {
            setState(() {
              isActive = false;
              isParticipating = false;
            });
          }
          widget.onRecruitmentEnd();
          return;
        }
        
        // 通常の参加取り消し
        if (data['success'] && mounted) {
          setState(() {
            isParticipating = false;
            participantCount = data['participantCount'] ?? participantCount;
          });
        }
      }
    } catch (e) {
      print("参加取り消しエラー: $e");
    }
  }

  /// 募集終了
  Future<void> _endRecruitment() async {
    try {
      final chatId = widget.message['id'];
      print("人狼募集終了開始: chatId=$chatId, userId=${widget.currentUserId}");
      final response = await http.post(
        Uri.parse(ApiConfig.werewolfEndUrl(chatId)),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': int.parse(widget.currentUserId),
        }),
      );

      print("人狼募集終了レスポンス: ${response.statusCode}, body: ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final canStartGame = data['canStartGame'] ?? false;
        final participantCount = data['participantCount'] ?? 0;
        
        _handleRecruitmentEnd(canStartGame: canStartGame, participantCount: participantCount);
      }
    } catch (e) {
      print("募集終了エラー: $e");
    }
  }

  /// 募集終了時の処理
  void _handleRecruitmentEnd({bool canStartGame = false, int participantCount = 0}) {
    final chatId = widget.message['id'] as int;
    print("_handleRecruitmentEnd呼び出し: chatId=$chatId, canStartGame=$canStartGame, participantCount=$participantCount");
    if (_endedRecruitments.contains(chatId)) {
      print("既に終了処理済み - 早期リターン");
      return; // 既に終了処理済みの場合は何もしない
    }
    _endedRecruitments.add(chatId); // 終了済みとしてマーク（同期的に設定）
    print("終了処理を実行します (chatId=$chatIdを終了済みセットに追加)");
    
    _timer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      isActive = false;
    });
    widget.onRecruitmentEnd();
    
    // チャットメッセージをデータベースから削除（非同期で実行するが待たない）
    _deleteRecruitmentMessage();
    
    // 参加者が3人以上の場合のみゲーム開始
    if (canStartGame && isParticipating) {
      _navigateToWerewolfGame();
    } else if (isParticipating && participantCount < MIN_PLAYERS) {
      // 参加者不足の通知
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("参加者が$MIN_PLAYERS人未満のため、ゲームは開始されませんでした"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// 人狼ゲーム画面へ遷移
  Future<void> _navigateToWerewolfGame() async {
    try {
      final chatId = widget.message['id'];
      final threadId = widget.message['thread_id'];
      
      print("人狼ゲーム開始処理: chatId=$chatId, threadId=$threadId");
      
      // 募集情報を取得して参加者リストを取得
      final recruitmentResponse = await http.get(
        Uri.parse(ApiConfig.werewolfRecruitmentUrl(chatId)),
      );
      
      if (recruitmentResponse.statusCode != 200) {
        throw Exception('募集情報の取得に失敗しました');
      }
      
      final recruitmentData = json.decode(recruitmentResponse.body);
      final participants = List<int>.from(recruitmentData['participants'] ?? []);
      final hostUserId = recruitmentData['hostUserId'];
      final currentUserIdInt = int.parse(widget.currentUserId);
      final isHost = hostUserId == currentUserIdInt;
      
      print("募集情報: hostUserId=$hostUserId, currentUserId=$currentUserIdInt, isHost=$isHost, participants=$participants");
      
      if (participants.length < MIN_PLAYERS) {
        throw Exception('参加者が不足しています');
      }
      
      // hostUserIdを必ず最初に配置（ゲームマスターになる）
      final sortedParticipants = <int>[];
      if (hostUserId != null && participants.contains(hostUserId)) {
        sortedParticipants.add(hostUserId);
        sortedParticipants.addAll(participants.where((id) => id != hostUserId));
      } else {
        sortedParticipants.addAll(participants);
      }
      
      print("ソート後のparticipants: $sortedParticipants (GM=${sortedParticipants.isNotEmpty ? sortedParticipants[0] : 'none'})");
      
      Map<String, dynamic>? gameThread;
      
      // ホストのみが専用スレッドを作成
      if (isHost) {
        print("🎮 ホストとして専用スレッドを作成開始...");
        
        // ローディング画面を表示
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _WerewolfLoadingScreen(
                message: 'ゲーム専用スレッドを作成中...',
              ),
            ),
          );
        }
        
        // 少し待機（UI表示のため）
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 人狼ゲーム専用スレッド（タイプ3）を作成
        final createThreadResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/threads'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'title': '人狼ゲーム実行中',
            'description': '人狼ゲーム専用スレッド',
            'type': 3, // 人狼ゲーム専用タイプ
            'user_id': currentUserIdInt,
          }),
        );
        
        print("スレッド作成レスポンス: statusCode=${createThreadResponse.statusCode}");
        
        if (createThreadResponse.statusCode != 200) {
          throw Exception('スレッドの作成に失敗しました: ${createThreadResponse.statusCode}');
        }
        
        gameThread = json.decode(createThreadResponse.body);
        final gameThreadId = gameThread!['id'];
        print("✅ 専用スレッド作成完了: threadId=$gameThreadId");
        
        // 作成したスレッドIDを募集データに保存
        final saveResponse = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/chat/werewolf/recruitment/$chatId/game-thread'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'gameThreadId': gameThreadId}),
        );
        
        print("📡 ゲームスレッドID保存レスポンス: status=${saveResponse.statusCode}, body=${saveResponse.body}");
        
        if (saveResponse.statusCode != 200) {
          print("⚠️ ゲームスレッドIDの保存に失敗: ${saveResponse.statusCode}");
        } else {
          print("✅ ゲームスレッドIDを募集に保存完了");
        }
      } else {
        // 非ホストはスレッドIDが保存されるまで待機
        print("⏳ 非ホスト: ゲームスレッドIDの取得を待機中...");
        
        // ローディング画面を表示
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _WerewolfLoadingScreen(
                message: 'ゲームマスターがスレッドを作成中...\nしばらくお待ちください',
              ),
            ),
          );
        }
        
        int retryCount = 0;
        const maxRetries = 20;
        
        while (retryCount < maxRetries) {
          await Future.delayed(const Duration(milliseconds: 500));
          
          final response = await http.get(
            Uri.parse(ApiConfig.werewolfRecruitmentUrl(chatId)),
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final gameThreadId = data['gameThreadId'];
            
            if (gameThreadId != null) {
              print("✅ ゲームスレッドID取得: $gameThreadId");
              
              // スレッド情報を構築（WerewolfGameScreenはidとtitleのみ使用）
              gameThread = {
                'id': gameThreadId,
                'title': '人狼ゲーム実行中',
                'type': 3,
                'description': '人狼ゲーム専用スレッド'
              };
              break;
            }
          }
          
          retryCount++;
          print("リトライ中... ($retryCount/$maxRetries)");
        }
        
        if (retryCount >= maxRetries) {
          throw Exception('ゲームスレッドIDの取得がタイムアウトしました');
        }
      }
      
      // gameThreadがnullの場合はエラー
      if (gameThread == null) {
        throw Exception('ゲームスレッドの取得に失敗しました');
      }
      
      print("🎮 ゲーム画面へ遷移: threadId=${gameThread!['id']}");
      
      // ローディング画面を閉じる（表示されている場合）
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // 少し待機してからゲーム画面へ遷移
      await Future.delayed(const Duration(milliseconds: 300));
      
      // ゲーム画面へ遷移
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WerewolfGameScreen(
              thread: gameThread!,
              participants: sortedParticipants,
              originThreadId: widget.message['thread_id'] != null
                  ? int.tryParse(widget.message['thread_id'].toString())
                  : null,
            ),
          ),
        );
      }
    } catch (e) {
      print("人狼ゲーム開始エラー: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ゲームの開始に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 募集メッセージをデータベースから削除（物理削除）
  Future<void> _deleteRecruitmentMessage() async {
    try {
      final chatId = widget.message['id'];
      print("人狼募集メッセージ削除開始: chatId=$chatId");
      final response = await http.delete(
        Uri.parse(ApiConfig.werewolfDeleteUrl(chatId)),
      );

      if (response.statusCode == 200) {
        print("人狼募集メッセージ削除成功: chatId=$chatId");
      } else {
        print("人狼募集メッセージ削除失敗: ${response.statusCode}, body: ${response.body}");
      }
    } catch (e) {
      print("募集メッセージ削除エラー: $e");
    }
  }

  /// 残り時間を表示形式に変換
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gamepad, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                '人狼ゲーム募集',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
              Spacer(),
              if (isActive)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '募集中',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '終了',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          if (isActive) ...[
            Row(
              children: [
                Icon(Icons.timer, size: 16),
                SizedBox(width: 4),
                Text(
                  '残り時間: ${_formatTime(remainingSeconds)}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16),
                SizedBox(width: 4),
                Text(
                  '参加者: $participantCount 人',
                  style: TextStyle(fontSize: 14),
                ),                SizedBox(width: 8),
                if (participantCount < MIN_PLAYERS)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Text(
                      "最低${MIN_PLAYERS}人必要",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),              ],
            ),
            SizedBox(height: 12),
            if (isHost)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _endRecruitment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('募集終了'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isParticipating ? _leaveRecruitment : _joinRecruitment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isParticipating ? Colors.grey : Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isParticipating ? '参加取り消し' : '参加する'),
                ),
              ),
          ] else ...[
            Text(
              '募集は終了しました',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 人狼ゲームスレッド作成中のローディング画面
class _WerewolfLoadingScreen extends StatelessWidget {
  final String message;
  
  const _WerewolfLoadingScreen({
    required this.message,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
