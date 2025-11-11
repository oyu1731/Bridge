import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../11-common/58-header.dart';
import 'article_api_client.dart';
import 'api_config.dart';

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
    return PhotoDTO(
      id: json['id'],
      filePath: json['filePath'],
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
  ArticleDTO? _article;
  List<PhotoDTO?> _photos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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

      // 記事データを取得
      final article = await ArticleApiClient.getArticleById(articleId);
      if (article == null) {
        throw Exception('Article not found');
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
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
            _article?.companyName ?? widget.companyName ?? '株式会社AAA',
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
    // 存在する写真のリストを作成
    List<Widget> imageWidgets = [];
    
    // 画像1 (photo1_id) - photo1Idが存在し、かつ写真が取得できた場合のみ追加
    if (_article?.photo1Id != null && _photos.isNotEmpty && _photos[0] != null) {
      imageWidgets.add(
        Expanded(
          child: Container(
            height: double.infinity,
            margin: EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              border: Border.all(color: Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildPhotoWidget(0, '画像1'),
          ),
        ),
      );
    }
    
    // 画像2 (photo2_id) - photo2Idが存在し、かつ写真が取得できた場合のみ追加
    if (_article?.photo2Id != null && _photos.length > 1 && _photos[1] != null) {
      imageWidgets.add(
        Expanded(
          child: Container(
            height: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              border: Border.all(color: Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildPhotoWidget(1, '画像2'),
          ),
        ),
      );
    }
    
    // 画像3 (photo3_id) - photo3Idが存在し、かつ写真が取得できた場合のみ追加
    if (_article?.photo3Id != null && _photos.length > 2 && _photos[2] != null) {
      imageWidgets.add(
        Expanded(
          child: Container(
            height: double.infinity,
            margin: EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              border: Border.all(color: Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildPhotoWidget(2, '画像3'),
          ),
        ),
      );
    }

    // 画像が一つもない場合は、画像セクション自体を表示しない
    if (imageWidgets.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      height: 200,
      child: Row(
        children: imageWidgets,
      ),
    );
  }

  Widget _buildPhotoWidget(int index, String placeholder) {
    if (index < _photos.length && _photos[index] != null) {
      final photo = _photos[index]!;
      if (photo.filePath != null && photo.filePath!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            photo.filePath!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
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
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              );
            },
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
          Text(
            _article?.description ?? widget.description ?? '記事の内容が表示されます。',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF424242),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: _toggleLike,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                border: Border.all(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${_article?.totalLikes ?? 0}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
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

  Future<void> _toggleLike() async {
    if (_article?.id == null) return;

    try {
      // いいね機能の実装（後で詳細な実装を追加可能）
      await ArticleApiClient.likeArticle(_article!.id!);
      
      // データを再読み込み
      _loadArticleData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('いいねしました'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}