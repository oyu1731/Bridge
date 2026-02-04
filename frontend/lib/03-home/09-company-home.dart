import 'package:bridge/02-auth/06-delete-account.dart';
import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '../06-company/article_api_client.dart';
import '../06-company/16-article-list.dart';
import '../06-company/18-article-detail.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // セッション保存用
import 'package:http/http.dart' as http;
import '../08-thread/thread_api_client.dart';
import '../08-thread/31-thread-list.dart';
import 'package:bridge/08-thread/33-thread-unofficial-detail.dart';
import 'package:bridge/08-thread/thread_model.dart';

class CompanyHome extends StatefulWidget {
  final String? initialMessage;
  const CompanyHome({Key? key, this.initialMessage}) : super(key: key);

  @override
  State<CompanyHome> createState() => _CompanyHomeState();
}

class _CompanyHomeState extends State<CompanyHome>
    with SingleTickerProviderStateMixin {
  List<Thread> officialThreads = [];
  List<Thread> hotUnofficialThreads = [];
  static const Color textCyanDark = Color.fromARGB(255, 2, 44, 61);
  // API呼び出し　並び替え　上位３件に絞り込み
  Future<List<Thread>> fetchTop3UnofficialThreads() async {
    final threads = await ThreadApiClient.getAllThreads();
    final unofficial =
        threads
            .where(
              (t) =>
                  t.type == 2 &&
                  (t.entryCriteria == userType || t.entryCriteria == 1),
            )
            .toList();
    unofficial.sort((a, b) {
      final aTime = a.lastCommentDate ?? DateTime(2000);
      final bTime = b.lastCommentDate ?? DateTime(2000);
      return bTime.compareTo(aTime); // 新しい順
    });
    return unofficial.take(3).toList();
  }

  //ユーザ情報取得
  int? userType;
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('current_user');
    if (jsonString == null) return;
    final userData = jsonDecode(jsonString);
    setState(() {
      userType = userData['type'] + 1;
    });
  }

  /// ログイン中のアカウントのサブスク確認・更新
  Future<void> _checkAndUpdateSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('current_user');
    if (jsonString == null) return;

    final userData = jsonDecode(jsonString);
    final userId = userData['id'];

    try {
      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/users/$userId/check-subscription',
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📋 サブスク確認完了: ${data['message']}');

        // usersテーブルのplanStatusが更新されている場合、セッションも更新
        if (data['planStatus'] != null) {
          print('🔄 セッション更新: planStatus=${data['planStatus']}');
          userData['planStatus'] = data['planStatus'];
          await prefs.setString('current_user', jsonEncode(userData));

          // 無料に変わった場合はヘッダーをリロード
          if (data['planStatus'] == '無料') {
            print('⚠️ プランが無料に変更されました - ヘッダーを再ロード');
            // ヘッダーのキャッシュとアラート履歴をリセット
            BridgeHeader.clearPlanStatusCache();
            BridgeHeader.resetAlertHistory(userId);
            print('🗑️ ヘッダーのキャッシュをクリア、アラート履歴をリセット');
            // 状態を更新してリビルド
            if (mounted) setState(() {});
          }
        }
      } else {
        print('❌ サブスク確認エラー: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ サブスク確認通信エラー: $e');
    }
  }

  Future<void> _init() async {
    await _loadUserData(); //ユーザ取得
    await _checkAndUpdateSubscriptionStatus(); // サブスク確認・更新
    print("iiiiiiiiii");
    print(userType);
  }

  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // タブ5個
    _init();
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
      body: Column(
        children: [
          if (widget.initialMessage != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.initialMessage ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTopPageTab(context),
                Center(child: Text('タブ2の内容')),
                Center(child: Text('タブ3の内容')),
                Center(child: Text('タブ4の内容')),
                Center(child: Text('タブ5の内容')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================
  // トップページタブ
  // =====================
  Widget _buildTopPageTab(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return FutureBuilder<List<ArticleDTO>>(
      future: ArticleApiClient.getAllArticles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('記事の取得に失敗しました'));
        }
        // 取得した記事のうち最大10件のみ表示
        final articles = (snapshot.data ?? []).take(10).toList();
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textCyanDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ThreadList()),
                        );
                      },
                      child: const Text(
                        '>スレッド一覧',
                        style: TextStyle(color: textCyanDark),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    FutureBuilder<List<Thread>>(
                      future: fetchTop3UnofficialThreads(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text('スレッド取得エラー');
                        }
                        final threads = snapshot.data ?? [];
                        if (threads.isEmpty) {
                          return Text('表示できるスレッドがありません');
                        }
                        return Column(
                          children:
                              threads.map((t) {
                                return Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    ThreadUnOfficialDetail(
                                                      thread: {
                                                        'id': t.id,
                                                        'title': t.title,
                                                      },
                                                    ),
                                          ),
                                        );
                                      },
                                      //説明文の表示
                                      child: Card(
                                        child: ListTile(
                                          title: Text(
                                            t.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            t.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          trailing: Text(
                                            t.timeAgo,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        );
                      },
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textCyanDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ArticleListPage()),
                        );
                      },
                      child: const Text(
                        '>記事一覧',
                        style: TextStyle(color: textCyanDark),
                      ),
                    ),
                  ],
                ),
              ),

              // スマホ: 横スクロール / PC: PageView＋ボタン（3枚ずつ）
              Center(
                child: SizedBox(
                  height: 260,
                  width: double.infinity,
                  child:
                      isMobile
                          ? ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: articles.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, i) {
                              final a = articles[i];
                              return _buildArticleCard(
                                title: a.title,
                                companyName: a.companyName ?? '',
                                totalLikes: a.totalLikes ?? 0,
                                link: '',
                                photo1Id: a.photo1Id,
                                onTitleTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ArticleDetailPage(
                                            articleTitle: a.title,
                                            articleId: a.id?.toString() ?? '',
                                            companyName: a.companyName,
                                            description: a.description,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                          : _ArticlePager(
                            articles:
                                articles
                                    .map(
                                      (a) => {
                                        "title": a.title,
                                        "companyName": a.companyName ?? '',
                                        "totalLikes": a.totalLikes ?? 0,
                                        "link": '',
                                        "photo1Id": a.photo1Id,
                                        "onTitleTap": () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => ArticleDetailPage(
                                                    articleTitle: a.title,
                                                    articleId:
                                                        a.id?.toString() ?? '',
                                                    companyName: a.companyName,
                                                    description: a.description,
                                                  ),
                                            ),
                                          );
                                        },
                                      },
                                    )
                                    .toList(),
                          ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// =====================
// スレッドカード
// =====================
Widget _buildThreadCard({required String title, required String time}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 4),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    ),
  );
}

// =====================
// 記事カード
// =====================
Widget _buildArticleCard({
  required String title,
  required String companyName,
  required int totalLikes,
  required String link,
  int? photo1Id,
  VoidCallback? onTitleTap,
}) {
  return SizedBox(
    width: 260, // 横幅を少し広げて安定させる
    child: Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias, // 角丸からはみ出る画像をカット
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTitleTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 画像部分 ---
            Container(
              height: 120, // 高さを高くして写真を目立たせる
              width: double.infinity,
              color: Colors.grey.shade200,
              child:
                  photo1Id != null
                      ? FutureBuilder<PhotoDTO?>(
                        future: PhotoApiClient.getPhotoById(photo1Id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return CircularProgressIndicator();
                          }
                          final photo = snapshot.data;
                          if (photo != null &&
                              photo.filePath != null &&
                              photo.filePath!.isNotEmpty) {
                            return Image.network(photo.filePath!);
                          } else {
                            return Icon(Icons.image_not_supported, size: 50);
                          }
                        },
                      )
                      : const Icon(
                        Icons.business,
                        size: 50,
                        color: Colors.grey,
                      ),
            ),
            // --- テキスト部分 ---
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4), // 余白の調整
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16, // 少し小さくしてバランスをとる
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                companyName,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(), // 下部に押し込む
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text('$totalLikes', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// =====================
// PC用記事ページャー (3枚ずつ表示)
// =====================
class _ArticlePager extends StatefulWidget {
  final List<Map<String, dynamic>> articles;
  const _ArticlePager({required this.articles});

  @override
  State<_ArticlePager> createState() => _ArticlePagerState();
}

class _ArticlePagerState extends State<_ArticlePager> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  int _getItemsPerPage() {
    final width = MediaQuery.of(context).size.width;
    const cardWidth = 240.0; // カード幅固定
    const buttonWidth = 100.0; // 左右ボタンの幅
    final availableWidth = width - buttonWidth; // 利用可能な幅
    return (availableWidth / cardWidth).floor().clamp(1, 5); // 最小1、最大5件
  }

  void _nextPage() {
    final itemsPerPage = _getItemsPerPage();
    final maxPage = (widget.articles.length + itemsPerPage - 1) ~/ itemsPerPage;
    final nextPage = (_currentPage + 1) % maxPage;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    final itemsPerPage = _getItemsPerPage();
    final maxPage = (widget.articles.length + itemsPerPage - 1) ~/ itemsPerPage;
    final prevPage = (_currentPage - 1 + maxPage) % maxPage;
    _pageController.animateToPage(
      prevPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsPerPage = _getItemsPerPage();
    final totalPages =
        (widget.articles.length + itemsPerPage - 1) ~/ itemsPerPage;

    return Row(
      children: [
        IconButton(onPressed: _prevPage, icon: const Icon(Icons.arrow_back)),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * itemsPerPage;
              final end = (start + itemsPerPage).clamp(
                0,
                widget.articles.length,
              );
              final pageArticles = widget.articles.sublist(start, end);

              return Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        pageArticles
                            .map(
                              (a) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                ),
                                child: _buildArticleCard(
                                  title: a["title"] ?? '',
                                  companyName: a["companyName"] ?? '',
                                  totalLikes: a["totalLikes"] ?? 0,
                                  link: a["link"] ?? '',
                                  photo1Id: a["photo1Id"],
                                  onTitleTap: a["onTitleTap"],
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              );
            },
          ),
        ),
        IconButton(onPressed: _nextPage, icon: const Icon(Icons.arrow_forward)),
      ],
    );
  }
}
