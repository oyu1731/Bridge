import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class AdminCompanyArticleDetail extends StatefulWidget {
  final String articleId; // 遷移元から受け取るID

  const AdminCompanyArticleDetail({Key? key, required this.articleId}) : super(key: key);

  @override
  _AdminCompanyArticleDetailState createState() => _AdminCompanyArticleDetailState();
}

class _AdminCompanyArticleDetailState extends State<AdminCompanyArticleDetail> {
  Map<String, dynamic>? _articleData;

  @override
  void initState() {
    super.initState();
    _loadArticleData();
  }

  // ダミーデータをIDで取得
  void _loadArticleData() {
    final dummyArticles = [
      {
        'id': '1',
        'title': '【株式会社AAA】【選考あり】会社説明会のご案内',
        'description':
            '弊社では、随時オンライン会社説明会を開催中です。定期的にあるマイナビもしくはリクナビのリンクからエントリーください！エントリーお待ちしております！',
        'tag': '#説明会開催中,#会社紹介',
        'company': '株式会社AAA',
        'images': [
          'https://via.placeholder.com/150',
          'https://via.placeholder.com/150',
        ],
      },
      {
        'id': '2',
        'title': '【株式会社AAA】スレッドを開設しました。',
        'description':
            '弊社の交流スレッドを作成いたしました！質問においても気になることや、弊社に対する質問など気軽に投稿してくださいね♪\n\nスレッドタイトルは【株式会社AAA～フリースレッド】です！',
        'tag': '#スレッド開設',
        'company': '株式会社AAA',
        'images': [
          'https://via.placeholder.com/150',
        ],
      },
    ];

    setState(() {
      _articleData =
          dummyArticles.firstWhere((a) => a['id'] == widget.articleId, orElse: () => {});
    });
  }

  // 削除処理（ポップアップ確認）
  void _deleteArticle() async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('削除確認'),
        content: Text('この記事を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('削除'),
          ),
        ],
      ),
    );

    if (confirm) {
      // TODO: バックエンド削除処理を入れる
      Navigator.pop(context); // 削除完了後、前画面に戻る
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_articleData == null || _articleData!.isEmpty) {
      return Scaffold(
        appBar: BridgeHeader(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // タイトル
            Text(
              _articleData!['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // タブ（タグ）、会社名、削除ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左：タグ
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: (_articleData!['tag'] as String)
                        .split(',')
                        .map((t) => Chip(label: Text(t)))
                        .toList(),
                  ),
                ),
                // 右：会社名 + 削除
                Row(
                  children: [
                    Text(
                      _articleData!['company'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _deleteArticle,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE3F2FD),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: Color(0xFF64B5F6)),
                        ),
                      ),
                      child: const Text('削除'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 画像表示（最大3枚まで横スクロール）
            if (_articleData!['images'] != null && (_articleData!['images'] as List).isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: (_articleData!['images'] as List)
                      .take(3)
                      .map((url) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Image.network(url),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),

            // 説明文
            Text(
              _articleData!['description'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
