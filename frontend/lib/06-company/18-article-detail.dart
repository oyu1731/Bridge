import 'package:flutter/material.dart';
import '../11-common/58-header.dart';

class ArticleDetailPage extends StatelessWidget {
  final String articleTitle;
  final String articleId;
  final String? companyName;
  final String? description;
  final String? category;
  final String? location;

  const ArticleDetailPage({
    Key? key,
    required this.articleTitle,
    required this.articleId,
    this.companyName,
    this.description,
    this.category,
    this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 記事タイトル
              _buildArticleTitle(),
              
              const SizedBox(height: 16),
              
              // 企業名とハッシュタグセクション
              _buildCompanyAndHashtags(),
              
              const SizedBox(height: 24),
              
              // 画像セクション
              _buildImageSection(),
              
              const SizedBox(height: 24),
              
              // 記事内容セクション
              _buildArticleContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleTitle() {
    return Container(
      width: double.infinity,
      child: Text(
        articleTitle,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF424242),
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCompanyAndHashtags() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ハッシュタグセクション
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '＃説明会開催中, ＃会社紹介',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
        ),
        
        // 企業名セクション
        Container(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            companyName ?? '株式会社AAA',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 200,
      child: Row(
        children: [
          // 画像1
          Expanded(
            child: Container(
              height: double.infinity,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                border: Border.all(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '画像1',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          
          // 画像2
          Expanded(
            child: Container(
              height: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                border: Border.all(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '画像2',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          
          // 画像3
          Expanded(
            child: Container(
              height: double.infinity,
              margin: EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                border: Border.all(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '画像3',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '弊社では、随時オンライン会社説明会を開催中です。',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF424242),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'エントリーについては、マイナビ・リクナビの各サイトよりお申し込みください。',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF424242),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'エントリーお待ちしております！',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF424242),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}