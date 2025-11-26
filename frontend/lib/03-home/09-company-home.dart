import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class CompanyHome extends StatefulWidget {
  const CompanyHome({Key? key}) : super(key: key);

  @override
  State<CompanyHome> createState() => _CompanyHomeState();
}

class _CompanyHomeState extends State<CompanyHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // タブ5個
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTopPageTab(),
          Center(child: Text('タブ2の内容')),
          Center(child: Text('タブ3の内容')),
          Center(child: Text('タブ4の内容')),
          Center(child: Text('タブ5の内容')),
        ],
      ),
    );
  }
}

// =====================
// トップページタブ
// =====================
Widget _buildTopPageTab() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 最新スレッド
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最新スレッド',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('>スレッド一覧'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildThreadCard(
                title: 'これは、企業トップです。',
                time: '1分前',
              ),
              const SizedBox(height: 12),
              _buildThreadCard(
                title: '株式会社AAAーフリースレッド',
                time: '2分前',
              ),
              const SizedBox(height: 12),
              _buildThreadCard(
                title: '学生×社会人スレッド',
                time: '7分前',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 注目記事
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '注目記事',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('>記事一覧'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildArticleCard(
                title: '【株式会社AAA】【選考あり】会社説明会のご案内',
                description:
                    '#説明会開催中,#会社紹介\n卒業では、Onlineオンライン会社説明会を開催中です。記事内にあるマイナビのリンクからエントリーください...',
                link: 'https://example.com',
              ),
              const SizedBox(width: 16),
              _buildArticleCard(
                title: '【27卒向け説明会のご案内 【株式会社BBB】',
                description:
                    '#説明会開催中,#会社紹介,#新卒\n若い オンラインで会社説明会を開催中です。エントリーもお待ちしております！！\nご応募はこちらから！>https://mynabi.2...',
                link: 'https://mynabi2.example.com',
              ),
              const SizedBox(width: 16),
              _buildArticleCard(
                title: '株式会社CCC',
                description:
                    '#説明会開催中,#会社紹介\nあなたの挑戦を応援します！技用エントリーは公式サイトから！！\n【https://example.com】',
                link: 'https://example.com',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

// =====================
// スレッドカード
// =====================
Widget _buildThreadCard({
  required String title,
  required String time,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

// =====================
// 記事カード
// =====================
Widget _buildArticleCard({
  required String title,
  required String description,
  required String link,
}) {
  return Container(
    width: 300,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.teal[300]!),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
