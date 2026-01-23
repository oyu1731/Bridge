// screen_wrapper.dart (新規作成)

import 'package:bridge/11-common/59-global-method.dart';
import 'package:flutter/material.dart';

// BridgeHeaderはPreferredSizeWidgetなので、AppBarとして利用可能
// BridgeHeaderのクラス名に応じて適宜インポートしてください。
// import 'bridge_header.dart';

class ScreenWrapper extends StatelessWidget {
  final Widget child; // 画面コンテンツ
  final PreferredSizeWidget? appBar; // ヘッダー (BridgeHeaderなど)
  final Widget? bottomNavigationBar; // 下部ナビゲーションを受け取れるように
  final Color? backgroundColor; // 背景色を受け取れるように

  const ScreenWrapper({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.backgroundColor,
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
        backgroundColor: backgroundColor,
        body: child, // 各画面のメインコンテンツ
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
