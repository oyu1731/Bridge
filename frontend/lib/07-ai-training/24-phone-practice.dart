import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/60-ScreenWrapper.dart';
import 'package:bridge/11-common/59-global-method.dart';
import 'package:http/http.dart' as http;
import 'package:bridge/07-ai-training/25-phone-result.dart';
import 'package:bridge/07-ai-training/21-ai-training-list.dart';
import 'package:js/js.dart';

@JS('speechWrapper')
external SpeechWrapper get speechWrapper;

@JS()
@staticInterop
class SpeechWrapper {}

extension SpeechWrapperExt on SpeechWrapper {
  external void start(Function onResult);
  external void stop();
}

class PhonePractice extends StatefulWidget {
  const PhonePractice({super.key});

  @override
  State<PhonePractice> createState() => _PhonePracticeState();
}

class _PhonePracticeState extends State<PhonePractice> {
  // --- Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();

  // --- Dropdown values ---
  String? selectedGenre;
  String? selectedCallAtmosphere;
  String? selectedDifficulty;

  // --- Review type ---
  String reviewType = "all";

  Map<String, dynamic>? user;
  Map<String, dynamic> _companyInfo = {};
  String? _authToken;

  final List<String> genres = ["ビジネス", "カジュアル", "フォーマル"];
  final List<String> callAtmospheres = ["穏やか", "厳格", "フレンドリー"];
  final List<String> difficulties = ["簡単", "普通", "難しい"];

  int? _availableTokens; // ユーザーが保有するトークン数

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    user = await GlobalActions().loadUserSession();
    _authToken = await GlobalActions().loadAuthToken();
    print("userのプラン状態: ${user?['plan_status']}");

    // 認証トークンの取得
    _authToken = await GlobalActions().loadAuthToken();
    if (_authToken != null) {
      print("[_init] 取得した認証トークン: $_authToken");
    } else {
      print("[_init] 認証トークンはSharedPreferencesに保存されていません。");
    }

    // ユーザー保有トークン数の取得
    if (user != null && user!['id'] != null) {
      _availableTokens = await GlobalActions().fetchUserTokens(
        user!['id'] as int,
      );
      print("[_init] 取得したユーザー保有トークン: $_availableTokens");
    }

    if (user != null) {
      nameController.text = user!['nickname'] ?? '';
    }

    selectedGenre = (genres..shuffle()).first;
    selectedCallAtmosphere = (callAtmospheres..shuffle()).first;
    selectedDifficulty = (difficulties..shuffle()).first;

    setState(() {});
    Future.delayed(Duration.zero, () => _openSettingPopup());
  }

  void _openSettingPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isFree = (user?['plan_status'] ?? '無料') == '無料';

            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "電話設定",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // トークン情報表示
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "現在のトークン",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _availableTokens?.toString() ?? '未取得',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "20トークン消費",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // あなたの情報
                    _buildSectionHeader(icon: Icons.person, title: "あなたの情報"),
                    const SizedBox(height: 12),
                    _inputField("お名前", nameController),
                    const SizedBox(height: 12),
                    _inputField("所属企業名", companyNameController),
                    const SizedBox(height: 20),

                    // 電話の受信モード設定
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                icon: Icons.settings,
                                title: "電話の受信モード設定",
                              ),
                              const SizedBox(height: 16),
                              _dropdown("ジャンル", genres, selectedGenre, (v) {
                                setModalState(() => selectedGenre = v);
                              }, isFree: isFree),
                              const SizedBox(height: 12),
                              _dropdown(
                                "雰囲気",
                                callAtmospheres,
                                selectedCallAtmosphere,
                                (v) {
                                  setModalState(
                                    () => selectedCallAtmosphere = v,
                                  );
                                },
                                isFree: isFree,
                              ),
                              const SizedBox(height: 12),
                              _dropdown(
                                "難易度",
                                difficulties,
                                selectedDifficulty,
                                (v) {
                                  setModalState(() => selectedDifficulty = v);
                                },
                                isFree: isFree,
                              ),
                            ],
                          ),
                        ),
                        if (isFree)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "PREMIUM",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 電話開始ボタン
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (user == null) return;

                          final payload = {
                            "userId": user!['id'],
                            "planStatus": user!['plan_status'],
                            "userName": nameController.text,
                            "companyName": companyNameController.text,
                            "genre": selectedGenre,
                            "callAtmosphere": selectedCallAtmosphere,
                            "difficulty": selectedDifficulty,
                            "reviewType": reviewType,
                          };

                          _companyInfo = {
                            "userName": nameController.text,
                            "companyName": companyNameController.text,
                            "genre": selectedGenre,
                            "callAtmosphere": selectedCallAtmosphere,
                            "difficulty": selectedDifficulty,
                          };
                          print("送信する内容: $_companyInfo");

                          final url = Uri.parse(
                            'http://localhost:8080/api/phone/practice',
                          );
                          final headers = {
                            'Content-Type': 'application/json; charset=UTF-8',
                          };

                          try {
                            final response = await http.post(
                              url,
                              headers: headers,
                              body: jsonEncode(payload),
                            );

                            if (response.statusCode == 200) {
                              final Map<String, dynamic> rawResponse =
                                  jsonDecode(response.body);

                              final String initialMessage =
                                  rawResponse['message'] ?? "電話が繋がりました。";
                              final String scenario =
                                  rawResponse['scenario'] ?? "";
                              final String memo = rawResponse['memo'] ?? "";
                              final String sessionId =
                                  rawResponse['sessionId'] ?? "";

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => PhoneCallScreen(
                                        initialMessage: initialMessage,
                                        scenario: scenario,
                                        memo: memo,
                                        companyInfo: _companyInfo,
                                        user: user,
                                        sessionId: sessionId,
                                      ),
                                ),
                              );
                            } else {
                              throw Exception('電話開始に失敗: ${response.body}');
                            }
                          } catch (e) {
                            print("error" + e.toString());
                            showGenericDialog(
                              context: context,
                              type: DialogType.onlyOk,
                              title: 'エラー',
                              content: '電話開始中にエラーが発生しました: $e',
                              confirmText: 'OK',
                              onConfirm: () {},
                            );
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "電話を開始する",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AiTrainingListPage(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text(
                          "練習一覧へ戻る",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged, {
    bool isFree = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                if (isFree) {
                  showGenericDialog(
                    context: context,
                    type: DialogType.onlyOk,
                    title: 'プレミアム限定',
                    content: 'この設定はプレミアム会員限定です。',
                    confirmText: 'OK',
                    onConfirm: () {},
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isFree ? Colors.grey.shade300 : Colors.grey.shade400,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isFree ? Colors.grey.shade100 : Colors.white,
                ),
                child: DropdownButton<String>(
                  hint: const Text("選択してください"),
                  underline: const SizedBox(),
                  value: items.contains(selectedValue) ? selectedValue : null,
                  isExpanded: true,
                  items:
                      items
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                  onChanged: isFree ? null : onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      appBar: BridgeHeader(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "電話設定が完了するとここに電話画面が表示されます",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneCallScreen extends StatefulWidget {
  final String initialMessage;
  final String scenario;
  final String memo;
  final Map<String, dynamic> companyInfo;
  final Map<String, dynamic>? user;
  final String sessionId;

  const PhoneCallScreen({
    super.key,
    required this.initialMessage,
    required this.scenario,
    required this.memo,
    required this.companyInfo,
    this.user,
    required this.sessionId,
  });

  @override
  State<PhoneCallScreen> createState() => _PhoneCallScreenState();
}

class _PhoneCallScreenState extends State<PhoneCallScreen> {
  bool _isMicOn = false;
  final TextEditingController _textEditingController = TextEditingController();
  String _currentAIMessage = "";
  String? _endReason;
  bool _isConversationEnd = false;
  final GlobalActions _globalActions = GlobalActions();
  Map<String, dynamic>? _userSession;

  @override
  void initState() {
    super.initState();
    _currentAIMessage = widget.initialMessage;
    _textEditingController.addListener(() {
      print("テキスト変更: ${_textEditingController.text}");
    });
    _loadUserSession();
    _speakAIMessage();
  }

  void _loadUserSession() async {
    _userSession = await _globalActions.loadUserSession();
    setState(() {});
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _speakAIMessage() {
    speakWeb(_currentAIMessage);
  }

  void _toggleMic() {
    print("[Dart] Toggle mic. Before: $_isMicOn");
    setState(() {
      _isMicOn = !_isMicOn;
      if (_isMicOn) {
        print("[Dart] Calling speechWrapper.start()");
        speechWrapper.start(
          allowInterop((String result) {
            print("[Dart] On speech result: $result");
            setState(() {
              _textEditingController.text = result;
              _textEditingController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textEditingController.text.length),
              );
            });
          }),
        );
      } else {
        print("[Dart] Calling speechWrapper.stop()");
        speechWrapper.stop();
        print("[Dart] PhonePractice: マイクOFF");
      }
    });
    print("[Dart] Toggle mic. After: $_isMicOn");
  }

  void _submitAnswer() async {
    if (_isConversationEnd) {
      _showInfoDialog("会話は終了しています", _endReason ?? "会話は既に終了しています。");
      return;
    }

    if (_isMicOn) {
      speechWrapper.stop();
      setState(() {
        _isMicOn = false;
      });
    }

    String answer = _textEditingController.text;

    if (answer.trim().isEmpty) {
      _showInfoDialog("入力がありません", "何かメッセージを入力してください。");
      return;
    }

    final url = Uri.parse('http://localhost:8080/api/phone/continue');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final payload = {"sessionId": widget.sessionId, "message": answer};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = jsonDecode(response.body);

        setState(() {
          _currentAIMessage = apiResponse['message'] ?? "応答がありません。";
          _isConversationEnd = apiResponse['isConversationEnd'] ?? false;
          _endReason = apiResponse['endReason'];
          _textEditingController.clear();
          _isMicOn = false;
        });

        _speakAIMessage();

        if (_isConversationEnd) {
          _showInfoDialog("会話終了", _endReason ?? "会話が終了しました。");
        }
      } else {
        throw Exception('AI応答取得に失敗: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog("AI応答取得中にエラーが発生しました", e.toString());
    }
  }

  void _showErrorDialog(String title, String content) {
    showGenericDialog(
      context: context,
      type: DialogType.onlyOk,
      title: title,
      content: content,
      confirmText: 'OK',
      onConfirm: () {},
    );
  }

  void _showInfoDialog(String title, String content) {
    showGenericDialog(
      context: context,
      type: DialogType.onlyOk,
      title: title,
      content: content,
      confirmText: 'OK',
      onConfirm: () {},
    );
  }

  void _endCallAndNavigateToResult() async {
    final url = Uri.parse('http://localhost:8080/api/phone/end');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final payload = {"sessionId": widget.sessionId};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("会話終了API呼び出し成功");
        final Map<String, dynamic> evaluationData = jsonDecode(response.body);
        print("評価データを受信: ${evaluationData['totalScore']}点");

        if (_userSession != null && _userSession!['id'] != null) {
          final userId = _userSession!['id'] as int;
          final tokensToDeduct = 20;
          final bool deducted = await _globalActions.deductUserTokens(
            userId,
            tokensToDeduct,
          );
          if (deducted) {
            print('$tokensToDeduct トークンを消費しました。');
          } else {
            print('トークン消費に失敗しました。');
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => PhoneResultScreen(
                  sessionId: widget.sessionId,
                  evaluationResult: evaluationData,
                ),
          ),
        );
      } else {
        print("会話終了API呼び出し失敗: ${response.statusCode} - ${response.body}");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PhoneResultScreen(sessionId: widget.sessionId),
          ),
        );
      }
    } catch (e) {
      print("会話終了API呼び出し中にエラーが発生しました: $e");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PhoneResultScreen(sessionId: widget.sessionId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      appBar: BridgeHeader(),
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // メモ表示
              if (widget.memo.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade50,
                    border: Border.all(color: Colors.yellow.shade300),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.memo,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // シナリオ表示
              if (widget.scenario.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description,
                          size: 18,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "シナリオ: ${widget.scenario}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // AIメッセージ表示
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone,
                              size: 20,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "通話内容",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _currentAIMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 会話終了理由の表示
              if (_isConversationEnd && _endReason != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "会話終了理由: $_endReason",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // マイクボタン
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _isMicOn
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF0F9FF),
                        border: Border.all(
                          color:
                              _isMicOn
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF0EA5E9),
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isMicOn ? Icons.mic : Icons.mic_off,
                          size: 32,
                          color:
                              _isMicOn
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF0EA5E9),
                        ),
                        onPressed: _isConversationEnd ? null : _toggleMic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isMicOn ? "マイクON - 音声入力中" : "マイクOFF - タップで音声入力開始",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            _isMicOn
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 回答入力エリア
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "あなたの回答",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 120,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _textEditingController,
                          maxLines: null,
                          expands: true,
                          decoration: InputDecoration(
                            hintText:
                                _isMicOn
                                    ? "音声認識中...話しかけてください"
                                    : "回答を入力してください（音声入力の場合はマイクボタンをタップ）",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 14),
                          enabled: !_isConversationEnd,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ボタンエリア
              Row(
                children: [
                  // 送信ボタン
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isConversationEnd ? null : _submitAnswer,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "送信",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 電話を切るボタン
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade400),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _endCallAndNavigateToResult,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call_end, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "電話を切る",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
