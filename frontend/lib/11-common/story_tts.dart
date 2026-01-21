import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class StoryTTS {
  static final StoryTTS _instance = StoryTTS._internal();

  factory StoryTTS() {
    return _instance;
  }

  StoryTTS._internal();

  bool _isSpeaking = false;
  Completer<void>? _currentCompleter;

  bool get isSpeaking => _isSpeaking;

  /// 物語用の読み上げメソッド
  /// - レート: 1.5倍速
  /// - 音量: 最大
  /// - ピッチ: 1.0（通常）
  /// - 言語: 日本語
  Future<void> speakStoryLine(
    String text, {
    double rate = 1.5,
    double volume = 1.0,
    double pitch = 1.0,
  }) async {
    if (!kIsWeb) return;
    if (text.isEmpty) return;

    // スキップ対象のテキストをフィルタ
    if (_shouldSkipText(text)) return;

    // テキストクリーニング
    final cleanText = _cleanText(text);
    if (cleanText.isEmpty) return;

    // すでに話している場合は待機
    if (_isSpeaking) {
      await _currentCompleter?.future;
    }

    _isSpeaking = true;
    _currentCompleter = Completer<void>();

    try {
      await _executeStoryTTS(cleanText, rate, volume, pitch);
    } finally {
      _isSpeaking = false;
      if (_currentCompleter?.isCompleted == false) {
        _currentCompleter?.complete();
      }
      _currentCompleter = null;
    }
  }

  /// 読み上げをキャンセル
  void cancel() {
    try {
      final speechSynthesis = html.window as dynamic;
      if (speechSynthesis.speechSynthesis != null) {
        speechSynthesis.speechSynthesis.cancel();
      }
    } catch (e) {
      print('Cancel error: $e');
    }
    _isSpeaking = false;
    if (_currentCompleter?.isCompleted == false) {
      _currentCompleter?.complete();
    }
  }

  /// テキストをスキップすべきかチェック
  bool _shouldSkipText(String text) {
    // 章タイトル
    if (text.startsWith("第") && text.contains("章")) return true;
    // 終了マーク
    if (text == "完") return true;
    // サブタイトル
    if (text.contains("〜虚飾のサイゼリアと、ニンニクの逆襲〜")) return true;

    return false;
  }

  /// テキストのクリーニング
  String _cleanText(String text) {
    return text
        .replaceAll("\n", " ")
        .replaceAll("\r", " ")
        .replaceAll("  ", " ")
        .trim();
  }

  /// JavaScriptを使用した読み上げ実行
  Future<void> _executeStoryTTS(
    String text,
    double rate,
    double volume,
    double pitch,
  ) async {
    final completer = Completer<void>();
    bool eventFired = false;

    // イベントリスナーをまず登録
    late html.EventListener listener;
    listener = (event) {
      if (!eventFired) {
        eventFired = true;
        html.window.removeEventListener('storyTTSDone', listener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    };

    html.window.addEventListener('storyTTSDone', listener);

    try {
      // JavaScript実行用のスクリプト要素を作成
      final script = html.ScriptElement();
      script.text = _generateJavaScript(text, rate, volume, pitch);
      html.document.body?.append(script);

      // スクリプトの実行完了を待つ
      await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('Story TTS timeout');
          if (!eventFired) {
            eventFired = true;
            html.window.removeEventListener('storyTTSDone', listener);
          }
        },
      );

      // スクリプト要素を削除
      try {
        script.remove();
      } catch (_) {}
    } catch (e) {
      print('StoryTTS execution error: $e');
      if (!eventFired) {
        eventFired = true;
        html.window.removeEventListener('storyTTSDone', listener);
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  /// JavaScriptコードの生成
  String _generateJavaScript(
    String text,
    double rate,
    double volume,
    double pitch,
  ) {
    return """
(function() {
  try {
    var textToSpeak = ${jsonEncode(text)};
    var rate = $rate;
    var volume = $volume;
    var pitch = $pitch;

    // 前の読み上げをキャンセル
    if (window.speechSynthesis) {
      window.speechSynthesis.cancel();
    }

    // 少し待ってから実行（キャンセルが完了するため）
    setTimeout(function() {
      try {
        var utterThis = new SpeechSynthesisUtterance(textToSpeak);
        utterThis.lang = "ja-JP";
        utterThis.rate = rate;
        utterThis.pitch = pitch;
        utterThis.volume = volume;

        utterThis.onend = function() {
          window.dispatchEvent(new Event("storyTTSDone"));
        };

        utterThis.onerror = function(error) {
          console.error("Speech synthesis error:", error);
          window.dispatchEvent(new Event("storyTTSDone"));
        };

        if (window.speechSynthesis) {
          window.speechSynthesis.speak(utterThis);
        } else {
          console.error("Speech synthesis not available");
          window.dispatchEvent(new Event("storyTTSDone"));
        }
      } catch (innerError) {
        console.error("Inner error:", innerError);
        window.dispatchEvent(new Event("storyTTSDone"));
      }
    }, 50);
  } catch (error) {
    console.error("StoryTTS error:", error);
    window.dispatchEvent(new Event("storyTTSDone"));
  }
})();
""";
  }
}
