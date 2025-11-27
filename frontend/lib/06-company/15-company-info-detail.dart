import 'package:flutter/material.dart';
import '../11-common/58-header.dart';
import '18-article-detail.dart';
import '16-article-list.dart';
import 'company_api_client.dart';
import 'article_api_client.dart';

class CompanyDetailPage extends StatefulWidget {
  final String companyName;
  final int companyId;

  const CompanyDetailPage({
    Key? key,
    required this.companyName,
    required this.companyId,
  }) : super(key: key);

  @override
  _CompanyDetailPageState createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends State<CompanyDetailPage> {
  CompanyDTO? _company;
  List<ArticleDTO> _featuredArticles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 企業情報を取得
      final company = await CompanyApiClient.getCompanyById(widget.companyId);
      
      // 企業の記事を取得（いいね数順）
      final articles = await ArticleApiClient.getArticlesByCompanyId(widget.companyId);
      
      // いいね数順にソート（降順）
      articles.sort((a, b) => (b.totalLikes ?? 0).compareTo(a.totalLikes ?? 0));
      
      setState(() {
        _company = company;
        _featuredArticles = articles.take(5).toList(); // 上位5件を取得
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '不明';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}年${date.month}月${date.day}日';
    } catch (e) {
      return '不明';
    }
  }

  // いいね行（0件でも固定高さで表示してレイアウトを安定化）
  Widget _buildLikeRow(int? likes) {
    final count = likes ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        height: 18,
        child: Row(
          children: [
            Icon(
              Icons.favorite,
              size: 12,
              color: Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyImage(double height) {
    if (_company?.photoPath != null && _company!.photoPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _company!.photoPath!,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: height * 0.3,
                    color: Color(0xFF757575),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '画像を読み込めません',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: height * 0.3,
              color: Color(0xFF757575),
            ),
            SizedBox(height: 8),
            Text(
              '企業画像',
              style: TextStyle(
                fontSize: height > 200 ? 20 : 16,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: BridgeHeader(),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: BridgeHeader(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'エラーが発生しました',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(_error!),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCompanyData,
                child: Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    if (_company == null) {
      return Scaffold(
        appBar: BridgeHeader(),
        body: Center(
          child: Text('企業情報が見つかりません'),
        ),
      );
    }

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
                        _company!.name,
                        style: TextStyle(
                          fontSize: 24, // スマートフォンでは少し小さく
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '最終更新：${_formatDate(_company!.createdAt)}',
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
                          _company!.name,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ),
                      Text(
                        '最終更新：${_formatDate(_company!.createdAt)}',
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
                                child: _buildCompanyImage(200),
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
                                  child: _buildCompanyImage(250),
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
              child: _featuredArticles.isEmpty
                  ? Center(
                      child: Text(
                        '記事がありません',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: _featuredArticles
                            .map(
                              (article) => Container(
                                margin: EdgeInsets.only(bottom: 16),
                                child: InkWell(
                                  onTap: () {
                                    // 記事詳細ページへの遷移
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ArticleDetailPage(
                                          articleTitle: article.title,
                                          articleId: article.id.toString(),
                                          companyName: widget.companyName,
                                          description: article.description,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1976D2),
                                          decoration: TextDecoration.underline,
                                          height: 1.4,
                                        ),
                                      ),
                                      _buildLikeRow(article.totalLikes),
                                    ],
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
                        companyName: widget.companyName,
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
          _featuredArticles.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      '記事がありません',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: _featuredArticles
                      .map(
                        (article) => Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () {
                              // 記事詳細ページへの遷移
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArticleDetailPage(
                                    articleTitle: article.title,
                                    articleId: article.id.toString(),
                                    companyName: widget.companyName,
                                    description: article.description,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1976D2),
                                    decoration: TextDecoration.underline,
                                    height: 1.4,
                                  ),
                                ),
                                _buildLikeRow(article.totalLikes),
                              ],
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
                      companyName: widget.companyName,
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
    if (_company == null) return Container();

    final companyInfo = [
      {
        'label': '業界',
        'value': _company!.industry ?? '情報がありません',
      },
      {
        'label': 'プロフィール',
        'value': _company!.description ?? '情報がありません',
      },
      {
        'label': '電話番号',
        'value': _company!.phoneNumber.isNotEmpty ? _company!.phoneNumber : '情報がありません',
      },
      {
        'label': 'email',
        'value': _company!.email ?? '情報がありません',
      },
      {
        'label': '所在地',
        'value': _company!.address.isNotEmpty ? _company!.address : '情報がありません',
      },
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
