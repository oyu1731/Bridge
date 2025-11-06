import 'package:flutter/material.dart';
import '../11-common/58-header.dart';
import '16-article-list.dart';

class CompanyDetailPage extends StatelessWidget {
  final String companyName;
  final String companyId;

  const CompanyDetailPage({
    Key? key,
    required this.companyName,
    this.companyId = 'dummy-id',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Column(
        children: [
          // 企業名と最終更新日
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isSmallScreen = constraints.maxWidth <= 800;
                
                if (isSmallScreen) {
                  // スマートフォン: 縦配置
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '株式会社XXX',
                        style: TextStyle(
                          fontSize: 24, // スマートフォンでは少し小さく
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '最終更新：XXX年X月X日',
                        style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                      ),
                    ],
                  );
                } else {
                  // デスクトップ: 横配置（従来通り）
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '株式会社XXX',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ),
                      Text(
                        '最終更新：XXX年X月X日',
                        style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                      ),
                    ],
                  );
                }
              },
            ),
          ),

          // メインコンテンツエリア（レスポンシブ対応）
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // スマートフォンサイズ（幅800px以下）かどうかを判定
                bool isSmallScreen = constraints.maxWidth <= 800;
                
                if (isSmallScreen) {
                  // スマートフォン: 縦配置（企業詳細情報 → 注目記事）
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // 企業詳細情報
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 企業画像
                              Container(
                                width: double.infinity,
                                height: 200, // スマートフォンでは少し小さく
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F5F5),
                                  border: Border.all(color: Color(0xFFE0E0E0)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '画像',
                                    style: TextStyle(
                                      fontSize: 20, // スマートフォンでは少し小さく
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 企業概要タイトル
                              Text(
                                '企業概要',
                                style: TextStyle(
                                  fontSize: 20, // スマートフォンでは少し小さく
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF424242),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 企業詳細情報テーブル
                              _buildCompanyInfoTable(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                        
                        // 注目記事（スマートフォン用）
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildFeaturedArticlesContent(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                } else {
                  // デスクトップ: 左右分割（従来通り）
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左側：企業詳細情報（スクロール可能）
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 企業画像
                                Container(
                                  width: double.infinity,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                    border: Border.all(color: Color(0xFFE0E0E0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '画像',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Color(0xFF757575),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // 企業概要タイトル
                                Text(
                                  '企業概要',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 企業詳細情報テーブル
                                _buildCompanyInfoTable(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 右側：注目記事（固定位置）
                      Container(
                        width: 350,
                        padding: const EdgeInsets.only(right: 24, top: 24),
                        child: _buildFeaturedArticles(),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedArticles() {
    final articles = [
      {'title': '【営業職】ITエンジニアとして、このようなことを、してみたい・やってみたい'},
      {'title': '【9Q分野】オンライン説明会のご案内'},
      {'title': '【Web説明会】★全国どこからでも参加可能！★2Q分野★'},
    ];

    return Container(
      padding: EdgeInsets.all(20),
      height: 400, // 固定高さ
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '注目記事',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: articles
                      .map(
                        (article) => Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () {
                              // 記事詳細ページへの遷移（張りぼて）
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('記事詳細ページに遷移します'),
                                  backgroundColor: Color(0xFF1976D2),
                                ),
                              );
                            },
                            child: Text(
                              article['title']!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1976D2),
                                decoration: TextDecoration.underline,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  // 記事一覧ページに遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleListPage(
                        companyName: companyName,
                      ),
                    ),
                  );
                },
                child: Text(
                  'もっと見る',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1976D2),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedArticlesContent() {
    final articles = [
      {'title': '【営業職】ITエンジニアとして、このようなことを、してみたい・やってみたい'},
      {'title': '【9Q分野】オンライン説明会のご案内'},
      {'title': '【Web説明会】★全国どこからでも参加可能！★2Q分野★'},
    ];

    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // 重要: サイズを最小限に
        children: [
          Text(
            '注目記事',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 16),
          // Expandedを削除してColumnに変更
          Column(
            children: articles
                .map(
                  (article) => Container(
                    margin: EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        // 記事詳細ページへの遷移（張りぼて）
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('記事詳細ページに遷移します'),
                            backgroundColor: Color(0xFF1976D2),
                          ),
                        );
                      },
                      child: Text(
                        article['title']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1976D2),
                          decoration: TextDecoration.underline,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                // 記事一覧ページに遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleListPage(
                      companyName: companyName,
                    ),
                  ),
                );
              },
              child: Text(
                'もっと見る',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1976D2),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoTable() {
    final companyInfo = [
      {
        'label': 'プロフィール',
        'value': '株式会社XXXは、テクノロジーの力で人と社会をつなぐ革新的なソリューションを提供する会社です。',
      },
      {'label': '事業内容', 'value': 'クラウド開発、AIシステム設計、Webアプリケーション制作'},
      {'label': '会社所在地', 'value': 'XX県XX市XX区XX—XXXX XXビル'},
      {'label': '会社電話番号', 'value': 'XXX-XXXX-XXXX'},
      {'label': '設立', 'value': 'XXX年X月'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children:
            companyInfo
                .map((info) => _buildInfoRow(info['label']!, info['value']!))
                .toList(),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ラベル部分
            Container(
              width: 120,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border(
                  right: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                ),
              ),
            ),
            // 値部分
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF616161),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
