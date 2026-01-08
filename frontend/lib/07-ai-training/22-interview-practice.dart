import 'dart:convert';
import 'dart:math';
import 'package:bridge/11-common/60-ScreenWrapper.dart';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/59-global-method.dart';
import 'package:http/http.dart' as http;
import 'package:bridge/07-ai-training/23-interview-result.dart';
import 'package:bridge/07-ai-training/21-ai-training-list.dart';
import 'package:js/js.dart' as js;

@js.JS('speechWrapper')
external SpeechWrapper get speechWrapper;

@js.JS()
@js.staticInterop
class SpeechWrapper {}

extension SpeechWrapperExt on SpeechWrapper {
  external void start(Function onResult);
  external void stop();
}

class InterviewPractice extends StatefulWidget {
  const InterviewPractice({super.key});

  @override
  State<InterviewPractice> createState() => _InterviewPracticeState();
}

class _InterviewPracticeState extends State<InterviewPractice> {
  // --- Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController careerController = TextEditingController();

  // --- Dropdown values ---
  String? selectedIndustry;
  String? selectedScale;
  String? selectedAtmosphere;

  // --- Question count ---
  int questionCount = 5;

  // --- Review type ---
  String reviewType = "all";

  // --- Question type ---
  String selectedQuestionType = "normal";

  Map<String, dynamic>? user;
  String? _authToken; // 認証トークン
  int? _availableTokens; // ユーザーが保有するトークン数
  Map<String, dynamic> _companyInfo = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    user = await GlobalActions().loadUserSession();
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
      selectedIndustry = user!['industry'] ?? null;
      selectedScale = user!['scale'] ?? null;
      selectedAtmosphere = user!['atmosphere'] ?? null;
    }
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
                              Icons.record_voice_over,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "面接設定",
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
                    const SizedBox(height: 20),

                    // 応募先企業の情報
                    _buildSectionHeader(
                      icon: Icons.business,
                      title: "応募先企業の情報",
                    ),
                    const SizedBox(height: 12),
                    _dropdown(
                      "業界",
                      ["IT", "商社", "広告", "メーカー"],
                      selectedIndustry,
                      (v) {
                        setModalState(() => selectedIndustry = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    _dropdown(
                      "企業規模",
                      ["大企業", "中小企業", "スタートアップ"],
                      selectedScale,
                      (v) {
                        setModalState(() => selectedScale = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    _dropdown(
                      "企業の雰囲気",
                      ["堅実", "フランク", "体育会系"],
                      selectedAtmosphere,
                      (v) {
                        setModalState(() => selectedAtmosphere = v);
                      },
                    ),
                    const SizedBox(height: 20),

                    // 想定質問タイプ
                    _buildSectionHeader(icon: Icons.quiz, title: "想定する質問タイプ"),
                    const SizedBox(height: 12),
                    _buildQuestionTypeCards(setModalState, isFree),
                    const SizedBox(height: 20),

                    // その他設定
                    _buildSectionHeader(icon: Icons.settings, title: "その他設定"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "想定質問数",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    if (questionCount > 1) questionCount--;
                                  });
                                },
                                icon: Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "$questionCount",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    if (questionCount < 20) questionCount++;
                                  });
                                },
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 面接開始ボタン
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
                            "questionType": selectedQuestionType,
                            "questionCount": questionCount,
                            "reviewType": reviewType,
                            "industry": selectedIndustry,
                            "scale": selectedScale,
                            "atmosphere": selectedAtmosphere,
                          };

                          _companyInfo = {
                            "industry": selectedIndustry,
                            "scale": selectedScale,
                            "atmosphere": selectedAtmosphere,
                          };

                          final url = Uri.parse(
                            'http://localhost:8080/api/interview',
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
                              final List<dynamic> rawQuestions = jsonDecode(
                                response.body,
                              );
                              final List<String> questions = List<String>.from(
                                rawQuestions.map(
                                  (q) => q['question'] ?? q.toString(),
                                ),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => InterviewScreen(
                                        questions: questions,
                                        companyInfo: _companyInfo,
                                        questionType: selectedQuestionType,
                                      ),
                                ),
                              );
                            } else {
                              throw Exception('質問作成に失敗: ${response.body}');
                            }
                          } catch (e) {
                            print("error" + e.toString());
                            showGenericDialog(
                              context: context,
                              type: DialogType.onlyOk,
                              title: 'エラー',
                              content: '質問作成中にエラーが発生しました: $e',
                              confirmText: 'OK',
                              onConfirm: () {},
                            );
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "面接を開始する",
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
    Function(String?) onChanged,
  ) {
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
            DropdownButton<String>(
              hint: const Text("選択してください"),
              underline: const SizedBox(),
              value: items.contains(selectedValue) ? selectedValue : null,
              isExpanded: true,
              items:
                  items
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTypeCards(
    void Function(void Function()) setModalState,
    bool isFree,
  ) {
    return Column(
      children: [
        _questionTypeCard(
          setModalState,
          type: "normal",
          title: "一般質問",
          desc: "就活でよく聞かれる基本的な質問を中心に練習できます。",
          icon: Icons.chat_bubble_outline,
          premium: false,
          isFree: isFree,
        ),
        const SizedBox(height: 12),
        _questionTypeCard(
          setModalState,
          type: "casual",
          title: "カジュアル",
          desc: "雑談を交えた自然な会話形式で練習できます。",
          icon: Icons.emoji_emotions_outlined,
          premium: true,
          isFree: isFree,
        ),
        const SizedBox(height: 12),
        _questionTypeCard(
          setModalState,
          type: "pressure",
          title: "圧迫気味",
          desc: "少し緊張感のある質問で本番の緊張に慣れましょう。",
          icon: Icons.psychology_outlined,
          premium: true,
          isFree: isFree,
        ),
      ],
    );
  }

  Widget _questionTypeCard(
    void Function(void Function()) setModalState, {
    required String type,
    required String title,
    required String desc,
    required IconData icon,
    required bool premium,
    required bool isFree,
  }) {
    final bool selected = selectedQuestionType == type;

    return GestureDetector(
      onTap: () {
        if (premium && isFree) {
          showGenericDialog(
            context: context,
            type: DialogType.onlyOk,
            title: 'プレミアム限定',
            content: 'この質問タイプはプレミアム会員限定です。',
            confirmText: 'OK',
            onConfirm: () {},
          );
          return;
        }

        setModalState(() => selectedQuestionType = type);
      },
      child: Opacity(
        opacity: (premium && isFree) ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF2FF) : Colors.white,
            border: Border.all(
              color: selected ? const Color(0xFF6366F1) : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      selected ? const Color(0xFF6366F1) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                selected
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF1E293B),
                          ),
                        ),
                        if (premium)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        color:
                            selected
                                ? const Color(0xFF6366F1)
                                : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
            ],
          ),
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
            Icon(
              Icons.record_voice_over,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "面接設定が完了するとここに面接画面が表示されます",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class InterviewScreen extends StatefulWidget {
  final List<String> questions;
  final Map<String, dynamic> companyInfo;
  final String questionType;

  const InterviewScreen({
    super.key,
    required this.questions,
    required this.companyInfo,
    required this.questionType,
  });

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  int _currentQuestionIndex = 0;
  bool _isMicOn = false;
  final TextEditingController _textEditingController = TextEditingController();
  List<Map<String, dynamic>> _interviewAnswers = [];
  final GlobalActions _globalActions = GlobalActions();
  Map<String, dynamic>? _userSession;
  final Random _random = Random();
  late String _currentInterviewerImage;

  // 面接官の画像リスト
  final List<String> _interviewerImages = [
    '../lib/01-images/mensetukan1.png',
    '../lib/01-images/mensetukan2.png',
    '../lib/01-images/mensetukan3.png',
    '../lib/01-images/mensetukan4.png',
    '../lib/01-images/mensetukan5.png',
    '../lib/01-images/mensetukan6.png',
  ];

  void _loadUserSession() async {
    _userSession = await _globalActions.loadUserSession();
    setState(() {});
  }

  void _speakCurrentQuestion() {
    final currentQuestion = widget.questions[_currentQuestionIndex];
    speakWeb(currentQuestion);
  }

  // ランダムな面接官画像を選択
  void _selectRandomInterviewerImage() {
    _currentInterviewerImage =
        _interviewerImages[_random.nextInt(_interviewerImages.length)];
  }

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() {
      print("テキスト変更: ${_textEditingController.text}");
    });
    _loadUserSession();
    _selectRandomInterviewerImage();
    _speakCurrentQuestion();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _toggleMic() {
    print("[Dart] Toggle mic. Before: $_isMicOn");
    setState(() {
      _isMicOn = !_isMicOn;
      if (_isMicOn) {
        print("[Dart] Calling speechWrapper.start()");
        speechWrapper.start(
          js.allowInterop((String result) {
            // web専用コードのためエラーが出ています。気にしなくていい。
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
    if (_isMicOn) {
      setState(() {
        _isMicOn = false;
      });
    }

    String answer = _textEditingController.text;
    print("質問 ${_currentQuestionIndex + 1} への回答: $answer");

    Map<String, String> companyInfoString = widget.companyInfo.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    _interviewAnswers.add({
      "question": widget.questions[_currentQuestionIndex],
      "answer": answer,
      "companyInfo": companyInfoString,
      "questionType": widget.questionType,
    });

    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _textEditingController.clear();
        // 次の質問で新しい面接官画像を選択
        _selectRandomInterviewerImage();
        print("[Dart] InterviewPractice: テキストフィールドをクリア (次の質問へ)");
      });
      _speakCurrentQuestion();
    } else {
      print("面接終了");

      final dataToSend = _interviewAnswers;
      final prettyJson = const JsonEncoder.withIndent('  ').convert(dataToSend);
      print("送信するデータ:\n$prettyJson");

      final url = Uri.parse(
        'http://localhost:8080/api/interview/answers?questionType=${widget.questionType}',
      );
      final headers = {'Content-Type': 'application/json; charset=UTF-8'};

      try {
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(dataToSend),
        );

        if (response.statusCode == 200) {
          print("回答データ送信成功: ${response.body}");
          final Map<String, dynamic> apiResponse = jsonDecode(response.body);
          final String? content =
              apiResponse['choices']?[0]?['message']?['content'];

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

          if (content != null) {
            final RegExp regex = RegExp(r"```\s*([\s\S]*?)\s*```");
            final Match? match = regex.firstMatch(content);

            if (match != null && match.groupCount >= 1) {
              final String evaluationJsonString = match.group(1)!;
              try {
                json.decode(evaluationJsonString);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => InterviewResultPage(
                          evaluationJson: evaluationJsonString,
                        ),
                  ),
                );
              } catch (e) {
                _showErrorDialog(
                  "評価結果のJSONが不正です。",
                  "AIから返されたJSONの形式が正しくありません: $e",
                );
              }
            } else {
              try {
                json.decode(content);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            InterviewResultPage(evaluationJson: content),
                  ),
                );
              } catch (e) {
                _showErrorDialog(
                  "評価結果のJSONを抽出できませんでした。",
                  "Grok AIからの応答内容が期待される形式ではありません。エラー: $e",
                );
              }
            }
          } else {
            _showErrorDialog("Grok AIからの応答内容がありません。", "AIからの評価結果が空です。");
          }
        } else {
          _showErrorDialog(
            "回答データ送信失敗",
            "評価結果の取得に失敗しました: ${response.statusCode} - ${response.body}",
          );
        }
      } catch (e) {
        _showErrorDialog("回答データ送信中にエラーが発生しました", e.toString());
      }
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

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / widget.questions.length;

    return ScreenWrapper(
      appBar: BridgeHeader(),
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 進捗表示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "質問 ${_currentQuestionIndex + 1}/${widget.questions.length}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          "${(progress * 100).round()}%",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6366F1),
                      ),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 面接官の画像
                    Container(
                      width: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _currentInterviewerImage,
                          width: 160,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
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
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.question_answer,
                                    size: 20,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "質問",
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
                                  currentQuestion,
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
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                        onPressed: _toggleMic,
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 送信ボタン
              Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
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
                  onPressed: _submitAnswer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _currentQuestionIndex < widget.questions.length - 1
                            ? Icons.arrow_forward
                            : Icons.check,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentQuestionIndex < widget.questions.length - 1
                            ? "次の質問へ"
                            : "面接を終了する",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
