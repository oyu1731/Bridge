import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // ota1128
import 'dart:js' as js; // ota1128
import 'package:http/http.dart' as http; // ota1128
import 'package:bridge/06-company/api_config.dart'; // ota1128
import 'package:share_plus/share_plus.dart'; // ota1128
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cross_file/cross_file.dart';

// Web専用API（画像を新しいタブで開く、クリップボードにコピー）
import 'dart:typed_data';
import 'dart:html' as html;

class GlobalActions {
  /// ユーザーセッション情報をSharedPreferencesから取得
  Future<Map<String, dynamic>?> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('current_user');

    if (jsonString != null) {
      final Map<String, dynamic> user = jsonDecode(jsonString);
      print('セッションから取得: $user');
      return user; // ✅ Map を返す
    } else {
      print('セッションにユーザー情報はありません');
      return null; // ✅ 見つからない場合は null
    }
  }

  /// SharedPreferencesからトークンを取得
  Future<String?> loadAuthToken() async {
    print("トークン取得メソッドを実行");
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token'); // 'auth_token' キーを使用
    if (token != null) {
      print('セッションから認証トークンを取得: $token');
      return token;
    } else {
      print('セッションに認証トークン情報はありません');
      return null;
    }
  }

  /// SharedPreferencesに保存されている全てのキーをリストアップ（デバッグ用）
  Future<Set<String>> getAllSharedPreferencesKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys();
  }

  // 文字列から色を生成するヘルパーメソッド
  static Color getColorFromName(String name) {
    // シンプルなハッシュ関数で色を生成
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // 生成されたハッシュ値から色を調整
    final int red = (hash & 0xFF0000) >> 16;
    final int green = (hash & 0x00FF00) >> 8;
    final int blue = (hash & 0x0000FF);

    return Color.fromRGBO(red, green, blue, 1.0);
  }

  /// 音声設定をSharedPreferencesに保存
  Future<void> saveVoiceSetting(String voiceName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_voice_name', voiceName);
    print('音声設定を保存しました: $voiceName');
  }

  /// 音声設定をSharedPreferencesから取得
  Future<String?> loadVoiceSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final String? voiceName = prefs.getString('selected_voice_name');
    if (voiceName != null) {
      print('セッションから音声設定を取得: $voiceName');
      return voiceName;
    } else {
      print('セッションに音声設定はありません');
      return null;
    }
  }

  /// 音声のトーンをSharedPreferencesに保存
  Future<void> saveVoicePitch(double pitch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('selected_voice_pitch', pitch);
    print('音声トーンを保存しました: $pitch');
  }

  /// 音声のトーンをSharedPreferencesから取得
  Future<double?> loadVoicePitch() async {
    final prefs = await SharedPreferences.getInstance();
    final double? pitch = prefs.getDouble('selected_voice_pitch');
    if (pitch != null) {
      print('セッションから音声トーンを取得: $pitch');
      return pitch;
    } else {
      print('セッションに音声トーン情報はありません');
      return null;
    }
  }

  /// 音声の速さをSharedPreferencesに保存
  Future<void> saveVoiceRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('selected_voice_rate', rate);
    print('音声速さを保存しました: $rate');
  }

  /// 音声の速さをSharedPreferencesから取得
  Future<double?> loadVoiceRate() async {
    final prefs = await SharedPreferences.getInstance();
    final double? rate = prefs.getDouble('selected_voice_rate');
    if (rate != null) {
      print('セッションから音声速さを取得: $rate');
      return rate;
    } else {
      print('セッションに音声速さ情報はありません');
      return null;
    }
  }

  /// 音声の大きさをSharedPreferencesに保存
  Future<void> saveVoiceVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('selected_voice_volume', volume);
    print('音声の大きさを保存しました: $volume');
  }

  /// 音声の大きさをSharedPreferencesから取得
  Future<double?> loadVoiceVolume() async {
    final prefs = await SharedPreferences.getInstance();
    final double? volume = prefs.getDouble('selected_voice_volume');
    if (volume != null) {
      print('セッションから音声の大きさを取得: $volume');
      return volume;
    } else {
      print('セッションに音声の大きさ情報はありません');
      return null;
    }
  }

  /// ユーザーIDに基づいて最新のトークン数を取得
  Future<int?> fetchUserTokens(int userId) async {
    print("--- fetchUserTokens開始 ---");
    try {
      final apiUrl = '${ApiConfig.baseUrl}/api/users/$userId';
      print("トークン取得を開始します。ユーザーID: $userId, URL: $apiUrl");
      final response = await http.get(Uri.parse(apiUrl));

      print("レスポンスステータスコード: ${response.statusCode}");

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> userData = jsonDecode(response.body);

          // --- デバッグ用ログ追加 ---
          print("レスポンスボディ (JSON): ${response.body}");

          if (userData.containsKey('token')) {
            final tokenValue = userData['token'];
            print("取得したトークン数: $tokenValue (型: ${tokenValue.runtimeType})");

            // トークンがnullの場合もint?型で返す
            return tokenValue as int?;
          } else {
            print("!! 警告: レスポンスJSONに 'token' キーが存在しません。!!");
            return null;
          }
        } on FormatException catch (e) {
          print('JSONデコードエラー: $e');
          print('無効なレスポンスボディ: ${response.body}');
          return null;
        }
      } else {
        print('ユーザー情報取得エラー: ${response.statusCode} - ${response.reasonPhrase}');
        print('エラーボディ: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ユーザー情報取得中にネットワークまたは処理エラーが発生しました: $e');
      return null;
    } finally {
      print("--- fetchUserTokens終了 ---");
    }
  }

  /// ユーザーのトークンを減らす
  Future<bool> deductUserTokens(int userId, int tokensToDeduct) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/users/$userId/deduct-tokens?tokensToDeduct=$tokensToDeduct',
        ),
      );

      if (response.statusCode == 200) {
        print('トークン消費成功: $tokensToDeduct');
        return true;
      } else {
        print('トークン消費失敗: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('トークン消費中にエラーが発生しました: $e');
      return false;
    }
  }
} // GlobalActions クラスの閉じ括弧

/// ダイアログのボタンパターン定義
enum DialogType {
  onlyOk, // OKボタンのみ（通知・完了など）
  yesNo, // はい・いいえ（確認など）
}

/// 汎用ダイアログを表示する関数
Future<void> showGenericDialog({
  required BuildContext context,
  required DialogType type, // ボタンのパターン指定
  required String title, // タイトル
  required String content, // 本文
  String confirmText = 'OK', // OKボタンの文字（デフォルト: OK）
  String cancelText = 'キャンセル', // キャンセルボタンの文字（デフォルト: キャンセル）
  Color confirmColor = Colors.blue, // OKボタンの色（デフォルト: 青）
  VoidCallback? onConfirm, // OKを押した時の処理
  VoidCallback? onCancel, // キャンセルを押した時の処理
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false, // 外側タップで閉じない
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.4, // 横幅を40%に設定
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // --- タイトル ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // --- 本文 ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(content, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 24),

                // --- ボタンエリア（タイプによって分岐） ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child:
                      type == DialogType.onlyOk
                          ? _buildSingleButton(
                            context,
                            confirmText,
                            confirmColor,
                            onConfirm,
                          )
                          : _buildDoubleButtons(
                            context,
                            confirmText,
                            cancelText,
                            confirmColor,
                            onConfirm,
                            onCancel,
                          ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// 数字入力ダイアログを表示する関数
Future<void> showNumberInputDialog({
  required BuildContext context,
  required String title,
  required String message,
  required Function(int) onConfirm,
  int initialValue = 10,
  int minValue = 1,
  int maxValue = 100,
  String confirmText = '開始',
  String cancelText = 'キャンセル',
}) async {
  int selectedValue = initialValue;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(message, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              if (selectedValue > minValue) {
                                selectedValue--;
                              }
                            });
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Container(
                          width: 80,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$selectedValue',
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              if (selectedValue < maxValue) {
                                selectedValue++;
                              }
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              elevation: 5,
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: Text(
                                cancelText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              elevation: 5,
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              onConfirm(selectedValue);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              child: Text(
                                confirmText,
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
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

// --- 内部用：ボタン1つの場合（OKのみ） ---
Widget _buildSingleButton(
  BuildContext context,
  String text,
  Color color,
  VoidCallback? onConfirm,
) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      elevation: 5,
      shape: const StadiumBorder(),
    ),
    onPressed: () {
      Navigator.pop(context); // 閉じる
      if (onConfirm != null) onConfirm(); // 処理実行
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

// --- 内部用：ボタン2つの場合（YES / NO） ---
Widget _buildDoubleButtons(
  BuildContext context,
  String confirmText,
  String cancelText,
  Color confirmColor,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      // キャンセルボタン（左）
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          elevation: 5,
          shape: const StadiumBorder(),
        ),
        onPressed: () {
          Navigator.pop(context); // 閉じる
          if (onCancel != null) onCancel();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            cancelText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // 実行ボタン（右）
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: confirmColor,
          elevation: 5,
          shape: const StadiumBorder(),
        ),
        onPressed: () {
          Navigator.pop(context); // 閉じる
          if (onConfirm != null) onConfirm();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: Text(
            confirmText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}

/// Webブラウザでテキストを読み上げる関数
Future<void> speakWeb(
  String text, {
  String? voiceName,
  double? pitch,
  double? rate,
  double? volume, // volume パラメータを追加
}) async {
  try {
    final GlobalActions globalActions = GlobalActions();
    // 引数で指定がない場合はSharedPreferencesからロード
    final String? targetVoiceName =
        voiceName ?? await globalActions.loadVoiceSetting();
    final double targetPitch =
        pitch ?? await globalActions.loadVoicePitch() ?? 1.0; // デフォルト値 1.0
    final double targetRate =
        rate ?? await globalActions.loadVoiceRate() ?? 0.5; // デフォルト値 0.5
    final double targetVolume =
        volume ?? await globalActions.loadVoiceVolume() ?? 1.0; // デフォルト値 1.0

    var jsCode = """
var textToSpeak = "$text";
var selectedVoiceName = ${targetVoiceName != null ? '"$targetVoiceName"' : 'null'};
var selectedPitch = $targetPitch;
var selectedRate = $targetRate;
var selectedVolume = $targetVolume; // JavaScript変数にvolumeを追加

var voices = speechSynthesis.getVoices();
var selectedVoice = null;

if (selectedVoiceName) {
    selectedVoice = voices.find(v => v.name === selectedVoiceName);
}

// 保存された音声が見つからない場合や、デフォルトの日本語音声がない場合
if (!selectedVoice) {
    // 日本語のデフォルト音声を検索 (以前のロジック)
    var japaneseVoiceNames = [
        'Microsoft Ayumi - Japanese (Japan)',
        'Microsoft Haruka - Japanese (Japan)',
        'Microsoft Ichiro - Japanese (Japan)',
        'Microsoft Sayaka - Japanese (Japan)',
        'Google 日本語'
    ];
    for (var i = 0; i < japaneseVoiceNames.length; i++) {
        var defaultVoiceName = japaneseVoiceNames[i];
        selectedVoice = voices.find(v => v.name === defaultVoiceName);
        if (selectedVoice) {
            break;
        }
    }
}


if (selectedVoice) {
    var utterThis = new SpeechSynthesisUtterance(textToSpeak);
    utterThis.lang = "ja-JP";
    utterThis.voice = selectedVoice;
    utterThis.rate = selectedRate;
    utterThis.pitch = selectedPitch;
    utterThis.volume = selectedVolume; // utterThisにvolumeを設定

    speechSynthesis.cancel();
    speechSynthesis.speak(utterThis);
} else {
    console.error('利用可能な日本語音声が見つかりませんでした。');
}
""";

    js.context.callMethod('eval', [jsCode]);
  } catch (e) {
    print("Error内容:" + e.toString());
  }
}
