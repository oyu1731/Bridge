import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  State<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends State<CompanyDetailPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchData();
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

  CompanyDTO? _company;
  List<ArticleDTO> _featuredArticles = [];
  bool _isLoading = true;
  String? _error;
  LatLng? _companyLatLng;
  bool _isGeocoding = false;
  String? _mapError;

  // 自動ループ用コントローラ/タイマー
  PageController? _featuredPageController;
  Timer? _featuredTimer;
  int _currentFeaturedPage = 0;

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final company = await CompanyApiClient.getCompanyById(widget.companyId);
      final articles = await ArticleApiClient.getArticlesByCompanyId(
        widget.companyId,
      );
      // 削除済み記事を除外
      final filtered = articles.where((a) => a.isDeleted != true).toList();
      filtered.sort((a, b) => (b.totalLikes ?? 0).compareTo(a.totalLikes ?? 0));
      setState(() {
        _company = company;
        _featuredArticles = filtered.take(5).toList();
        _isLoading = false;
      });
      _geocodeAddress(company?.address);
      // 記事取得後に自動スクロールをセットアップ
      _setupFeaturedAutoScroll();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupFeaturedAutoScroll() {
    // 既存のタイマーをクリア
    _featuredTimer?.cancel();
    _featuredPageController ??= PageController(
      initialPage: _currentFeaturedPage,
    );

    if ((_featuredArticles.length) <= 1) return;

    _featuredTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_featuredArticles.isEmpty) return;
      _currentFeaturedPage =
          (_currentFeaturedPage + 1) % _featuredArticles.length;
      _featuredPageController?.animateToPage(
        _currentFeaturedPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _geocodeAddress(String? address) async {
    if (address == null || address.trim().isEmpty) return;
    if (_isGeocoding) return;
    setState(() {
      _isGeocoding = true;
      _mapError = null;
    });
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'json',
        'q': address,
        'limit': '1',
      });
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'bridge-app/1.0 (contact: dev@bridge.local)'},
      );
      if (response.statusCode != 200) {
        throw Exception('Geocoding failed: ${response.statusCode}');
      }
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty) {
        throw Exception('No location found');
      }
      final lat = double.tryParse(data.first['lat']?.toString() ?? '');
      final lon = double.tryParse(data.first['lon']?.toString() ?? '');
      if (lat == null || lon == null) {
        throw Exception('Invalid coordinates');
      }
      setState(() {
        _companyLatLng = LatLng(lat, lon);
      });
    } catch (e) {
      setState(() {
        _mapError = '地図を取得できませんでした';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '不明';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}年${date.month}月${date.day}日';
    } catch (_) {
      return '不明';
    }
  }

  Widget _buildLikeRow(int? likes) {
    final count = likes ?? 0;
    return Row(
      children: [
        Icon(Icons.favorite, size: 12, color: Colors.red),
        SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(fontSize: 11, color: Color(0xFF757575)),
        ),
      ],
    );
  }

  Widget _buildCompanyImage(double maxHeight) {
    final photoPath = _company?.photoPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      return AspectRatioImage(
        imageUrl: photoPath,
        maxHeight: maxHeight,
        onTap: () => _showImageModal(photoPath),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: maxHeight * 0.3,
              color: Color(0xFF757575),
            ),
            SizedBox(height: 8),
            Text(
              '企業画像',
              style: TextStyle(
                fontSize: maxHeight > 200 ? 20 : 16,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showImageModal(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(16),
            child: Stack(
              children: [
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
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => Center(
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
                          ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: EdgeInsets.all(8),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildCompanyInfoTable() {
    final c = _company;
    if (c == null) return Container();
    final info = [
      {
        'label': '業界',
        'value':
            (c.industries != null && c.industries!.isNotEmpty)
                ? c.industries!.join(', ')
                : (c.industry ?? '情報がありません'),
      },
      {'label': 'プロフィール', 'value': c.description ?? '情報がありません'},
      {
        'label': '電話番号',
        'value': (c.phoneNumber.isNotEmpty) ? c.phoneNumber : '情報がありません',
      },
      {'label': 'email', 'value': c.email ?? '情報がありません'},
      {
        'label': '所在地',
        'value': (c.address.isNotEmpty) ? c.address : '情報がありません',
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
            info.map((e) => _buildInfoRow(e['label']!, e['value']!)).toList(),
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

  Widget _buildFeaturedArticles({bool isMobile = false}) {
    final articles = _featuredArticles;
    final containerHeight = isMobile ? 180.0 : 320.0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '注目記事',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          SizedBox(height: 16),
          articles.isEmpty
              ? Center(
                child: Text(
                  '記事がありません',
                  style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
                ),
              )
              : Column(
                children: [
                  SizedBox(
                    height: containerHeight,
                    child: PageView.builder(
                      controller: _featuredPageController,
                      itemCount: articles.length,
                      onPageChanged: (i) => _currentFeaturedPage = i,
                      itemBuilder: (context, index) {
                        final article = articles[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ArticleDetailPage(
                                      articleTitle: article.title,
                                      articleId: article.id.toString(),
                                      companyName: widget.companyName,
                                      description: article.description,
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Color(0xFFF9F9F9),
                              border: Border.all(color: Color(0xFFECEFF1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1976D2),
                                    decoration: TextDecoration.underline,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 8),
                                _buildLikeRow(article.totalLikes),
                                SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    article.description ?? '',
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF616161),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ArticleListPage(
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
        ],
      ),
    );
  }

  Widget _buildCompanyMap({bool isMobile = false}) {
    final mapHeight = isMobile ? 220.0 : 260.0;
    return Container(
      width: double.infinity,
      height: mapHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child:
            _companyLatLng == null
                ? Center(
                  child: Text(
                    _isGeocoding
                        ? '地図を読み込み中...'
                        : (_mapError ?? '位置情報が見つかりませんでした'),
                    style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
                  ),
                )
                : FlutterMap(
                  options: MapOptions(
                    initialCenter: _companyLatLng!,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.bridge.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _companyLatLng!,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }

  @override
  @override
  void dispose() {
    _featuredTimer?.cancel();
    _featuredPageController?.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: BridgeHeader(),
        body: Center(child: CircularProgressIndicator()),
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
              ElevatedButton(onPressed: _fetchData, child: Text('再試行')),
            ],
          ),
        ),
      );
    }
    if (_company == null) {
      return Scaffold(
        appBar: BridgeHeader(),
        body: Center(child: Text('企業情報が見つかりません')),
      );
    }
    return Scaffold(
      appBar: BridgeHeader(),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth <= 800;
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _company!.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '最終更新：${_formatDate(_company!.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  );
                } else {
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth <= 800;
                if (isMobile) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F5F5),
                                  border: Border.all(color: Color(0xFFE0E0E0)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _buildCompanyImage(200),
                              ),
                              SizedBox(height: 24),
                              Text(
                                '企業概要',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF424242),
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildCompanyInfoTable(),
                              SizedBox(height: 24),
                              Text(
                                '所在地（地図）',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF424242),
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildCompanyMap(isMobile: true),
                              SizedBox(height: 32),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(horizontal: 24),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildFeaturedArticles(isMobile: true),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                    border: Border.all(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _buildCompanyImage(250),
                                ),
                                SizedBox(height: 32),
                                Text(
                                  '企業概要',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                                SizedBox(height: 24),
                                _buildCompanyInfoTable(),
                                SizedBox(height: 24),
                                Text(
                                  '所在地（地図）',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                                SizedBox(height: 12),
                                _buildCompanyMap(),
                                SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 350,
                        padding: EdgeInsets.only(right: 24, top: 24),
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
}

class AspectRatioImage extends StatefulWidget {
  final String imageUrl;
  final double maxHeight;
  final VoidCallback? onTap;
  const AspectRatioImage({
    required this.imageUrl,
    required this.maxHeight,
    this.onTap,
    Key? key,
  }) : super(key: key);
  @override
  State<AspectRatioImage> createState() => _AspectRatioImageState();
}

class _AspectRatioImageState extends State<AspectRatioImage> {
  double? _aspectRatio;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getImageAspectRatio();
  }

  void _getImageAspectRatio() async {
    final image = Image.network(widget.imageUrl);
    final completer = Completer<ImageInfo>();
    image.image
        .resolve(ImageConfiguration())
        .addListener(
          ImageStreamListener((info, _) {
            completer.complete(info);
          }),
        );
    final info = await completer.future;
    setState(() {
      _aspectRatio = info.image.width / info.image.height;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _aspectRatio == null) {
      return Center(child: CircularProgressIndicator());
    }
    double height = widget.maxHeight;
    double width = height * _aspectRatio!;
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.imageUrl,
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
