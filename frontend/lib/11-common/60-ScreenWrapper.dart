// screen_wrapper.dart (新規作成)

import 'package:bridge/11-common/59-global-method.dart';
import 'package:flutter/material.dart';

// BridgeHeaderはPreferredSizeWidgetなので、AppBarとして利用可能
// BridgeHeaderのクラス名に応じて適宜インポートしてください。
// import 'bridge_header.dart';

class ScreenWrapper extends StatelessWidget {
  final Widget child; // 画面コンテンツ
  final PreferredSizeWidget? appBar; // ヘッダー (BridgeHeaderなど)

  // Scaffoldの主要なプロパティが必要ならここに追加します（例: bottomNavigationBarなど）
  // final Widget? bottomNavigationBar;

  const ScreenWrapper({
    super.key,
    required this.child,
    this.appBar,
    // this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 戻る操作をブロック
      canPop: false,

      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }

        // 🚨 ブラウザの戻るボタンが押された時の警告 🚨
        showGenericDialog(
          // 直接呼び出す
          context: context,
          type: DialogType.onlyOk,
          title: '注意',
          content: '画面上のボタンから操作してください。',
        );
      },

      child: Scaffold(
        appBar: appBar, // BridgeHeaderがここに設定されます
        body: child, // 各画面のメインコンテンツ
        // bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
