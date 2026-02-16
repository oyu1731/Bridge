import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../06-company/18-article-detail.dart';
import '../06-company/article_api_client.dart';
import '../11-common/58-header.dart';

class LikedArticleListPage extends StatefulWidget {
  const LikedArticleListPage({super.key});

  @override
  State<LikedArticleListPage> createState() => _LikedArticleListPageState();
}

class _LikedArticleListPageState extends State<LikedArticleListPage> {
  bool _isLoading = true;
  String? _error;
  List<ArticleDTO> _likedArticles = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadLikedArticles();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null && mounted) {
      Navigator.of(context).pushReplacementNamed('/signin');
    }
  }

  Future<void> _loadLikedArticles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson == null) {
        throw Exception('ログイン情報が見つかりません。');
      }

      final userData = jsonDecode(userJson);
      final dynamic userIdRaw = userData['id'];
      final int? userId =
          userIdRaw is int ? userIdRaw : int.tryParse(userIdRaw.toString());

      if (userId == null) {
        throw Exception('ユーザーIDが不正です。');
      }

      final liked = await ArticleApiClient.getLikedArticlesByUserId(userId);
      final visible =
          liked.where((article) => article.isDeleted != true).toList();

      setState(() {
        _likedArticles = visible;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'いいねした記事の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  void _openArticleDetail(ArticleDTO article) {
    if (article.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('記事IDが不正なため詳細を開けません')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ArticleDetailPage(
              articleTitle: article.title,
              articleId: article.id!.toString(),
              companyName: article.companyName,
              description: article.description,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BridgeHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'いいねした記事一覧',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFD32F2F)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadLikedArticles,
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    if (_likedArticles.isEmpty) {
      return const Center(
        child: Text(
          'いいねした記事はありません',
          style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _likedArticles.length,
      itemBuilder: (context, index) {
        final article = _likedArticles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            title: Text(
              article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(article.companyName ?? '会社名不明'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text('${article.totalLikes ?? 0}'),
                    ],
                  ),
                ],
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openArticleDetail(article),
          ),
        );
      },
    );
  }
}
