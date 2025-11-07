import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class AdminThreadList extends StatefulWidget {
  @override
  _AdminThreadListState createState() => _AdminThreadListState();
}

class _AdminThreadListState extends State<AdminThreadList> {
  List<Map<String, String>> officialThreads = [];
  List<Map<String, String>> hotUnofficialThreads = [];

  @override
  void initState() {
    super.initState();
    _fetchThreads();
  }

  @override
  void didUpdateWidget(covariant AdminThreadList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ホットリロードや再読み込み時にスレッド情報を再取得
    _fetchThreads();
  }

  // 初回に公式スレッド（固定3件）＋ 非公式スレッド上位5件を取得
  Future<void> _fetchThreads() async {
    await Future.delayed(Duration(milliseconds: 300)); // 通信待ち想定
    setState(() {
      // 公式スレッド（固定）: ラストコメント＋経過時間を取得
      officialThreads = [
        {
          'id': '1',
          'title': '学生・社会人',
          'lastComment': '最近忙しいけど頑張ってる！',
          'timeAgo': '3分前',
        },
        {
          'id': '2',
          'title': '学生',
          'lastComment': 'テスト期間でやばいです…',
          'timeAgo': '15分前',
        },
        {
          'id': '3',
          'title': '社会人',
          'lastComment': '残業が多くてつらい…',
          'timeAgo': '42分前',
        },
      ];

      // 非公式スレッド（通報からの経過時間が短い上位5件）
      hotUnofficialThreads = [
        {'id': 't1', 'title': '業界別の面接対策', 'timeAgo': '3分前'},
        {'id': 't2', 'title': '社会人一年目の過ごし方', 'timeAgo': '10分前'},
        {'id': 't3', 'title': 'おすすめの資格', 'timeAgo': '25分前'},
        {'id': 't4', 'title': '働きながら転職活動するには', 'timeAgo': '50分前'},
        {'id': 't5', 'title': '就活で意識すべきこと', 'timeAgo': '1時間前'},
      ];
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Column(
      ),
    );
  }
}