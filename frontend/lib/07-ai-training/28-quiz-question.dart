import 'package:flutter/material.dart';
import 'dart:convert'; // JSONをデコードするために必要
import 'package:flutter/services.dart' show rootBundle; // rootBundleを使用するために必要
import 'package:bridge/11-common/58-header.dart'; // BridgeHeader を使用するため追加
import 'package:bridge/11-common/59-global-method.dart'; // showGenericDialog を使用するため
import '29-quiz-explanation.dart';
import '30-quiz-score.dart';

class QuizScreen extends StatefulWidget {
  final int questionCount;
  final String courseType;

  const QuizScreen({
    super.key,
    required this.questionCount,
    required this.courseType,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  List<bool?> _userAnswers = [];
  bool _isEndlessMode = false;
  List<Map<String, dynamic>> _quizData = []; // 初期化は空のリストに

  @override
  void initState() {
    super.initState();
    _loadQuizData(); // クイズデータをロード
    _isEndlessMode = widget.questionCount == 0;
  }

  Future<void> _loadQuizData() async {
    try {
      final String response = await rootBundle.loadString(
        'lib/07-ai-training/quiz_data.json',
      );
      final List<dynamic> data = json.decode(response);
      setState(() {
        _quizData = data.cast<Map<String, dynamic>>();
        _userAnswers = List.filled(
          _isEndlessMode ? _quizData.length : widget.questionCount,
          null,
        );
      });
    } catch (e) {
      print('Error loading quiz data: $e');
      // エラー処理をここに追加することもできます (例: エラーメッセージの表示)
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizData.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // データロード中はローディングインジケータを表示
        ),
      );
    }

    final currentQuestion = _getCurrentQuestion();

    return Scaffold(
      appBar: BridgeHeader(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 進捗表示
            if (!_isEndlessMode) ...[
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / widget.questionCount,
                backgroundColor: Colors.grey[300],
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
            ],

            // 問題番号
            Text(
              _isEndlessMode
                  ? '問題 ${_currentQuestionIndex + 1}'
                  : '問題 ${_currentQuestionIndex + 1}/${widget.questionCount}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 問題文
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentQuestion['question'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // マルバツボタン
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _answerQuestion(true),
                    icon: const Icon(Icons.check, size: 30),
                    label: const Text('マル', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _answerQuestion(false),
                    icon: const Icon(Icons.close, size: 30),
                    label: const Text('バツ', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // コース選択に戻るボタン
            OutlinedButton(
              onPressed: _showReturnConfirmation,
              child: const Text('コース選択に戻る'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getCurrentQuestion() {
    if (_quizData.isEmpty) {
      return {
        'question': '問題データをロード中...',
        'answer': false, // 仮の値
        'explanation': 'データを読み込んでいます。',
      };
    }
    if (_isEndlessMode) {
      // エンドレスモードでは問題をループ
      return _quizData[_currentQuestionIndex % _quizData.length];
    } else {
      // 通常モードでは問題を順番に
      return _currentQuestionIndex < _quizData.length
          ? _quizData[_currentQuestionIndex]
          : {
            'question': '追加の問題データが必要です',
            'answer': true,
            'explanation': '問題データを追加してください',
          };
    }
  }

  void _answerQuestion(bool userAnswer) {
    if (_quizData.isEmpty) return; // データがロードされていない場合は何もしない

    setState(() {
      _userAnswers[_currentQuestionIndex] = userAnswer;
    });

    // 解答解説画面へ遷移
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AnswerExplanationScreen(
              question: _getCurrentQuestion(),
              userAnswer: userAnswer,
              questionNumber: _currentQuestionIndex + 1,
              totalQuestions: _isEndlessMode ? null : widget.questionCount,
              courseType: widget.courseType,
              onNext: _goToNextQuestion,
              onFinish: _goToResult,
            ),
      ),
    );
  }

  void _goToNextQuestion() {
    setState(() {
      _currentQuestionIndex++;

      // エンドレスモードで問題データが足りない場合に拡張
      if (_isEndlessMode && _currentQuestionIndex >= _userAnswers.length) {
        // _userAnswers.length を _quizData.length の倍数に拡張
        // 例: _quizData.length が 3 で、 _userAnswers.length が 3 になった場合、
        // 次の問題は _quizData[0] になるため、_userAnswers を 1つ追加
        _userAnswers.add(null);
      }
    });

    Navigator.pop(context); // 解答画面を閉じる
  }

  void _goToResult() {
    final correctAnswers = _calculateCorrectAnswers();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => ResultScreen(
              totalQuestions:
                  _isEndlessMode
                      ? _currentQuestionIndex + 1
                      : widget.questionCount,
              correctAnswers: correctAnswers,
              courseType: widget.courseType,
            ),
      ),
    );
  }

  int _calculateCorrectAnswers() {
    int correct = 0;
    for (int i = 0; i < _userAnswers.length; i++) {
      if (i < _quizData.length &&
          _userAnswers[i] == _quizData[i % _quizData.length]['answer']) {
        // エンドレスモード対応
        correct++;
      }
    }
    return correct;
  }

  void _showReturnConfirmation() {
    showGenericDialog(
      context: context,
      type: DialogType.yesNo,
      title: '確認',
      content: 'コース選択画面に戻りますか？\n現在の進捗は失われます。',
      confirmText: 'はい',
      cancelText: 'キャンセル',
      onConfirm: () {
        Navigator.pop(context); // コース選択画面に戻る
      },
      onCancel: () {},
    );
  }
}
