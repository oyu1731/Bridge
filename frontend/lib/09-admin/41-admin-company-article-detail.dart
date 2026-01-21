import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../11-common/58-header.dart';
import '../06-company/api_config.dart';
import 'admin_article_dto.dart';

/* ------------------ 写真DTO（企業側と同一ロジック） ------------------ */
class AdminPhotoDTO {
  final int? id;
  final String? filePath;
  final String? fileName;

  AdminPhotoDTO({this.id, this.filePath, this.fileName});

  factory AdminPhotoDTO.fromJson(Map<String, dynamic> json) {
    String? photoPath = json['photoPath'];
    String? fullPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      fullPath = '${ApiConfig.baseUrl}$photoPath';
    }

    return AdminPhotoDTO(
      id: json['id'],
      filePath: fullPath,
      fileName: json['fileName'],
    );
  }
}

/* ------------------ 写真API ------------------ */
class AdminPhotoApiClient {
  static String get baseUrl => ApiConfig.photosUrl;

  static Future<AdminPhotoDTO?> getPhotoById(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/$id'));
    if (res.statusCode == 200) {
      return AdminPhotoDTO.fromJson(json.decode(res.body));
    }
    return null;
  }
}

/* ================== 記事詳細 ================== */
class AdminCompanyArticleDetail extends StatefulWidget {
  final String articleId;
  const AdminCompanyArticleDetail({super.key, required this.articleId});

  @override
  State<AdminCompanyArticleDetail> createState() =>
      _AdminCompanyArticleDetailState();
}

class _AdminCompanyArticleDetailState extends State<AdminCompanyArticleDetail> {
  AdminArticleDTO? _article;
  List<AdminPhotoDTO?> _photos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/articles/${widget.articleId}'),
      );
      if (res.statusCode != 200) throw Exception('取得失敗');

      final article = AdminArticleDTO.fromJson(json.decode(res.body));

      final photos = <AdminPhotoDTO?>[];

      if (article.photo1Id != null) {
        photos.add(await AdminPhotoApiClient.getPhotoById(article.photo1Id!));
      } else {
        photos.add(null);
      }
      if (article.photo2Id != null) {
        photos.add(await AdminPhotoApiClient.getPhotoById(article.photo2Id!));
      } else {
        photos.add(null);
      }
      if (article.photo3Id != null) {
        photos.add(await AdminPhotoApiClient.getPhotoById(article.photo3Id!));
      } else {
        photos.add(null);
      }

      setState(() {
        _article = article;
        _photos = photos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この記事を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );

    if (ok == true) {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/articles/${_article!.id}'),
      );

      if (res.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('記事を削除しました'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pop(context, true); // ← 一覧へ戻る & 即反映
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('削除に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(appBar: BridgeHeader(), body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: const BridgeHeader(), body: Center(child: Text(_error!)));

    final a = _article!;
    return Scaffold(
      appBar: const BridgeHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text(a.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            _buildTagsAndCompany(a),
            const SizedBox(height: 24),
            _buildImageSection(),
            const SizedBox(height: 24),
            const Text(
              '記事本文',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.start, // ← 左
            ),
            const SizedBox(height: 12),

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Text(
                  a.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.7),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildLikeSection(a),
          ],
        ),
      ),
    );
  }

  // ★ タグを企業側と同一デザインへ修正
  Widget _buildTagsAndCompany(AdminArticleDTO a) => Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: a.tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF90CAF9)),
                ),
                child: Text("#$t", style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ),
          const SizedBox(width: 12),
          Text(a.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _delete,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              shadowColor: const Color(0xFF1976D2).withOpacity(0.3),
            ),
            child: const Text(
              '削除',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );

  /* -------------------- 企業側と同一ロジック -------------------- */
  Widget _buildImageSection() {
    final isWide = MediaQuery.of(context).size.width >= 900;
    List<Widget> imageWidgets = [];

    if (_photos.length > 0 && _photos[0] != null) imageWidgets.add(_buildPhotoWidget(0));
    if (_photos.length > 1 && _photos[1] != null) imageWidgets.add(_buildPhotoWidget(1));
    if (_photos.length > 2 && _photos[2] != null) imageWidgets.add(_buildPhotoWidget(2));

    if (imageWidgets.isEmpty) return const SizedBox.shrink();

    double h1 = isWide ? 360 : 300;
    double h2 = isWide ? 270 : 250;
    double h3 = isWide ? 240 : 200;
    double maxRow = isWide ? 825 : double.infinity;
    double maxSingle = isWide ? 675 : double.infinity;

    if (imageWidgets.length == 1) {
      return Center(child: ConstrainedBox(constraints: BoxConstraints(maxHeight: h1, maxWidth: maxSingle), child: imageWidgets[0]));
    }
    if (imageWidgets.length == 2) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: h2, maxWidth: maxRow),
          child: Row(children: [
            Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: imageWidgets[0])),
            Expanded(child: Padding(padding: const EdgeInsets.only(left: 8), child: imageWidgets[1])),
          ]),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h3, maxWidth: maxRow),
        child: Row(children: [
          Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: imageWidgets[0])),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: imageWidgets[1])),
          Expanded(child: Padding(padding: const EdgeInsets.only(left: 8), child: imageWidgets[2])),
        ]),
      ),
    );
  }

  Widget _buildPhotoWidget(int index) {
    final photo = _photos[index];

    // 企業側と同一：無ければ「何も描画しない」
    if (photo == null || photo.filePath == null || photo.filePath!.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showImageModal(photo.filePath!),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black12,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Image.network(
              photo.filePath!,
              loadingBuilder: (c, w, p) =>
                  p == null ? w : const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
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

  Widget _buildLikeSection(AdminArticleDTO a) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Icon(Icons.favorite, color: Colors.red),
        const SizedBox(width: 6),
        Text('${a.totalLikes}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showImageModal(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (c, w, p) =>
                      p == null ? w : const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorBuilder: (_, __, ___) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.broken_image, color: Colors.white, size: 64),
                      SizedBox(height: 16),
                      Text('画像を読み込めませんでした', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                style: IconButton.styleFrom(backgroundColor: Colors.black54, padding: const EdgeInsets.all(8)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
