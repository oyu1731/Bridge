import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import 'story_data.dart'; // 物語データをインポート

class HiddenPage extends StatefulWidget {
  const HiddenPage({Key? key}) : super(key: key);

  @override
  State<HiddenPage> createState() => _HiddenPageState();
}

class _HiddenPageState extends State<HiddenPage> {
  int _tapCount = 0;

  final List<String> _previewLines = [
    "左上のロゴを、あなたは何度もタップした。",
    "戻るでもなく、進むでもなく、ただの「確認行動」。",
    "だがその一つ一つは、もう記録されている。",
    "回数、間隔、迷いの長さ。すべてが、あなたの輪郭になる。",
    "あなたは今、自分でも気づかないうちに「選別される側」に立っている。",
    "これはバグでも裏技でもない。",
    "これは、観測される人間の物語への入口だ。",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 300,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tapCount > 7 ? 7 : _tapCount,
                    itemBuilder: (context, index) {
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 800),
                        opacity: 1.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _previewLines[index],
                            style: TextStyle(
                              color:
                                  index == _tapCount - 1
                                      ? const Color(0xFF818CF8)
                                      : Colors.white70,
                              fontSize: 16,
                              letterSpacing: 0.5,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_tapCount < 7) {
                        _tapCount++;
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AutoStoryPage(),
                          ),
                        );
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors:
                            _tapCount < 7
                                ? [
                                  const Color(0xFF334155),
                                  const Color(0xFF1E293B),
                                ]
                                : [
                                  const Color(0xFF6366F1),
                                  const Color(0xFF8B5CF6),
                                ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              _tapCount < 7
                                  ? Colors.black26
                                  : const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _tapCount < 7 ? '$_tapCount / 7' : 'OPEN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   AutoStoryPage
========================================================= */

class AutoStoryPage extends StatefulWidget {
  const AutoStoryPage({Key? key}) : super(key: key);

  @override
  State<AutoStoryPage> createState() => _AutoStoryPageState();
}

class _AutoStoryPageState extends State<AutoStoryPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  bool _isAutoScrolling = true;
  double _scrollSpeed = 100.0;
  int _currentChapterIndex = 0;
  bool _isVoiceEnabled = true;
  int _currentReadIndex = -1;
  bool _isSpeaking = false;

  int _flowId = 0;
  int _pendingResumeIndex = -1;

  final List<String> _fullStory = StoryData.fullStory;

  late final List<Map<String, Color>> _chapterColors = [
    {'bg': const Color(0xFFF8F9FA), 'text': const Color(0xFF334155)},
    {'bg': const Color(0xFFF1F5F9), 'text': const Color(0xFF1E293B)},
    {'bg': const Color(0xFFE2E8F0), 'text': const Color(0xFF0F172A)},
    {'bg': const Color(0xFFCBD5E1), 'text': const Color(0xFF0F172A)},
    {'bg': const Color(0xFF94A3B8), 'text': const Color(0xFF020617)},
    {'bg': const Color(0xFF475569), 'text': const Color(0xFFF8FAFC)},
    {'bg': const Color(0xFF1E293B), 'text': const Color(0xFFF1F5F9)},
    {'bg': const Color(0xFF0F172A), 'text': const Color(0xFFCBD5E1)},
    {'bg': const Color(0xFF020617), 'text': const Color(0xFF94A3B8)},
  ];

  final List<double> _speedOptions = [100.0, 150.0, 200.0, 300.0];
  int _currentSpeedIndex = 0;

  /// ★ SafeAreaを考慮した読み上げ基準Y座標（PC / スマホ共通）
  double _getCursorTargetY(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeHeight =
        media.size.height - media.padding.top - media.padding.bottom;

    return media.padding.top + safeHeight * 0.35;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0);
      if (_isAutoScrolling && _isVoiceEnabled) {
        _startReadingFlow(0);
      }
    });
    _scrollController.addListener(_updateChapterIndex);
  }

  @override
  void dispose() {
    _stopAllProcesses();
    _scrollController.removeListener(_updateChapterIndex);
    _scrollController.dispose();
    super.dispose();
  }

  void _stopAllProcesses() {
    _flowId++;
    _stopVoice();
  }

  /* ===== 読み上げ・スクロール連動 ===== */

  Future<void> _startReadingFlow(int startIndex) async {
    _flowId++;
    final int currentSyncId = _flowId;

    for (int i = startIndex; i < _fullStory.length; i++) {
      if (currentSyncId != _flowId || !_isAutoScrolling || !_isVoiceEnabled)
        break;

      final line = _fullStory[i];

      if (line.startsWith("<<IMAGE:")) {
        final fileName = line.replaceAll("<<IMAGE:", "").replaceAll(">>", "");
        final bool isFinal = fileName == "story_last.jpg";

        _pendingResumeIndex = i + 1;

        await Future.delayed(const Duration(milliseconds: 400));
        _showStoryImage(fileName, isFinal);
        break;
      }

      await _readAndScroll(i, currentSyncId);
      if (currentSyncId != _flowId) break;
    }
  }

  Future<void> _readAndScroll(int index, int syncId) async {
    if (!mounted || syncId != _flowId) return;

    setState(() {
      _currentReadIndex = index;
      _isSpeaking = true;
      _currentChapterIndex = _calculateChapterIndexFromLine(index);
    });

    await _scrollLineToCursorPosition(index);
    if (syncId != _flowId) return;

    await Future.delayed(const Duration(milliseconds: 200));
    await _speakLineAsync(_fullStory[index]);

    if (mounted && syncId == _flowId) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  /// ★ 修正済み：SafeArea対応スクロール
  Future<void> _scrollLineToCursorPosition(int index) async {
    if (!_scrollController.hasClients || !mounted) return;

    final double cursorPositionY = _getCursorTargetY(context);

    double cumulativeHeight = 0;
    for (int i = 0; i < index; i++) {
      cumulativeHeight += _calculateLineHeight(i);
    }

    final double targetOffset =
        cumulativeHeight - cursorPositionY + (_calculateLineHeight(index) / 2);

    await _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  int _calculateChapterIndexFromLine(int lineIndex) {
    int chapter = 0;
    for (int i = 0; i <= lineIndex && i < _fullStory.length; i++) {
      final line = _fullStory[i];
      if ((line.startsWith("第") && line.contains("章")) ||
          (line.startsWith("終章"))) {
        chapter++;
      }
    }
    return (chapter - 1).clamp(0, _chapterColors.length - 1);
  }

  double _calculateLineHeight(int index) {
    final line = _fullStory[index];
    if (line.startsWith("第") || line.startsWith("終") && line.contains("章"))
      return 160.0;
    if (line == "完") return 180.0;
    if (index == 0 || line.contains("〜")) return 200.0;
    return 120.0;
  }
  /* ===== 画像モーダル ===== */

  void _showStoryImage(String imagePath, bool isFinal) {
    _stopVoice();
    _flowId++;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;

        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: screenSize.height * 0.7,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.asset(
                        '../lib/01-images/$imagePath',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      if (isFinal) {
                        _showFinalMessage();
                      } else {
                        if (_isAutoScrolling &&
                            _isVoiceEnabled &&
                            _pendingResumeIndex >= 0) {
                          _startReadingFlow(_pendingResumeIndex);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      minimumSize: const Size(120, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isFinal ? "最後へ" : "閉じる",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /* ===== 最終メッセージ ===== */

  void _showFinalMessage() {
    const fullText =
        "この物語は、フィクションです。\n"
        "でも、あなたが今ここにいることだけは、現実です。\n\n"
        "画面の向こう側で誰かが観測し、\n"
        "こちら側であなたが選び続けてきました。\n\n"
        "では、質問です。\n\n"
        "この物語を閉じたあと、\n"
        "あなたの次の行動は、\n"
        "誰が決めるのでしょうか。";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _FinalTypingDialog(fullText: fullText);
      },
    );
  }

  /* ===== UI ===== */

  Widget _buildStoryLine(String line, int index) {
    if (line.startsWith("<<IMAGE:")) {
      return const SizedBox.shrink();
    }

    final currentColor =
        _chapterColors[_currentChapterIndex >= _chapterColors.length
            ? 0
            : _currentChapterIndex];
    final textColor = currentColor['text']!;
    final isCurrentLine = index == _currentReadIndex;

    Widget lineContent;

    if (line.startsWith("第") || line.startsWith("終") && line.contains("章")) {
      lineContent = Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor.withOpacity(0.3), width: 2),
          ),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      lineContent = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border:
                isCurrentLine && _isSpeaking
                    ? Border.all(color: textColor.withOpacity(0.5), width: 2)
                    : null,
          ),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 18,
              height: 1.8,
              color: textColor,
              fontWeight:
                  isCurrentLine && _isSpeaking
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onLineTapped(index),
      child: lineContent,
    );
  }

  void _onLineTapped(int index) async {
    _stopAllProcesses();
    setState(() => _isSpeaking = false);
    await Future.delayed(const Duration(milliseconds: 100));

    await _scrollLineToCursorPosition(index);
    setState(() => _currentReadIndex = index);

    if (_isAutoScrolling && _isVoiceEnabled) {
      _startReadingFlow(index);
    }
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
      if (_isAutoScrolling && _isVoiceEnabled) {
        _startReadingFlow(_currentReadIndex >= 0 ? _currentReadIndex : 0);
      } else {
        _stopAllProcesses();
      }
    });
  }

  void _toggleVoice() {
    setState(() {
      _isVoiceEnabled = !_isVoiceEnabled;
      if (_isVoiceEnabled && _isAutoScrolling) {
        _startReadingFlow(_currentReadIndex >= 0 ? _currentReadIndex : 0);
      } else {
        _stopAllProcesses();
      }
    });
  }

  void _updateChapterIndex() {
    if (_currentReadIndex < 0) return;
    final newIndex = _calculateChapterIndexFromLine(_currentReadIndex);
    if (newIndex != _currentChapterIndex) {
      setState(() => _currentChapterIndex = newIndex);
    }
  }

  void _stopVoice() {
    try {
      js.context.callMethod('eval', ["speechSynthesis.cancel();"]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentColor =
        _chapterColors[_currentChapterIndex >= _chapterColors.length
            ? 0
            : _currentChapterIndex];

    return Scaffold(
      backgroundColor: currentColor['bg']!,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 100),
              child: Column(
                children: [
                  ..._fullStory
                      .asMap()
                      .entries
                      .map((e) => _buildStoryLine(e.value, e.key))
                      .toList(),
                  const SizedBox(height: 300),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 320,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous,
                        color: currentColor['text'],
                      ),
                      onPressed: () => _onLineTapped(0),
                    ),
                    IconButton(
                      icon: Icon(
                        _isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
                        color:
                            _isVoiceEnabled
                                ? const Color(0xFF6366F1)
                                : currentColor['text'],
                      ),
                      onPressed: _toggleVoice,
                    ),
                    IconButton(
                      icon: Icon(
                        _isAutoScrolling ? Icons.pause : Icons.play_arrow,
                        color: currentColor['text'],
                        size: 28,
                      ),
                      onPressed: _toggleAutoScroll,
                    ),
                    IconButton(
                      icon: Icon(Icons.home, color: currentColor['text']),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===== 最終タイピングダイアログ ===== */

class _FinalTypingDialog extends StatefulWidget {
  final String fullText;
  const _FinalTypingDialog({required this.fullText});

  @override
  State<_FinalTypingDialog> createState() => _FinalTypingDialogState();
}

class _FinalTypingDialogState extends State<_FinalTypingDialog> {
  String _visibleText = "";
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_index < widget.fullText.length) {
        setState(() {
          _visibleText += widget.fullText[_index];
          _index++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      title: const Text("読者の皆様へ", style: TextStyle(color: Colors.white)),
      content: Text(
        _visibleText,
        style: const TextStyle(color: Colors.white70, height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("閉じる"),
        ),
      ],
    );
  }
}

/* ===== Web Speech ===== */

Future<void> speakWebFixed(
  String text, {
  double pitch = 1.0,
  double rate = 1.0,
  double volume = 1.0,
}) async {
  if (!kIsWeb) return;

  final completer = Completer<void>();
  final script =
      html.ScriptElement()
        ..text = """
(function() {
  var utter = new SpeechSynthesisUtterance(${jsonEncode(text)});
  utter.lang = 'ja-JP';
  utter.rate = $rate;
  utter.onend = function() {
    window.dispatchEvent(new Event('flutterSpeechDone'));
  };
  speechSynthesis.cancel();
  speechSynthesis.speak(utter);
})();
""";

  html.document.body?.append(script);

  late html.EventListener listener;
  listener = (_) {
    html.window.removeEventListener('flutterSpeechDone', listener);
    script.remove();
    if (!completer.isCompleted) completer.complete();
  };

  html.window.addEventListener('flutterSpeechDone', listener);
  await completer.future;
}
