import 'package:flutter/material.dart';
import 'package:bridge/11-common/59-global-method.dart';
import 'dart:js' as js;

class VoiceSettingDialog extends StatefulWidget {
  const VoiceSettingDialog({super.key});

  @override
  State<VoiceSettingDialog> createState() => _VoiceSettingDialogState();
}

class _VoiceSettingDialogState extends State<VoiceSettingDialog> {
  String? _selectedVoiceName;
  double _pitch = 1.0; // 声のトーン (0.0 to 2.0, default 1.0)
  double _rate = 0.5; // 声の速さ (0.1 to 10.0, default 0.5 for a natural speed)
  double _volume = 1.0; // 音量 (0.0 to 1.0, default 1.0)
  List<String> _availableVoices = [];

  final GlobalActions _globalActions = GlobalActions();

  @override
  void initState() {
    super.initState();
    _loadVoiceSettings();
    _initVoices();
  }

  Future<void> _loadVoiceSettings() async {
    final String? savedVoice = await _globalActions.loadVoiceSetting();
    final double? savedPitch = await _globalActions.loadVoicePitch();
    final double? savedRate = await _globalActions.loadVoiceRate();
    final double? savedVolume = await _globalActions.loadVoiceVolume();

    setState(() {
      _selectedVoiceName = savedVoice;
      _pitch = savedPitch ?? 1.0;
      _rate = savedRate ?? 0.5;
      _volume = savedVolume ?? 1.0;
    });
  }

  Future<void> _initVoices() async {
    final js.JsObject? webSpeech = js.context['speechSynthesis'];
    if (webSpeech != null) {
      webSpeech.callMethod('addEventListener', [
        'voiceschanged',
        js.allowInterop(() {
          _updateAvailableVoices();
        }),
      ]);
      _updateAvailableVoices();
    } else {
      print("Web Speech API is not available.");
    }
  }

  void _updateAvailableVoices() {
    final js.JsObject? webSpeech = js.context['speechSynthesis'];
    if (webSpeech != null) {
      final js.JsArray voices = webSpeech.callMethod('getVoices') as js.JsArray;
      List<String> voiceNames = [];
      for (int i = 0; i < voices.length; i++) {
        final js.JsObject voice = voices[i] as js.JsObject;
        if (voice['lang'].toString().startsWith('ja')) {
          voiceNames.add(voice['name'].toString());
        }
      }
      setState(() {
        _availableVoices = voiceNames;
        if (_selectedVoiceName == null ||
            !_availableVoices.contains(_selectedVoiceName)) {
          _selectedVoiceName =
              _availableVoices.isNotEmpty ? _availableVoices.first : null;
        }
      });
    }
  }

  void _saveSettings() async {
    if (_selectedVoiceName != null) {
      await _globalActions.saveVoiceSetting(_selectedVoiceName!);
      await _globalActions.saveVoicePitch(_pitch);
      await _globalActions.saveVoiceRate(_rate);
      await _globalActions.saveVoiceVolume(_volume);
      showGenericDialog(
        context: context,
        type: DialogType.onlyOk,
        title: '設定保存',
        content: '音声設定を保存しました。',
      );
    } else {
      showGenericDialog(
        context: context,
        type: DialogType.onlyOk,
        title: '保存失敗',
        content: '音声が選択されていません。',
      );
    }
  }

  void _resetSettings() async {
    setState(() {
      _selectedVoiceName =
          _availableVoices.isNotEmpty ? _availableVoices.first : null;
      _pitch = 1.0;
      _rate = 1.0;
      _volume = 1.0;
    });
    await _globalActions.saveVoiceSetting(_selectedVoiceName ?? '');
    await _globalActions.saveVoicePitch(1.0);
    await _globalActions.saveVoiceRate(1.0);
    await _globalActions.saveVoiceVolume(1.0);
    showGenericDialog(
      context: context,
      type: DialogType.onlyOk,
      title: '設定リセット',
      content: '音声設定をリセットしました。',
    );
  }

  void _playSample() {
    if (_selectedVoiceName != null) {
      speakWeb(
        'こんにちは、AIの声のテストです。',
        voiceName: _selectedVoiceName!,
        pitch: _pitch,
        rate: _rate,
        volume: _volume,
      );
    } else {
      showGenericDialog(
        context: context,
        type: DialogType.onlyOk,
        title: '音声未選択',
        content: '音声を選択してください。',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI音声設定'),
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('声の種類'),
            DropdownButtonFormField<String>(
              value: _selectedVoiceName,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
              ),
              hint: const Text('音声を選択'),
              items:
                  _availableVoices.map((String voiceName) {
                    return DropdownMenuItem<String>(
                      value: voiceName,
                      child: Text(voiceName),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedVoiceName = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            Text('トーン: ${_pitch.toStringAsFixed(1)}'),
            Slider(
              value: _pitch,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              label: _pitch.toStringAsFixed(1),
              onChanged: (newValue) {
                setState(() {
                  _pitch = newValue;
                });
              },
            ),
            const SizedBox(height: 10),
            Text('速さ: ${_rate.toStringAsFixed(1)}'),
            Slider(
              value: _rate,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              label: _rate.toStringAsFixed(1),
              onChanged: (newValue) {
                setState(() {
                  _rate = newValue;
                });
              },
            ),
            const SizedBox(height: 10),
            Text('音量: ${_volume.toStringAsFixed(1)}'),
            Slider(
              value: _volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: _volume.toStringAsFixed(1),
              onChanged: (newValue) {
                setState(() {
                  _volume = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _resetSettings,
                  child: const Text('リセット'),
                ),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('保存'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _playSample,
              icon: const Icon(Icons.volume_up),
              label: const Text('サンプル再生'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
