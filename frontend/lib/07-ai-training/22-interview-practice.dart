import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/59-global-method.dart';
import 'package:http/http.dart' as http;

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
  String reviewType = "each"; // each / all

  // --- Question type ---
  String selectedQuestionType = "normal"; // normal / casual / pressure

  Map<String, dynamic>? user;
  Map<String, dynamic> _companyInfo = {}; // 会社情報を保持するMap

  @override
  void initState() {
    super.initState();
    _init(); // ユーザー情報を読み込む
  }

  Future<void> _init() async {
    user = await GlobalActions().loadUserSession();
    print("userのプラン状態: ${user?['plan_status']}");

    // ユーザー情報から初期値を設定
    if (user != null) {
      nameController.text = user!['nickname'] ?? ''; // ニックネーム
      selectedIndustry = user!['industry'] ?? null; // 業界
      selectedScale = user!['scale'] ?? null; // 企業規模
      selectedAtmosphere = user!['atmosphere'] ?? null; // 企業の雰囲気
    }
    setState(() {});

    // ユーザー情報読み込み後にポップアップを表示
    Future.delayed(Duration.zero, () => _openSettingPopup());
  }

  // -------------------------------------------------------------
  // 面接設定ポップアップ
  // -------------------------------------------------------------
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "面接設定",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // あなたの情報
                    Text(
                      "あなたの情報",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _inputField("お名前", nameController),
                    SizedBox(height: 12),
                    _inputField("経歴", careerController, maxLines: 3),
                    SizedBox(height: 25),

                    // 応募先企業の情報
                    Text(
                      "応募先企業の情報",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _dropdown(
                      "業界",
                      ["IT", "商社", "広告", "メーカー"],
                      selectedIndustry,
                      (v) {
                        setModalState(() => selectedIndustry = v);
                      },
                    ),
                    SizedBox(height: 10),
                    _dropdown(
                      "企業規模",
                      ["大企業", "中小企業", "スタートアップ"],
                      selectedScale,
                      (v) {
                        setModalState(() => selectedScale = v);
                      },
                    ),
                    SizedBox(height: 10),
                    _dropdown(
                      "企業の雰囲気",
                      ["堅実", "フランク", "体育会系"],
                      selectedAtmosphere,
                      (v) {
                        setModalState(() => selectedAtmosphere = v);
                      },
                    ),
                    SizedBox(height: 25),

                    // 想定質問タイプ
                    Text(
                      "想定する質問タイプ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildQuestionTypeCards(setModalState, isFree),
                    SizedBox(height: 25),

                    // その他設定
                    Text(
                      "その他設定",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),

                    // 質問数
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("想定質問数", style: TextStyle(fontSize: 16)),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setModalState(() {
                                  if (questionCount > 1) questionCount--;
                                });
                              },
                              icon: Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              "$questionCount",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setModalState(() {
                                  if (questionCount < 20) questionCount++;
                                });
                              },
                              icon: Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // レビュー形式
                    Text(
                      "レビュー形式",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _reviewTypeButtons(setModalState),
                    SizedBox(height: 30),

                    // 面接開始ボタン
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (user == null) return;

                          final payload = {
                            "userId": user!['id'], // ユーザーID
                            "planStatus": user!['plan_status'],
                            "questionType": selectedQuestionType,
                            "questionCount": questionCount,
                            "reviewType": reviewType,
                            "industry": selectedIndustry,
                            "scale": selectedScale,
                            "atmosphere": selectedAtmosphere,
                          };

                          // 会社情報を_companyInfoに格納
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
                              ); // q['question'] が JSON の場合

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => InterviewScreen(
                                        questions: questions,
                                        companyInfo: _companyInfo, // 会社情報を渡す
                                        questionType:
                                            selectedQuestionType, // 面接タイプを渡す
                                      ),
                                ),
                              );
                            } else {
                              throw Exception('質問作成に失敗: ${response.body}');
                            }
                          } catch (e) {
                            print("error" + e.toString());
                            showDialog(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: Text("エラー"),
                                    content: Text("質問作成中にエラーが発生しました: $e"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("OK"),
                                      ),
                                    ],
                                  ),
                            );
                          }
                        },
                        child: Text("面接を開始する", style: TextStyle(fontSize: 18)),
                      ),
                    ),

                    SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------
  // UIパーツ
  // ---------------------------------------------------------
  Widget _inputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            hint: Text("選択してください"),
            underline: SizedBox(),
            value: items.contains(selectedValue) ? selectedValue : null,
            isExpanded: true,
            items:
                items
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
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
          image: "../lib/01-images/question-type-1.png",
          premium: false,
          isFree: isFree,
        ),
        SizedBox(height: 12),
        _questionTypeCard(
          setModalState,
          type: "casual",
          title: "カジュアル",
          desc: "雑談を交えた自然な会話形式で練習できます。",
          image: "../lib/01-images/question-type-2.png",
          premium: true,
          isFree: isFree,
        ),
        SizedBox(height: 12),
        _questionTypeCard(
          setModalState,
          type: "pressure",
          title: "圧迫気味",
          desc: "少し緊張感のある質問で本番の緊張に慣れましょう。",
          image: "../lib/01-images/question-type-3.png",
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
    required String image,
    required bool premium,
    required bool isFree,
  }) {
    final bool selected = selectedQuestionType == type;

    return GestureDetector(
      onTap: () {
        if (premium && isFree) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: Text("プレミアム限定"),
                  content: Text("この質問タイプはプレミアム会員限定です。"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("OK"),
                    ),
                  ],
                ),
          );
          return;
        }

        setModalState(() => selectedQuestionType = type);
      },
      child: Opacity(
        opacity: (premium && isFree) ? 0.6 : 1.0,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.blue : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 12),
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
                          ),
                        ),
                        if (premium)
                          Container(
                            margin: EdgeInsets.only(left: 6),
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
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
                    SizedBox(height: 4),
                    Text(desc, style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewTypeButtons(void Function(void Function()) setModalState) {
    return Column(
      children: [
        _reviewButton(
          setModalState,
          title: "解答ごとにレビュー",
          desc: "各質問の後にフィードバックを得れます。",
          value: "each",
        ),
        SizedBox(height: 10),
        _reviewButton(
          setModalState,
          title: "全解答後にまとめてレビュー",
          desc: "すべての質問に回答した後に、総合的なフィードバックを得れます。",
          value: "all",
        ),
      ],
    );
  }

  Widget _reviewButton(
    void Function(void Function()) setModalState, {
    required String title,
    required String desc,
    required String value,
  }) {
    final bool selected = reviewType == value;

    return GestureDetector(
      onTap: () => setModalState(() => reviewType = value),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Colors.blue : Colors.grey,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // 画面本体
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Center(
        child: Text("面接設定が完了するとここに面接画面が表示されます", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

class InterviewScreen extends StatefulWidget {
  final List<String> questions;
  final Map<String, dynamic> companyInfo; // 会社情報を追加
  final String questionType; // 面接タイプを追加

  const InterviewScreen({
    super.key,
    required this.questions,
    required this.companyInfo, // 会社情報を必須にする
    required this.questionType, // 面接タイプを必須にする
  });

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  int _currentQuestionIndex = 0;
  bool _isMicOn = false;
  final TextEditingController _textEditingController = TextEditingController();
  String _transcribedText = ""; // リアルタイム文字起こし用
  List<Map<String, dynamic>> _interviewAnswers = []; // 質問、回答、会社情報を保持するリスト

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _toggleMic() {
    setState(() {
      _isMicOn = !_isMicOn;
      if (!_isMicOn) {
        // マイクオフになったら文字起こしをリセット
        _transcribedText = "";
      }
    });
    // TODO: 実際の音声認識の開始/停止ロジックをここに追加
    print("マイクの状態: ${_isMicOn ? 'ON' : 'OFF'}");
  }

  void _submitAnswer() async {
    String answer = _isMicOn ? _transcribedText : _textEditingController.text;
    print("質問 ${_currentQuestionIndex + 1} への回答: $answer");

    // companyInfo を Map<String, String> に変換
    Map<String, String> companyInfoString = widget.companyInfo.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    _interviewAnswers.add({
      "question": widget.questions[_currentQuestionIndex],
      "answer": answer,
      "companyInfo": companyInfoString, // 変換した companyInfo を使用
      "questionType": widget.questionType, // 面接タイプを追加
    });

    // 次の質問へ
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _textEditingController.clear();
        _transcribedText = "";
        _isMicOn = false;
      });
    } else {
      // 全質問が終了したら送信
      print("面接終了");

      // AnswerDTO のリストとして送信するため、_interviewAnswers をそのまま使用
      final dataToSend = _interviewAnswers;

      // JSONを整形してログに出力
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
        } else {
          print("回答データ送信失敗: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        print("回答データ送信中にエラーが発生しました: $e");
      }

      Navigator.pop(context);
    }
  }

  // ダミーの文字起こし機能
  void _simulateTranscription(String input) {
    if (_isMicOn) {
      setState(() {
        _transcribedText = input;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: const Text("面接練習")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 面接官の画像
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    '../lib/01-images/mensetukan.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      currentQuestion, // 質問文を表示
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // マイクボタンとON/OFF表示
            Center(
              child: Column(
                children: [
                  IconButton(
                    icon: Icon(
                      _isMicOn ? Icons.mic : Icons.mic_off,
                      size: 60,
                      color: _isMicOn ? Colors.red : Colors.grey,
                    ),
                    onPressed: _toggleMic,
                  ),
                  Text(
                    _isMicOn ? "マイクON" : "マイクOFF",
                    style: TextStyle(
                      fontSize: 16,
                      color: _isMicOn ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // テキスト入力フィールド / 文字起こし表示
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child:
                    _isMicOn
                        ? SingleChildScrollView(
                          child: Text(
                            _transcribedText.isEmpty
                                ? "マイク入力中..."
                                : _transcribedText,
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                        : TextField(
                          controller: _textEditingController,
                          maxLines: null, // 複数行入力可能
                          expands: true, // 高さを自動調整
                          decoration: const InputDecoration(
                            hintText: "回答を入力してください...",
                            border: InputBorder.none,
                          ),
                          onChanged: _simulateTranscription, // ダミーの文字起こし
                        ),
              ),
            ),
            const SizedBox(height: 20),

            // 送信ボタン
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitAnswer,
                child: const Text("送信", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
