import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../11-common/58-header.dart';
import 'article_api_client.dart';
import 'api_config.dart';
import '15-company-info-detail.dart';

class PhotoDTO {
  final int? id;
  final String? filePath;
  final String? fileName;

  PhotoDTO({
    this.id,
    this.filePath,
    this.fileName,
  });

  factory PhotoDTO.fromJson(Map<String, dynamic> json) {
    // バックエンドはphotoPathを返すので、それをfilePathにマッピング
    // パスをフルURLに変換
    String? photoPath = json['photoPath'];
    String? fullPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      // /uploads/photos/xxx.jpg のようなパスを http://localhost:8080/uploads/photos/xxx.jpg に変換
      fullPath = '${ApiConfig.baseUrl}$photoPath';
    }
    
    return PhotoDTO(
      id: json['id'],
      filePath: fullPath,
      fileName: json['fileName'],
    );
  }
}

class PhotoApiClient {
  static String get baseUrl => ApiConfig.photosUrl;

  static Future<PhotoDTO?> getPhotoById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode == 200) {
        return PhotoDTO.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load photo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching photo: $e');
    }
  }
}

class ArticleDetailPage extends StatefulWidget {
  final String articleTitle;
  final String articleId;
  final String? companyName;
  final String? description;

  const ArticleDetailPage({
    Key? key,
    required this.articleTitle,
    required this.articleId,
    this.companyName,
    this.description,
  }) : super(key: key);

  @override
  _ArticleDetailPageState createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadUserId();
  }

    Future<void> _checkLoginStatus() async {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/signin');
        }
      }
    }
  ArticleDTO? _article;
  List<PhotoDTO?> _photos = [];
  bool _isLoading = true;
  String? _error;
  int? _currentUserId; // サインイン中のユーザーID
  
  // いいね機能の状態
  bool _isLiked = false;
  bool _isLikeLoading = false;

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('current_user');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        setState(() {
          _currentUserId = userData['id'];
        });
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
    // ユーザーID読み込み後に記事データを読み込む
    _loadArticleData();
  }

  Future<void> _loadArticleData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 記事IDを整数に変換
      final int? articleId = int.tryParse(widget.articleId);
      if (articleId == null) {
        throw Exception('Invalid article ID');
      }

      // 記事データを取得（ユーザーID付き）
      final article = await ArticleApiClient.getArticleById(articleId, userId: _currentUserId);
      if (article == null) {
        throw Exception('Article not found');
      }
      
      // サーバーからいいね状態を取得
      if (article.isLikedByUser != null) {
        _isLiked = article.isLikedByUser!;
      }

      // デバッグ用：取得した記事データのphoto_idを確認
      print('Debug: Article data loaded');
      print('Photo1Id: ${article.photo1Id}');
      print('Photo2Id: ${article.photo2Id}'); 
      print('Photo3Id: ${article.photo3Id}');

      // 写真データを取得（photo1_id、photo2_id、photo3_idの順）
      List<PhotoDTO?> photos = [];
      
      if (article.photo1Id != null) {
        try {
          print('Debug: Fetching photo1 with id: ${article.photo1Id}');
          final photo = await PhotoApiClient.getPhotoById(article.photo1Id!);
          print('Debug: Photo1 result: ${photo?.filePath}');
          photos.add(photo);
        } catch (e) {
          print('Debug: Error fetching photo1: $e');
          photos.add(null);
        }
      } else {
        print('Debug: Photo1Id is null');
        photos.add(null);
      }

      if (article.photo2Id != null) {
        try {
          print('Debug: Fetching photo2 with id: ${article.photo2Id}');
          final photo = await PhotoApiClient.getPhotoById(article.photo2Id!);
          print('Debug: Photo2 result: ${photo?.filePath}');
          photos.add(photo);
        } catch (e) {
          print('Debug: Error fetching photo2: $e');
          photos.add(null);
        }
      } else {
        print('Debug: Photo2Id is null');
        photos.add(null);
      }

      if (article.photo3Id != null) {
        try {
          print('Debug: Fetching photo3 with id: ${article.photo3Id}');
          final photo = await PhotoApiClient.getPhotoById(article.photo3Id!);
          print('Debug: Photo3 result: ${photo?.filePath}');
          photos.add(photo);
        } catch (e) {
          print('Debug: Error fetching photo3: $e');
          photos.add(null);
        }
      } else {
        print('Debug: Photo3Id is null');
        photos.add(null);
      }

      setState(() {
        _article = article;
        _photos = photos;
        if (article.isLikedByUser != null) {
          _isLiked = article.isLikedByUser!;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }



  // いいねトグル機能
  Future<void> _toggleLike() async {
    if (_article?.id == null || _isLikeLoading || _currentUserId == null) return;

    setState(() {
      _isLikeLoading = true;
    });

    try {
      final int articleId = _article!.id!;
      final bool willLike = !_isLiked; // 新しい状態を計算
      
      // サーバーに新しい状態を送信（userId付き）
      await ArticleApiClient.likeArticle(articleId, _currentUserId!, willLike);

      // サーバーから最新の記事データを取得して同期
      final updatedArticle = await ArticleApiClient.getArticleById(articleId, userId: _currentUserId);
      if (updatedArticle != null) {
        setState(() {
          _article = updatedArticle;
          _isLiked = updatedArticle.isLikedByUser ?? false;
        });
      } else {
        // フォールバック: ローカルで状態を更新
        setState(() {
          _isLiked = willLike;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLiked ? 'いいねしました！' : 'いいねを取り消しました'),
          duration: Duration(seconds: 1),
          backgroundColor: _isLiked ? Colors.red : Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLikeLoading = false;
      });
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
                onPressed: _loadArticleData,
                child: Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    if (_article == null) {
      return Scaffold(
        appBar: BridgeHeader(),
        body: Center(
          child: Text('記事が見つかりません'),
        ),
      );
    }

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
              
              const SizedBox(height: 24),
              
              // いいねセクション
              _buildLikeSection(),
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
        _article?.title ?? widget.articleTitle,
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
    final tags = _article?.tags ?? [];
    Widget tagWidget;
    if (tags.isEmpty) {
      tagWidget = Text(
        'タグなし',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF757575),
        ),
      );
    } else {
      tagWidget = Wrap(
        spacing: 6,
        runSpacing: 4,
        children: tags.map((t) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFF90CAF9)),
            ),
            child: Text(
              '#$t',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: tagWidget),
        SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            final companyId = _article?.companyId;
            final companyName = _article?.companyName ?? widget.companyName ?? '';
            if (companyId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanyDetailPage(
                    companyName: companyName,
                    companyId: companyId,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('企業IDが取得できませんでした')),
              );
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              constraints: BoxConstraints(maxWidth: 220),
              child: Text(
                _article?.companyName ?? widget.companyName ?? '株式会社AAA',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0),
                  height: 1.3,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    // 存在する写真のリストを作成
    final isWide = MediaQuery.of(context).size.width >= 900; // PC幅判定
    List<Widget> imageWidgets = [];
    
    // 画像1 (photo1_id) - photo1Idが存在し、かつ写真が取得できた場合のみ追加
    if (_article?.photo1Id != null && _photos.isNotEmpty && _photos[0] != null) {
      imageWidgets.add(_buildPhotoWidget(0, '画像1'));
    }
    
    // 画像2 (photo2_id) - photo2Idが存在し、かつ写真が取得できた場合のみ追加
    if (_article?.photo2Id != null && _photos.length > 1 && _photos[1] != null) {
      imageWidgets.add(_buildPhotoWidget(1, '画像2'));
    }
    
    // 画像3 (photo3_id) - photo3Idが存在し、かつ写真が取得できた場合のみ追加
    if (_article?.photo3Id != null && _photos.length > 2 && _photos[2] != null) {
      imageWidgets.add(_buildPhotoWidget(2, '画像3'));
    }

    // 画像が一つもない場合は、画像セクション自体を表示しない
    if (imageWidgets.isEmpty) {
      return SizedBox.shrink();
    }

    // 画像枚数に応じて表示を調整
    int imageCount = imageWidgets.length;
    
    // PC幅かどうかで高さ・最大幅を調整（縦長画像がはみ出さない最大値＋中央寄せ）
    // PCサイズを現状の約3/4に縮小
    double singleHeight = isWide ? 360 : 300; // 480 -> 360
    double doubleHeight = isWide ? 270 : 250; // 360 -> 270
    double tripleHeight = isWide ? 240 : 200; // 320 -> 240
    double maxRowWidth = isWide ? 825 : double.infinity; // 1100 -> 825 (≈75%)
    double maxSingleWidth = isWide ? 675 : double.infinity; // 900 -> 675 (≈75%)

    if (imageCount == 1) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: singleHeight,
            maxWidth: maxSingleWidth,
          ),
          child: imageWidgets[0],
        ),
      );
    }

    if (imageCount == 2) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: doubleHeight,
            maxWidth: maxRowWidth,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: imageWidgets[0],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: imageWidgets[1],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: tripleHeight,
          maxWidth: maxRowWidth,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: imageWidgets[0],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: imageWidgets[1],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 8),
                child: imageWidgets[2],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoWidget(int index, String placeholder) {
    if (index < _photos.length && _photos[index] != null) {
      final photo = _photos[index]!;
      if (photo.filePath != null && photo.filePath!.isNotEmpty) {
        return GestureDetector(
          onTap: () => _showImageModal(photo.filePath!),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black12, // 縦長画像用余白背景
              border: Border.all(color: Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: Image.network(
                  photo.filePath!,
                  fit: BoxFit.contain,
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
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Color(0xFF757575),
                          size: 32,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '読み込み\nエラー',
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
                ),
              ),
            ),
          ),
        );
      }
    }

    // 写真がない場合のプレースホルダー
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            color: Color(0xFF757575),
            size: 32,
          ),
          SizedBox(height: 4),
          Text(
            placeholder,
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 12,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '記事本文',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            child: _buildLinkifiedDescription(
              _article?.description ?? widget.description ?? '記事の内容が表示されます。',
            ),
          ),
        ],
      ),
    );
  }

  // 記事本文内のURLを検出してリンク化
  Widget _buildLinkifiedDescription(String text) {
    final urlRegExp = RegExp(r'((https?:\/\/|www\.)[^\s]+)', caseSensitive: false);
    final spans = <TextSpan>[];
    int start = 0;
    final matches = urlRegExp.allMatches(text).toList();

    for (final m in matches) {
      if (m.start > start) {
        spans.add(TextSpan(text: text.substring(start, m.start)));
      }
      final rawUrl = text.substring(m.start, m.end);
      final url = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
      spans.add(
        TextSpan(
          text: rawUrl,
          style: const TextStyle(
            color: Color(0xFF1976D2),
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ),
      );
      start = m.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return SelectableText.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF424242),
          height: 1.6,
        ),
        children: spans,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLikeSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // 右端に配置
        children: [
          InkWell(
            onTap: _isLikeLoading ? null : _toggleLike,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _isLiked ? Colors.red[50] : Color(0xFFF5F5F5),
                border: Border.all(
                  color: _isLiked ? Colors.red : Color(0xFFE0E0E0),
                  width: _isLiked ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLikeLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      )
                    : Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Color(0xFF757575),
                        size: 20,
                      ),
                  SizedBox(width: 8),
                  Text(
                    '${_article?.totalLikes ?? 0}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _isLiked ? Colors.red : Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 画像拡大表示モーダル
  void _showImageModal(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16),
          child: Stack(
            children: [
              // 拡大画像表示
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '画像を読み込めませんでした',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // 閉じるボタン
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: EdgeInsets.all(8),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}