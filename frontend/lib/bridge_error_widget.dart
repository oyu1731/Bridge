import 'package:flutter/material.dart';
import '11-common/common_error_page.dart';

class BridgeErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;
  const BridgeErrorWidget(this.details, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // エラー内容から400/404/500を判別
    int errorCode = 500;
    final errorMsg = details.exceptionAsString().toLowerCase();
    if (errorMsg.contains('404')) {
      errorCode = 404;
    } else if (errorMsg.contains('400')) {
      errorCode = 400;
    }
    return CommonErrorPage(errorCode: errorCode);
  }
}
