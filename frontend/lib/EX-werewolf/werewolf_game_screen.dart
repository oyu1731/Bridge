import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/08-thread/33-thread-unofficial-detail.dart';

/// 人狼ゲーム実行画面（スレッドタイプ3専用）
class WerewolfGameScreen extends StatefulWidget {
  final Map<String, dynamic> thread;
  final List<int> participants; // 参加者のuserIdリスト
  final int? originThreadId; // ゲーム終了後に戻る非公式スレッドID
  
  const WerewolfGameScreen({
    required this.thread,
    required this.participants,
    this.originThreadId,
    Key? key,
  }) : super(key: key);

  @override
  _WerewolfGameScreenState createState() => _WerewolfGameScreenState();
}

class _WerewolfGameScreenState extends State<WerewolfGameScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // ユーザー情報キャッシュ
  String? _currentUserIconUrl;
  final Map<String, String> _nicknameCache = {};
  final Map<String, String?> _userIconCache = {};
  final Map<String, String?> _userTypeCache = {};
  
  String currentUserId = "";
  bool _isUserLoaded = false;
  List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  bool _canSendMessage = true; // メッセージ送信可否フラグ
  
  late final StreamController<List<Map<String, dynamic>>> _messageStreamController;
  late final WebSocketChannel _channel;
  final String baseUrl = '${ApiConfig.baseUrl}/api';
  final String img_baseurl = '${ApiConfig.baseUrl}';
  
  // ゲーム状態
  String _gamePhase = 'SETUP'; // SETUP, NIGHT, DISCUSSION, VOTING, ENDED
  int _remainingSeconds = 0; // 議論時間の残り秒数
  Timer? _discussionTimer;
  bool _isGameMaster = false; // 自分がゲームマスターかどうか
  List<Map<String, dynamic>> _botMessages = []; // チャットボットメッセージ（DB保存しない）
  String _debugInfo = ''; // デバッグ情報（画面表示用）
  int _currentCycle = 0; // 現在のサイクル数（日数）
  Set<int> _aliveUserIds = <int>{};
  Set<int> _deadUserIds = <int>{};
  
  // 役職・プレイヤー情報
  String? _myRole; // 自分の役職
  bool _isAlive = true; // 自分の生存状態
  int? _selectedTarget; // 夜行動/投票で選択したターゲット
  bool _hasActedTonight = false; // 今夜の行動完了フラグ
  bool _hasVoted = false; // 投票完了フラグ
  Timer? _phaseCheckTimer; // フェーズ変更を定期的にチェック
  int _lastNightCompleteNotifiedCycle = -1; // NIGHT_COMPLETE通知済みサイクル
  bool _isFetchingMessages = false; // メッセージ取得中
  DateTime _lastActiveAt = DateTime.now();
  Timer? _inactivityTimer;
  bool _inactiveHandled = false;
  bool _endFlowScheduled = false; // 終了フロー二重実行防止
  
  @override
  void initState() {
    super.initState();
    print('========== WerewolfGameScreen initState開始 ==========');
    print('threadId: ${widget.thread['id']}');
    print('participants: ${widget.participants}');
    print('participants[0] (GMになるべき): ${widget.participants.isNotEmpty ? widget.participants[0] : "empty"}');
    
    _debugInfo = 'initState実行中 threadId=${widget.thread['id']}';
    
    _messageStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
    _loadCurrentUser(); // awaitは使えないので、内部で処理を完結させる
    _fetchMessages();
    for (final userId in widget.participants) {
      _loadUserInfo(userId.toString());
    }
    
    _channel = WebSocketChannel.connect(
      Uri.parse(ApiConfig.chatWebSocketUrl(widget.thread['id'])),
    );
    
    print('WebSocket接続開始');
    _debugInfo += '\nWebSocket接続中...';
    // initState内でsetStateを呼ぶのは非推奨なので削除
    
    _channel.stream.listen((data) async {
      try {
        final msg = Map<String, dynamic>.from(jsonDecode(data));
        
        // ゲームイベント（フェーズ変更など）を処理
        if (msg['type'] == 'GAME_EVENT') {
          print('🎮 ゲームイベント受信: ${msg['event']}');
          await _handleGameEvent(msg);
          return;
        }
        
        // 通常のチャットメッセージを処理
        final userId = (msg['userId'] ?? msg['user_id']).toString();
        await _loadUserInfo(userId);
        
        if (!_messages.any((m) => m['id'] == msg['id'])) {
          _messages.add({
            'id': msg['id'],
            'user_id': userId,
            'text': msg['text'] ?? msg['content'],
            'thread_id': msg['threadId'] ?? msg['thread_id'],
            'created_at': msg['createdAt'] ?? msg['created_at'],
            'photoId': msg['photoId'] ?? msg['photo_id'],
          });
          
          if (mounted) {
            setState(() {});
            _scrollToBottom();
          }
        }
      } catch (e) {
        print('WebSocketメッセージ処理エラー: $e');
      }
    });
    
    print("WebSocket connected to thread ${widget.thread['id']}");

    _startInactivityWatch();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageStreamController.close();
    _channel.sink.close();
    _discussionTimer?.cancel();
    _phaseCheckTimer?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startInactivityWatch() {
    _lastActiveAt = DateTime.now();
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final elapsed = DateTime.now().difference(_lastActiveAt).inSeconds;
      if (elapsed >= 180 && !_inactiveHandled && _isAlive) {
        _inactiveHandled = true;
        _handleInactivity();
      }
    });
  }

  void _registerActivity() {
    _lastActiveAt = DateTime.now();
  }

  Future<void> _handleInactivity() async {
    if (_isGameMaster) {
      await _forceEndGameDueToInactivity();
    } else {
      await _markSelfInactive();
    }
  }

  Future<void> _markSelfInactive() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/inactive'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': int.parse(currentUserId)}),
      );
      _sendGameEvent('PLAYER_INACTIVE', {
        'userId': int.parse(currentUserId),
      });
    } catch (e) {
      print('非アクティブ処理エラー: $e');
    }
  }

  Future<void> _forceEndGameDueToInactivity() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/force-end'),
      );
      _sendGameEvent('GAME_ENDED', {'winner': 'forced'});
    } catch (e) {
      print('強制終了エラー: $e');
    }
  }
  
  /// ユーザー情報を読み込み
  Future<void> _loadUserInfo(String userId) async {
    if (_nicknameCache.containsKey(userId)) return;
    
    final res = await http.get(Uri.parse('$baseUrl/chat/user/$userId'));
    if (res.statusCode != 200) return;
    
    final data = json.decode(res.body);
    _nicknameCache[userId] = data['nickname'] ?? 'Unknown';
    _userTypeCache[userId] = data['type']?.toString();
    
    final iconId = data['icon'];
    if (iconId != null) {
      final res2 = await http.get(Uri.parse('$baseUrl/photos/$iconId'));
      if (res2.statusCode == 200) {
        final path = json.decode(res2.body)['photoPath'];
        if (path != null && path.toString().isNotEmpty) {
          _userIconCache[userId] = "$img_baseurl$path";
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// ユーザーIDから表示名を取得
  Future<String> _getUserLabel(int userId) async {
    final key = userId.toString();
    if (!_nicknameCache.containsKey(key)) {
      await _loadUserInfo(key);
    }
    return _nicknameCache[key] ?? 'ユーザー $userId';
  }
  
  /// 現在のユーザー情報を読み込み
  Future<void> _loadCurrentUser() async {
    try {
      print('📍 _loadCurrentUser開始');
      setState(() => _debugInfo = '1.開始 userId=?');
      
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('current_user');
      if (jsonString == null) {
        print('❌ current_userがnull');
        setState(() => _debugInfo += '\n❌user=null');
        return;
      }
      
      final userData = jsonDecode(jsonString);
      currentUserId = userData['id'].toString();
      print('✅ currentUserId取得: $currentUserId');
      setState(() => _debugInfo += '\n2.userId=$currentUserId');
      
      final res = await http.get(Uri.parse('$baseUrl/chat/user/$currentUserId'));
      if (res.statusCode == 200) {
        final iconId = json.decode(res.body)['icon'];
        if (iconId != null) {
          final res2 = await http.get(Uri.parse('$baseUrl/photos/$iconId'));
          if (res2.statusCode == 200) {
            final path = json.decode(res2.body)['photoPath'];
            _currentUserIconUrl = "$img_baseurl$path";
          }
        }
      }
      print('✅ ユーザー情報取得完了');
      setState(() => _debugInfo += '\n3.情報取得OK');
      
      // まずゲーム作成を試みる（既に存在する場合はエラーになるが問題ない）
      print('📍 _tryInitializeGame呼び出し');
      setState(() => _debugInfo += '\n4.ゲーム作成試行');
      await _tryInitializeGame();
      print('✅ _tryInitializeGame完了');
      setState(() => _debugInfo += '\n5.作成完了');
      
      // ゲームマスターかチェック
      print('📍 _checkIfGameMaster呼び出し');
      setState(() => _debugInfo += '\n6.GMチェック開始');
      await _checkIfGameMaster();
      print('✅ _checkIfGameMaster完了');
      setState(() => _debugInfo += '\n7.GMチェック完了 isGM=$_isGameMaster');
      setState(() => _debugInfo += '\n8.botMsg数=${_botMessages.length}');
      
      setState(() {
        _isUserLoaded = true;
      });
      print('✅ _loadCurrentUser完了');
      setState(() => _debugInfo += '\n9.全完了');
    } catch (e, stackTrace) {
      print('❌❌❌ _loadCurrentUserでエラー発生: $e');
      print('スタックトレース: $stackTrace');
      setState(() {
        _debugInfo += '\n❌エラー: $e';
        _isUserLoaded = true; // エラーでも画面は表示
      });
    }
  }
  
  /// ゲーム初期化を試みる（最初の参加者のみが実行）
  Future<void> _tryInitializeGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson == null) return;
      
      final userData = jsonDecode(userJson);
      final userId = userData['id'];
      
      // 最初の参加者（募集の主催者）のみがゲームを作成
      final isFirstParticipant = widget.participants.isNotEmpty && widget.participants[0] == userId;
      
      if (!isFirstParticipant) {
        print('ゲーム作成スキップ: 最初の参加者ではない (userId=$userId, first=${widget.participants[0]})');
        return;
      }
      
      print('ゲーム作成開始: 最初の参加者として実行 (userId=$userId)');
      
      final response = await http.post(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gameMasterId': userId,
          'participants': widget.participants,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('ゲーム作成成功: $data');
      } else {
        print('ゲーム作成失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('ゲーム初期化エラー: $e');
    }
  }
  
  /// ゲームマスターかチェック
  Future<void> _checkIfGameMaster() async {
    const maxRetries = 15;
    const retryDelay = Duration(milliseconds: 1000);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // ゲーム作成後、少し待ってから取得
        if (attempt > 1) {
          await Future.delayed(retryDelay);
        } else {
          await Future.delayed(const Duration(milliseconds: 800));
        }
        
        final url = '$baseUrl/chat/werewolf/game/${widget.thread['id']}?userId=$currentUserId';
        print('ゲーム情報取得リクエスト (試行$attempt/$maxRetries): $url');
        
        final response = await http.get(Uri.parse(url));
        
        print('ゲーム情報取得レスポンス: statusCode=${response.statusCode}, body=${response.body}');
        
        if (response.statusCode == 404 && attempt < maxRetries) {
          print('404: GM作成待ち... ${retryDelay.inMilliseconds}ms後にリトライ');
          setState(() {
            _debugInfo += '\n6.GM作成待ち($attempt/$maxRetries)';
          });
          continue; // 次のループへ
        }
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final isGM = data['gameMasterId'].toString() == currentUserId;
            final phase = data['phase'] ?? 'SETUP';
            
            print('✅ GM判定成功: isGM=$isGM, currentUserId=$currentUserId, gameMasterId=${data['gameMasterId']}, phase=$phase');
            
            setState(() {
              _isGameMaster = isGM;
              _gamePhase = phase;
              _canSendMessage = _gamePhase == 'SETUP' ? _isGameMaster : true;
              _debugInfo += '\n7.GMチェック完了: isGM=$isGM';
            });
            
            // GMまたは非GMに応じてメッセージを表示
            if (_isGameMaster) {
              print('GM: botMessageを再取得');
              await _loadGameMessage(true);
            } else {
              print('非GM: waitMessageを表示');
              final waitMsg = data['waitMessage'] ?? 'ゲームマスターがルールを設定しています...しばらくお待ちください。';
              setState(() {
                _botMessages.clear();
                _botMessages.add({
                  'text': waitMsg,
                  'timestamp': DateTime.now().toIso8601String(),
                });
                _debugInfo += '\n8.botMsgM=${_botMessages.length}';
              });
              print('✅ 待機メッセージ表示成功');
            }
            return; // 成功したので終了
          }
        }
        
        // 最後の試行で失敗した場合もデフォルトメッセージを表示
        if (attempt == maxRetries) {
          print('⚠️ 最終試行でも404: デフォルトメッセージ表示');
          setState(() {
            _isGameMaster = false;
            _canSendMessage = false;
            _botMessages.clear();
            _botMessages.add({
              'text': 'ゲームマスターがルールを設定しています...しばらくお待ちください。',
              'timestamp': DateTime.now().toIso8601String(),
            });
            _debugInfo += '\n7.タイムアウト: デフォルト表示';
            _debugInfo += '\n8.botMsgM=${_botMessages.length}';
          });
        }
      } catch (e) {
        print('ゲームマスターチェックエラー (試行$attempt): $e');
        if (attempt == maxRetries) {
          setState(() {
            _botMessages.clear();
            _botMessages.add({
              'text': 'ゲームマスターがルールを設定しています...しばらくお待ちください。',
              'timestamp': DateTime.now().toIso8601String(),
            });
            _debugInfo += '\n7.エラー: デフォルト表示';
            _debugInfo += '\n8.botMsgM=${_botMessages.length}';
          });
        }
      }
    }
  }
  
  /// GMのゲームメッセージを取得（既にゲームが作成済みなのでbotMessageだけ返す）
  Future<void> _loadGameMessage(bool isGM) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson == null) return;
      
      final userData = jsonDecode(userJson);
      final userId = userData['id'];
      
      // 既にゲームが作成済みなので、/startを呼ぶとbotMessageが返される
      final response = await http.post(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gameMasterId': userId,
          'participants': widget.participants,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _botMessages.clear();
          _botMessages.add({
            'text': data['botMessage'],
            'timestamp': DateTime.now().toIso8601String(),
          });
          _gamePhase = data['phase'];
          _debugInfo += '\n7.GMメッセージ表示';
        });
        print('GM用ボットメッセージ表示: ${data['botMessage']}');
      }
    } catch (e) {
      print('ゲームメッセージ取得エラー: $e');
      setState(() {
        _debugInfo += '\n7.エラー: $e';
      });
    }
  }
  
  /// 非GMプレイヤー用の待機メッセージを読み込み
  Future<void> _loadWaitingMessage() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}?userId=$currentUserId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['waitMessage'] != null) {
          setState(() {
            _botMessages.clear();
            _botMessages.add({
              'text': data['waitMessage'],
              'timestamp': DateTime.now().toIso8601String(),
            });
          });
          print('待機メッセージ表示: ${data['waitMessage']}');
        }
      }
    } catch (e) {
      print('待機メッセージ読み込みエラー: $e');
    }
  }
  
  /// メッセージを取得
  Future<void> _fetchMessages() async {
    if (_isFetchingMessages) return;
    _isFetchingMessages = true;
    final response = await http.get(
      Uri.parse('$baseUrl/chat/${widget.thread['id']}/active'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _messages = data.map<Map<String, dynamic>>((item) {
        final msg = Map<String, dynamic>.from(item as Map);
        final userId = msg['userId'] ?? msg['user_id'];
        return {
          'id': msg['id'],
          'user_id': userId?.toString() ?? '',
          'text': msg['text'] ?? msg['content'] ?? '',
          'thread_id': msg['threadId'] ?? msg['thread_id'],
          'created_at': msg['createdAt'] ?? msg['created_at'],
          'photoId': msg['photoId'] ?? msg['photo_id'],
        };
      }).toList();
      
      for (var msg in _messages) {
        if ((msg['user_id'] ?? '').toString().isNotEmpty) {
          await _loadUserInfo(msg['user_id'].toString());
        }
      }
      
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    }
    _isFetchingMessages = false;
  }
  
  /// メッセージを送信
  Future<void> _sendMessage() async {
    if (!_isAlive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('静観中のためメッセージを送信できません')),
      );
      return;
    }
    if (!_canSendMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('現在メッセージを送信できません')),
      );
      return;
    }
    
    if (_messageController.text.trim().isEmpty || _isSending) return;
    
    setState(() => _isSending = true);
    
    try {
      final messageText = _messageController.text.trim();
      
      // セットアップフェーズの場合はルール設定APIを使用
      if (_gamePhase == 'SETUP' && _isGameMaster) {
        final response = await http.post(
          Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/setup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': currentUserId,
            'message': messageText,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('セットアップレスポンス: $data');
          
          // ユーザーメッセージとボットメッセージを追加
          setState(() {
            _botMessages.add({
              'text': messageText,
              'isUser': true,
              'timestamp': DateTime.now().toIso8601String(),
            });
            _botMessages.add({
              'text': data['botMessage'],
              'isUser': false,
              'timestamp': DateTime.now().toIso8601String(),
            });
            
            // セットアップ完了チェック
            if (data['setupComplete'] == true) {
              _gamePhase = 'ROLE_ASSIGNMENT';
              _canSendMessage = false;
              // 役職配分を実行
              _assignRoles();
            }
          });
          
          _messageController.clear();
          _scrollToBottom();
        }
      } else {
        // 通常のチャットメッセージ
        final payload = {
          'userId': int.parse(currentUserId),
          'content': messageText,
          'threadId': widget.thread['id'],
          'photoId': null,
        };
        final response = await http.post(
          Uri.parse('$baseUrl/chat/${widget.thread['id']}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final msg = jsonDecode(response.body);
          _messages.add({
            'id': msg['id'],
            'user_id': msg['userId'].toString(),
            'text': msg['content'],
            'created_at': msg['createdAt'],
            'photoId': msg['photoId'],
            'userIconUrl': _currentUserIconUrl,
          });
          _messageStreamController.add(List.from(_messages));
          _messageController.clear();
          _channel.sink.add(jsonEncode({...msg, 'userIconUrl': _currentUserIconUrl}));
          _scrollToBottom();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('送信エラー: ${response.statusCode}')),
            );
          }
        }
      }
    } catch (e) {
      print('メッセージ送信エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送信エラー: $e')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  String _typeLabel(String? type) {
    switch (type) {
      case '1': return '学生';
      case '2': return '社会人';
      case '3': return '企業';
      case '4': return '運営';
      default: return '';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    print('build呼び出し: _isUserLoaded=$_isUserLoaded, currentUserId=$currentUserId, _isGameMaster=$_isGameMaster, botMessages=${_botMessages.length}');
    
    if (!_isUserLoaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('読み込み中... userId=$currentUserId'),
              const SizedBox(height: 8),
              Text(_debugInfo, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: BridgeHeader(),
      body: GestureDetector(
        onTap: _registerActivity,
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
          // タイトルバー
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Row(
              children: [
                const Icon(Icons.games, size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.thread['title'] ?? '人狼ゲーム',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // タイマー表示エリア
                _buildTimerWidget(),
              ],
            ),
          ),
          
          // チャット表示エリア
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _botMessages.length + _messages.length,
              itemBuilder: (context, index) {
                // ボットメッセージを先に表示
                if (index < _botMessages.length) {
                  final botMsg = _botMessages[index];
                  return _buildBotMessageBubble(botMsg);
                }
                
                // 通常のチャットメッセージ
                final msg = _messages[index - _botMessages.length];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          
          // プレイヤー選択UI（夜フェーズ・投票フェーズ）
          if (_gamePhase == 'NIGHT' || _gamePhase == 'VOTING')
            _buildPlayerSelectionUI(),
          
          // メッセージ入力エリア（画像投稿機能なし）
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: _canSendMessage,
                    decoration: InputDecoration(
                      hintText: _canSendMessage ? 'メッセージを入力' : '送信不可',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) {
                      _registerActivity();
                      _sendMessage();
                    },
                    onChanged: (_) => _registerActivity(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _canSendMessage && !_isSending ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
  
  /// タイマーウィジェット
  Widget _buildTimerWidget() {
    if (_gamePhase != 'DISCUSSION') {
      return const SizedBox.shrink();
    }
    
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Text(
                '$minutes:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (_isGameMaster) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _endDiscussion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('議論終了'),
          ),
        ],
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _showParticipantsDialog,
          icon: const Icon(Icons.group, size: 18),
          label: const Text('参加者'),
        ),
      ],
    );
  }

  void _showParticipantsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('参加者一覧'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.participants.length,
              itemBuilder: (context, index) {
                final userId = widget.participants[index];
                final name = _nicknameCache[userId.toString()] ?? 'ユーザー $userId';
                final isAlive = _aliveUserIds.contains(userId) || _aliveUserIds.isEmpty;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: isAlive ? Colors.black87 : Colors.red,
                          fontWeight: isAlive ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isAlive)
                        const Text('（静観）', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
  
  /// ボットメッセージバブル（システムメッセージ）
  Widget _buildBotMessageBubble(Map<String, dynamic> botMsg) {
    final isUserMessage = botMsg['isUser'] == true;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[
            // ボットアイコン
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue[700],
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUserMessage)
                  const Text(
                    'ゲームマスターアシスタント',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isUserMessage ? Colors.blue[50] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    botMsg['text'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isUserMessage ? Colors.blue[900] : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (isUserMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundImage: _currentUserIconUrl != null 
                ? NetworkImage(_currentUserIconUrl!)
                : null,
              child: _currentUserIconUrl == null
                ? const Icon(Icons.person)
                : null,
            ),
          ],
        ],
      ),
    );
  }
  
  /// メッセージバブル
  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final userId = msg['user_id'].toString();
    final nickname = _nicknameCache[userId] ?? 'Unknown';
    final iconUrl = _userIconCache[userId];
    final userType = _userTypeCache[userId];
    final isCurrentUser = userId == currentUserId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 20,
              backgroundImage: iconUrl != null ? NetworkImage(iconUrl) : null,
              child: iconUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (userType != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _typeLabel(userType),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(msg['text'] ?? ''),
                ),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundImage: _currentUserIconUrl != null ? NetworkImage(_currentUserIconUrl!) : null,
              child: _currentUserIconUrl == null ? const Icon(Icons.person) : null,
            ),
          ],
        ],
      ),
    );
  }
  
  // ============== ゲーム進行メソッド ==============
  
  /// 役職配分を実行
  Future<void> _assignRoles() async {
    try {
      // GMのみが役職配分APIを呼ぶ
      if (_isGameMaster) {
        final response = await http.post(
          Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/assign-roles'),
        );
        
        if (response.statusCode == 200) {
          print('✅ 役職配分完了 → 全員に通知');
          
          // WebSocketで全員に通知
          _sendGameEvent('ROLES_ASSIGNED');
        }
      }
      
      // 全員が自分の役職を取得（イベントハンドラーでも実行されるが、GMは即座に取得）
      await Future.delayed(const Duration(milliseconds: 1000));
      await _fetchMyRole();
      
      // 1日目の夜へ移行
      setState(() {
        _gamePhase = 'NIGHT';
        _hasActedTonight = false;
      });
      
      // フェーズ監視を開始
      _startPhaseMonitoring();
      
    } catch (e) {
      print('役職配分エラー: $e');
    }
  }
  
  /// 自分の役職を取得
  Future<void> _fetchMyRole() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/role?userId=$currentUserId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final roleMessage = data['roleMessage'];
        
        print('📜 役職メッセージ受信: $roleMessage');
        
        setState(() {
          // 役職メッセージから役職を抽出（より厳密なマッチング）
          if (roleMessage.contains('あなたは人狼です')) {
            _myRole = 'WEREWOLF';
          } else if (roleMessage.contains('あなたは占い師です')) {
            _myRole = 'SEER';
          } else if (roleMessage.contains('あなたは騎士です')) {
            _myRole = 'KNIGHT';
          } else if (roleMessage.contains('あなたは霊媒師です')) {
            _myRole = 'MEDIUM';
          } else if (roleMessage.contains('あなたは村人です')) {
            _myRole = 'VILLAGER';
          } else {
            // フォールバック: メッセージの冒頭で判定
            _myRole = 'VILLAGER';
            print('⚠️ 役職判定失敗、村人として設定');
          }
          
          // ボットメッセージとして表示
          _botMessages.clear();
          _botMessages.add({
            'text': roleMessage,
            'isUser': false,
            'timestamp': DateTime.now().toIso8601String(),
          });
        });

        // 1日目の夜のみ、人狼チームに仲間リストを専用表示
        if (_myRole == 'WEREWOLF' && _currentCycle <= 1) {
          final match = RegExp(r'仲間の人狼:\s*ユーザーID\s*([0-9,\s]+)')
              .firstMatch(roleMessage);
          if (match != null) {
            final ids = match.group(1)!
                .split(RegExp(r'[\s,]+'))
                .where((s) => s.isNotEmpty)
                .map((s) => int.tryParse(s))
                .whereType<int>()
                .toList();
            if (ids.isNotEmpty) {
              final names = <String>[];
              for (final id in ids) {
                names.add(await _getUserLabel(id));
              }
              if (mounted) {
                setState(() {
                  _botMessages.add({
                    'text': '🐺 仲間の人狼: ${names.join(', ')}',
                    'isUser': false,
                    'timestamp': DateTime.now().toIso8601String(),
                  });
                });
              }
            }
          }
        }
        
        print('✅ 役職取得: $_myRole');
      }
    } catch (e) {
      print('役職取得エラー: $e');
    }
  }
  
  /// フェーズ監視を開始（定期的にゲーム状態をチェック）
  void _startPhaseMonitoring() {
    _phaseCheckTimer?.cancel();
    _phaseCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _checkGamePhase();
    });
  }

  /// ゲーム情報を更新（currentCycleなど）
  Future<void> _refreshGameInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}?userId=$currentUserId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentCycle = data['currentCycle'] ?? _currentCycle;
        final aliveUserIds = (data['aliveUserIds'] as List<dynamic>?)
                ?.map((e) => int.parse(e.toString()))
                .toSet() ??
            _aliveUserIds;
        final deadUserIds = (data['deadUserIds'] as List<dynamic>?)
                ?.map((e) => int.parse(e.toString()))
                .toSet() ??
            _deadUserIds;
        if (mounted && currentCycle != _currentCycle) {
          setState(() {
            _currentCycle = currentCycle;
            _aliveUserIds = aliveUserIds;
            _deadUserIds = deadUserIds;
            _isAlive = !_deadUserIds.contains(int.tryParse(currentUserId) ?? -1);
          });
        }
      }
    } catch (e) {
      print('ゲーム情報更新エラー: $e');
    }
  }
  
  /// ゲームフェーズをチェック
  Future<void> _checkGamePhase() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}?userId=$currentUserId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newPhase = data['phase'];
        final currentCycle = data['currentCycle'] ?? 0;
        final discussionTimeMinutes = data['discussionTimeMinutes'] ?? 5;
        final aliveUserIds = (data['aliveUserIds'] as List<dynamic>?)
            ?.map((e) => int.parse(e.toString()))
            .toSet() ??
          _aliveUserIds;
        final deadUserIds = (data['deadUserIds'] as List<dynamic>?)
            ?.map((e) => int.parse(e.toString()))
            .toSet() ??
          _deadUserIds;

        final phaseChanged = newPhase != _gamePhase;
        final cycleChanged = currentCycle != _currentCycle;

        if ((phaseChanged || cycleChanged) && mounted) {
          setState(() {
            _gamePhase = newPhase;
            _currentCycle = currentCycle;
            _aliveUserIds = aliveUserIds;
            _deadUserIds = deadUserIds;
            _isAlive = !_deadUserIds.contains(int.tryParse(currentUserId) ?? -1);

            // フェーズに応じて初期化
            if (phaseChanged) {
              if (newPhase == 'NIGHT') {
                _hasActedTonight = false;
                _selectedTarget = null;
                _canSendMessage = false;
              } else if (newPhase == 'VOTING') {
                _hasVoted = false;
                _selectedTarget = null;
                _canSendMessage = false;
              } else if (newPhase == 'DISCUSSION') {
                // 議論時間を分から秒に変換
                final discussionTimeSeconds = discussionTimeMinutes * 60;
                _canSendMessage = true;
                _startDiscussionTimer(discussionTimeSeconds);
              }
            }
          });

          if (phaseChanged) {
            print('📍 フェーズ変更: $_gamePhase');
            if (newPhase == 'NIGHT') {
              await _maybeNotifyNightComplete();
            }
          }
        }
        if (mounted && (_aliveUserIds.isEmpty || _deadUserIds.isEmpty)) {
          setState(() {
            _aliveUserIds = aliveUserIds;
            _deadUserIds = deadUserIds;
            _isAlive = !_deadUserIds.contains(int.tryParse(currentUserId) ?? -1);
          });
        }
        if (_gamePhase == 'DISCUSSION') {
          await _fetchMessages();
        }
      }
    } catch (e) {
      print('フェーズチェックエラー: $e');
    }
  }

  /// 行動不要な役職の場合、夜の完了判定をチェックして通知
  Future<void> _maybeNotifyNightComplete() async {
    if (_gamePhase != 'NIGHT') return;
    if (_currentCycle == _lastNightCompleteNotifiedCycle) return;

    // 行動不要: 村人、霊媒師、または1日目の人狼
    final isWerewolfFirstNight = _myRole == 'WEREWOLF' && _currentCycle <= 1;
    final isNonActionRole = _myRole == 'VILLAGER' || _myRole == 'MEDIUM' || isWerewolfFirstNight;
    if (!isNonActionRole) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/night-complete'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['nightComplete'] == true) {
          print('✅ 夜行動完了検知 → WebSocketで全員に通知');
          _lastNightCompleteNotifiedCycle = _currentCycle;
          _sendGameEvent('NIGHT_COMPLETE');
        }
      }
    } catch (e) {
      print('夜完了チェックエラー: $e');
    }
  }
  
  /// ゲームイベントを処理
  Future<void> _handleGameEvent(Map<String, dynamic> msg) async {
    final event = msg['event'];
    final data = msg['data'] as Map<String, dynamic>?;
    
    print('🎮 ゲームイベント処理: event=$event, data=$data');
    
    switch (event) {
      case 'ROLES_ASSIGNED':
        // 役職配分完了 → 全員が役職を取得
        print('役職配分イベント受信 → 役職取得開始');
        await _refreshGameInfo();
        await _fetchMyRole();
        if (mounted) {
          setState(() {
            _gamePhase = 'NIGHT';
            _hasActedTonight = false;
          });
        }
        await _maybeNotifyNightComplete();
        _startPhaseMonitoring();
        break;
        
      case 'PHASE_CHANGED':
        // フェーズ変更 → 即座に同期
        final newPhase = data?['phase'];
        final phaseMessage = data?['message'];
        final aliveUserIds = (data?['aliveUserIds'] as List<dynamic>?)
                ?.map((e) => int.parse(e.toString()))
                .toSet();
        final deadUserIds = (data?['deadUserIds'] as List<dynamic>?)
                ?.map((e) => int.parse(e.toString()))
                .toSet();
        if (newPhase != null && newPhase != _gamePhase && mounted) {
          print('フェーズ変更イベント: $_gamePhase → $newPhase');
          setState(() {
            _gamePhase = newPhase;
            if (aliveUserIds != null) {
              _aliveUserIds = aliveUserIds;
            }
            if (deadUserIds != null) {
              _deadUserIds = deadUserIds;
              _isAlive = !_deadUserIds.contains(int.tryParse(currentUserId) ?? -1);
            }
            
            // フェーズ変更メッセージがあれば表示（重複は抑制）
            if (phaseMessage != null && phaseMessage.toString().isNotEmpty) {
              final lastText = _botMessages.isNotEmpty ? _botMessages.last['text'] : null;
              if (lastText != phaseMessage) {
                _botMessages.add({
                  'text': phaseMessage,
                  'isUser': false,
                  'timestamp': DateTime.now().toIso8601String(),
                });
              }
            }
            
            if (newPhase == 'NIGHT') {
              _hasActedTonight = false;
              _selectedTarget = null;
              _canSendMessage = false; // 夜はチャット不可
            } else if (newPhase == 'VOTING') {
              _hasVoted = false;
              _selectedTarget = null;
              _canSendMessage = false; // 投票中はチャット不可
            } else if (newPhase == 'DISCUSSION') {
              final discussionTime = data?['discussionTime'] ?? 300;
              _canSendMessage = true; // 議論中はチャット可能
              _startDiscussionTimer(discussionTime);
            }
          });
          if (newPhase == 'NIGHT') {
            await _maybeNotifyNightComplete();
          }
        }
        break;
        
      case 'GAME_ENDED':
        // ゲーム終了
        final winner = data?['winner'];
        print('ゲーム終了イベント: winner=$winner');
        if (winner != null) {
          _showGameResult(winner.toString());
        }
        break;

      case 'PLAYER_INACTIVE':
        final inactiveUserId = data?['userId'];
        if (inactiveUserId != null) {
          final id = int.tryParse(inactiveUserId.toString());
          if (id != null) {
            final name = _nicknameCache[id.toString()] ?? 'ユーザー $id';
            setState(() {
              _deadUserIds.add(id);
              _aliveUserIds.remove(id);
              if (id.toString() == currentUserId) {
                _isAlive = false;
              }
              _botMessages.add({
                'text': '$name が非アクティブのため静観になりました。',
                'isUser': false,
                'timestamp': DateTime.now().toIso8601String(),
              });
            });
          }
        }
        break;
        
      case 'NIGHT_COMPLETE':
        // 全員の夜行動完了 → GMが朝フェーズへ移行
        print('🌙 NIGHT_COMPLETEイベント受信: isGM=$_isGameMaster');
        if (_isGameMaster && _gamePhase == 'NIGHT') {
          print('✅ GMが朝フェーズへ移行を実行');
          await _executeNightPhase();
        }
        break;
        
      case 'VOTE_COMPLETE':
        // 全員の投票完了 → GMが処刑を実行
        print('🗳️ VOTE_COMPLETEイベント受信: isGM=$_isGameMaster');
        if (_isGameMaster) {
          print('✅ GMが投票結果を実行');
          await _executeVoting();
        }
        break;

      case 'NIGHT_RESULT':
        // 夜結果を全員に同期
        final nightMessage = data?['message']?.toString();
        int? killedUserId = data?['killedUserId'];
        if (nightMessage != null && nightMessage.isNotEmpty) {
          final lastText = _botMessages.isNotEmpty ? _botMessages.last['text'] : null;
          if (lastText != nightMessage) {
            setState(() {
              _botMessages.add({
                'text': nightMessage,
                'isUser': false,
                'timestamp': DateTime.now().toIso8601String(),
              });
              if (killedUserId != null && killedUserId.toString() == currentUserId) {
                _isAlive = false;
              }
              if (killedUserId != null) {
                _deadUserIds.add(killedUserId);
                _aliveUserIds.remove(killedUserId);
              }
            });
          }
        }
        break;

      case 'EXECUTION_RESULT':
        // 処刑結果を全員に同期
        final executedUserId = data?['executedUserId'];
        final executedName = data?['executedName']?.toString();
        if (executedUserId != null) {
          final label = executedName ?? 'ユーザーID $executedUserId';
          final resultText = '$label が処刑されました。';
          final lastText = _botMessages.isNotEmpty ? _botMessages.last['text'] : null;
          if (lastText != resultText) {
            setState(() {
              _botMessages.add({
                'text': resultText,
                'isUser': false,
                'timestamp': DateTime.now().toIso8601String(),
              });
              if (executedUserId.toString() == currentUserId) {
                _isAlive = false;
              }
              _deadUserIds.add(executedUserId);
              _aliveUserIds.remove(executedUserId);
            });
          }
        }
        break;
        
      default:
        print('未知のゲームイベント: $event');
    }
  }
  
  /// WebSocketでゲームイベントを送信
  void _sendGameEvent(String event, [Map<String, dynamic>? data]) {
    final message = {
      'type': 'GAME_EVENT',
      'event': event,
      'threadId': widget.thread['id'],
      'data': data ?? {},
    };
    _channel.sink.add(jsonEncode(message));
    print('🎮 ゲームイベント送信: $event');
  }
  
  /// 議論タイマーを開始
  void _startDiscussionTimer(int seconds) {
    _discussionTimer?.cancel();
    setState(() => _remainingSeconds = seconds);
    
    _discussionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        // タイマー終了時にGMなら投票フェーズへ移行できる
      }
    });
  }
  
  /// 夜の行動（襲撃/占い/護衛）を送信
  Future<void> _submitNightAction() async {
    if (!_isAlive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('静観中のため行動できません')),
      );
      return;
    }
    if (_selectedTarget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('対象を選択してください')),
      );
      return;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/night-action'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': int.parse(currentUserId),
          'targetUserId': _selectedTarget,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _hasActedTonight = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('行動を送信しました')),
        );
        
        // 全員完了したらWebSocketで全員に通知
        if (data['nightComplete'] == true) {
          print('✅ 全員の夜行動完了 → WebSocketで全員に通知');
          _sendGameEvent('NIGHT_COMPLETE');
        }
        // 占い師の結果を表示（本人のみ）
        Future<void> addResultMessage(dynamic result) async {
          if (result == null || result.toString().isEmpty) return;
          String message = result.toString();
          final match = RegExp(r'ユーザーID\s*(\d+)').firstMatch(message);
          if (match != null) {
            final targetId = int.tryParse(match.group(1) ?? '');
            if (targetId != null) {
              final label = await _getUserLabel(targetId);
              message = message.replaceAll('ユーザーID $targetId', label);
            }
          }
          setState(() {
            _botMessages.add({
              'text': message,
              'isUser': false,
              'timestamp': DateTime.now().toIso8601String(),
            });
          });
        }

        await addResultMessage(data['seerResult']);
        await addResultMessage(data['knightResult']);
        await addResultMessage(data['mediumResult']);
        // 行動決定を全員に通知（同期用）
        _sendGameEvent('NIGHT_ACTION_SUBMITTED', {
          'userId': int.parse(currentUserId),
          'targetUserId': _selectedTarget,
          'role': _myRole,
        });
      }
    } catch (e) {
      print('夜行動送信エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }
  
  /// 夜フェーズを実行（朝へ移行）
  Future<void> _executeNightPhase() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/execute-night'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String nightMessage = data['message'];
        final winner = data['winner'];
        int? killedUserId = data['killedUserId'] != null
            ? int.tryParse(data['killedUserId'].toString())
            : null;
        int? protectedUserId = data['protectedUserId'] != null
            ? int.tryParse(data['protectedUserId'].toString())
            : null;
        
        // ゲーム情報から議論時間を取得
        final gameInfoResponse = await http.get(
          Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}?userId=$currentUserId'),
        );
        int discussionTimeSeconds = 300; // デフォルト5分
        if (gameInfoResponse.statusCode == 200) {
          final gameInfo = jsonDecode(gameInfoResponse.body);
          final discussionTimeMinutes = gameInfo['discussionTimeMinutes'] ?? 5;
          discussionTimeSeconds = discussionTimeMinutes * 60;
        }
        
        // 夜結果メッセージのユーザーIDを名前に置換
        final match = RegExp(r'ユーザーID\s*(\d+)').firstMatch(nightMessage);
        if (match != null) {
          final targetId = int.tryParse(match.group(1) ?? '');
          if (targetId != null) {
            final label = await _getUserLabel(targetId);
            nightMessage = nightMessage.replaceAll('ユーザーID $targetId', label);
            killedUserId ??= targetId;
          }
        }

        // 護衛成功メッセージをユーザー名付きに変換
        if (protectedUserId != null && nightMessage.contains('護衛が成功しました')) {
          final name = await _getUserLabel(protectedUserId);
          nightMessage = '夜が明けました。\n$name は騎士に護衛されていたため、人狼の襲撃は失敗しました。';
        }

        // 結果をボットメッセージとして表示
        setState(() {
          _botMessages.add({
            'text': nightMessage,
            'isUser': false,
            'timestamp': DateTime.now().toIso8601String(),
          });
          if (killedUserId != null) {
            _deadUserIds.add(killedUserId);
            _aliveUserIds.remove(killedUserId);
            if (killedUserId.toString() == currentUserId) {
              _isAlive = false;
            }
          }
        });
        
        if (winner != null) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            _sendGameEvent('GAME_ENDED', {'winner': winner});
          });
        } else {
          // WebSocketで議論フェーズ開始を全員に通知（メッセージも含める）
          _sendGameEvent('PHASE_CHANGED', {
            'phase': 'DISCUSSION',
            'discussionTime': discussionTimeSeconds,
            'message': nightMessage,
            'aliveUserIds': _aliveUserIds.toList(),
            'deadUserIds': _deadUserIds.toList(),
          });
        }
        _sendGameEvent('NIGHT_RESULT', {
          'message': nightMessage,
          'killedUserId': killedUserId,
          'protectedUserId': protectedUserId,
        });
      }
    } catch (e) {
      print('夜実行エラー: $e');
    }
  }
  
  /// 投票を送信
  Future<void> _submitVote() async {
    if (_selectedTarget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投票先を選択してください')),
      );
      return;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/vote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'voterId': int.parse(currentUserId),
          'targetId': _selectedTarget,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _hasVoted = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投票しました')),
        );
        
        // 全員投票したらWebSocketで全員に通知
        if (data['voteComplete'] == true) {
          print('✅ 全員の投票完了 → WebSocketで全員に通知');
          _sendGameEvent('VOTE_COMPLETE');
        }
        // 投票決定を全員に通知（同期用）
        _sendGameEvent('VOTE_SUBMITTED', {
          'voterId': int.parse(currentUserId),
          'targetId': _selectedTarget,
        });
      }
    } catch (e) {
      print('投票送信エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }
  
  /// 投票を集計して処刑を実行
  Future<void> _executeVoting() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/execute-vote'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final executedUserId = data['executedUserId'];
        final winner = data['winner'];

        String executedLabel = 'ユーザーID $executedUserId';
        if (executedUserId != null) {
          executedLabel = await _getUserLabel(executedUserId);
        }
        
        // 処刑結果を表示
        setState(() {
          _messages.clear();
          _botMessages.add({
            'text': '$executedLabel が処刑されました。',
            'isUser': false,
            'timestamp': DateTime.now().toIso8601String(),
          });
          
          if (executedUserId.toString() == currentUserId) {
            _isAlive = false;
          }
        });

        // 処刑結果を全員に通知
        _sendGameEvent('EXECUTION_RESULT', {
          'executedUserId': executedUserId,
          'executedName': executedLabel,
        });
        
        // 勝敗判定
        if (winner != null) {
          // 処刑結果の表示後に勝敗通知を遅延
          Future.delayed(const Duration(milliseconds: 1500), () {
            _sendGameEvent('GAME_ENDED', {'winner': winner});
          });
        } else {
          // 次の夜フェーズへ移行を全員に通知
          _sendGameEvent('PHASE_CHANGED', {'phase': 'NIGHT'});
        }
      }
    } catch (e) {
      print('投票実行エラー: $e');
    }
  }
  
  /// ゲーム結果を表示
  void _showGameResult(String winner) {
    setState(() {
      _gamePhase = 'ENDED';
      _phaseCheckTimer?.cancel();
      
      String resultMessage = '';
      if (winner == 'villager') {
        resultMessage = '🎉 村人陣営の勝利！\n\n人狼を全員退治しました！';
      } else if (winner == 'werewolf') {
        resultMessage = '🐺 人狼陣営の勝利！\n\n人狼の数が村人と同数以上になりました！';
      } else if (winner == 'forced') {
        resultMessage = '⚠️ ゲームマスターが非アクティブのため、ゲームを終了しました。';
      } else {
        resultMessage = '⚠️ ゲームが終了しました。';
      }
      
      _botMessages.add({
        'text': resultMessage,
        'isUser': false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _scheduleGameEndFlow();
  }

  void _scheduleGameEndFlow() {
    if (_endFlowScheduled) return;
    _endFlowScheduled = true;

    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;
      await _navigateBackToOriginThread();
    });

    Future.delayed(const Duration(seconds: 8), () async {
      await _cleanupGameThread();
    });
  }

  Future<void> _navigateBackToOriginThread() async {
    final originThreadId = widget.originThreadId;
    if (originThreadId == null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/threads/$originThreadId'),
      );
      if (response.statusCode == 200) {
        final thread = jsonDecode(response.body);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ThreadUnOfficialDetail(thread: thread),
          ),
        );
      } else {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _cleanupGameThread() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/cleanup'),
      );
    } catch (e) {
      print('ゲームスレッド削除エラー: $e');
    }
  }
  
  /// 議論を終了（GMのみ）
  Future<void> _endDiscussion() async {
    if (!_isGameMaster) return;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/werewolf/game/${widget.thread['id']}/end-discussion'),
      );
      
      if (response.statusCode == 200) {
        // WebSocketで投票フェーズ開始を全員に通知
        _sendGameEvent('PHASE_CHANGED', {'phase': 'VOTING'});
        
        setState(() {
          _gamePhase = 'VOTING';
          _hasVoted = false;
          _selectedTarget = null;
          _canSendMessage = false;
          _discussionTimer?.cancel();
        });
      }
    } catch (e) {
      print('議論終了エラー: $e');
    }
  }
  
  /// プレイヤー選択UI
  Widget _buildPlayerSelectionUI() {
    print('🎯 _buildPlayerSelectionUI呼び出し: phase=$_gamePhase, role=$_myRole, isAlive=$_isAlive');
    
    // 死んでいたら表示しない
    if (!_isAlive) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[200],
        child: const Text(
          '静観中...（死亡したためゲームに介入できません）',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }
    
    // 夜フェーズで行動できない役職
    if (_gamePhase == 'NIGHT') {
      print('🌙 夜フェーズ: 役職チェック開始 role=$_myRole, cycle=$_currentCycle');
      
      // 1日目の夜は襲撃なし（人狼も行動不可）
      if (_currentCycle <= 1 && _myRole == 'WEREWOLF') {
        print('  → 1日目の夜: 人狼も襲撃不可');
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.red[50],
          child: const Text(
            '1日目の夜...\n襲撃は明日から開始できます。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        );
      }
      
      // 村人は常に行動不可
      if (_myRole == 'VILLAGER') {
        print('  → 村人: 行動不可');
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: const Text(
            '夜のフェーズ中...\n明日の議論に備えて休んでいます。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        );
      }
      // 霊媒師は夜は行動不可（処刑者の確認のみ）
      if (_myRole == 'MEDIUM') {
        print('  → 霊媒師: 行動不可');
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.purple[50],
          child: const Text(
            '霊媒中...\n処刑された人の役職を確認しています。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        );
      }
      // 夜に行動できるのは人狼・占い師・騎士のみ
      if (_myRole != 'WEREWOLF' && _myRole != 'SEER' && _myRole != 'KNIGHT') {
        print('  → その他の役職: 行動不可 role=$_myRole');
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: const Text(
            '夜のフェーズ中...\n特別な能力を持たないため休んでいます。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        );
      }
      
      print('  → 行動可能な役職: $_myRole');
    }
    
    // 既に行動/投票済み
    if ((_gamePhase == 'NIGHT' && _hasActedTonight) || 
        (_gamePhase == 'VOTING' && _hasVoted)) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.green[100],
        child: Text(
          _gamePhase == 'NIGHT' ? '✅ 夜の行動を完了しました' : '✅ 投票を完了しました',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }
    
    // 夜フェーズかつVOTINGフェーズでない場合の最終チェック
    if (_gamePhase == 'NIGHT') {
      // ここに到達するのは人狼・占い師・騎士のみのはず
      if (_myRole != 'WEREWOLF' && _myRole != 'SEER' && _myRole != 'KNIGHT') {
        // 念のための追加チェック
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: const Text(
            '夜のフェーズ中...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        );
      }
    }
    
    // タイトル
    String title = '';
    if (_gamePhase == 'NIGHT') {
      if (_myRole == 'WEREWOLF') {
        title = '🐺 襲撃するプレイヤーを選択';
      } else if (_myRole == 'SEER') {
        title = '🔮 占うプレイヤーを選択';
      } else if (_myRole == 'KNIGHT') {
        title = '🛡️ 護衛するプレイヤーを選択';
      } else {
        // ここには到達しないはず
        title = '夜の行動';
      }
    } else if (_gamePhase == 'VOTING') {
      title = '🗳️ 処刑するプレイヤーを選択';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orange[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.participants.map((userId) {
              if (_deadUserIds.contains(userId)) {
                return const SizedBox.shrink();
              }
              // 自分は除外（襲撃/占い/護衛/投票対象にならない）
              if (userId.toString() == currentUserId) {
                return const SizedBox.shrink();
              }
              
              final isSelected = _selectedTarget == userId;
              final userKey = userId.toString();
              final userLabel = _nicknameCache[userKey] ?? 'ユーザー $userId';
              
              return ChoiceChip(
                label: Text(userLabel),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTarget = selected ? userId : null;
                  });
                },
                selectedColor: Colors.orange,
                backgroundColor: Colors.grey[200],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _selectedTarget != null
                  ? (_gamePhase == 'NIGHT' ? _submitNightAction : _submitVote)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(_gamePhase == 'NIGHT' ? '行動を決定' : '投票する'),
            ),
          ),
        ],
      ),
    );
  }
}
