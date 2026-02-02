import 'dart:convert';
import 'package:http/http.dart' as http;
import '../11-common/api_config.dart';

class ArticleDTO {
  final int? id;
  final int companyId;
  final String? companyName;
  final String title;
  final String description;
  final int? totalLikes;
  final bool? isDeleted;
  final String? createdAt;
  final bool? isLikedByUser;
  final int? photo1Id;
  final int? photo2Id;
  final int? photo3Id;
  final List<String>? tags; // タグ情報を追加
  final String? industry; // 旧：業界名（後方互換）
  final List<String>? industries; // 新：業界リスト

  ArticleDTO({
    this.id,
    required this.companyId,
    this.companyName,
    required this.title,
    required this.description,
    this.totalLikes,
    this.isDeleted,
    this.createdAt,
    this.isLikedByUser,
    this.photo1Id,
    this.photo2Id,
    this.photo3Id,
    this.tags,
    this.industry,
    this.industries,
  });

  factory ArticleDTO.fromJson(Map<String, dynamic> json) {
    List<String>? industries;
    if (json['industries'] != null) {
      if (json['industries'] is List) {
        industries =
            (json['industries'] as List).map((e) => e.toString()).toList();
      } else if (json['industries'] is String) {
        industries = (json['industries'] as String).split(',');
      }
    }
    return ArticleDTO(
      id: json['id'],
      companyId: json['companyId'] ?? 0,
      companyName: json['companyName'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      totalLikes: json['totalLikes'],
      isDeleted: json['isDeleted'],
      createdAt: json['createdAt'],
      isLikedByUser: json['isLikedByUser'],
      photo1Id: json['photo1Id'],
      photo2Id: json['photo2Id'],
      photo3Id: json['photo3Id'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      industry: json['industry'],
      industries: industries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'title': title,
      'description': description,
      'totalLikes': totalLikes,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'isLikedByUser': isLikedByUser,
      'photo1Id': photo1Id,
      'photo2Id': photo2Id,
      'photo3Id': photo3Id,
      'tags': tags,
      'industry': industry,
      'industries': industries,
    };
  }
}

class ArticleApiClient {
  static String get baseUrl => ApiConfig.articlesUrl;

  static Future<List<ArticleDTO>> getAllArticles() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ArticleDTO.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load articles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching articles: $e');
    }
  }

  static Future<List<ArticleDTO>> searchArticles({
    int? companyId,
    String? keyword,
    List<int>? industryIds,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/search');
      final Map<String, String> queryParams = {};

      if (companyId != null) {
        queryParams['companyId'] = companyId.toString();
      }
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (industryIds != null && industryIds.isNotEmpty) {
        // 複数業界IDをカンマ区切りで送信
        queryParams['industryIds'] = industryIds.join(',');
      }

      final searchUri = uri.replace(queryParameters: queryParams);
      final response = await http.get(searchUri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ArticleDTO.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search articles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching articles: $e');
    }
  }

  static Future<ArticleDTO?> getArticleById(int id, {int? userId}) async {
    try {
      var uri = Uri.parse('$baseUrl/$id');
      if (userId != null) {
        uri = uri.replace(queryParameters: {'userId': userId.toString()});
      }
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return ArticleDTO.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load article: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching article: $e');
    }
  }

  static Future<ArticleDTO> createArticle(ArticleDTO article) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(article.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ArticleDTO.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create article: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating article: $e');
    }
  }

  static Future<ArticleDTO> updateArticle(int id, ArticleDTO article) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(article.toJson()),
      );

      if (response.statusCode == 200) {
        return ArticleDTO.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update article: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating article: $e');
    }
  }

  static Future<void> deleteArticle(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete article: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting article: $e');
    }
  }

  static Future<void> likeArticle(int id, int userId, bool isLiking) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$id/like'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'liking': isLiking}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to like article: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error liking article: $e');
    }
  }

  static Future<List<ArticleDTO>> getArticlesByCompanyId(int companyId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/company/$companyId'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ArticleDTO.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load company articles: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching company articles: $e');
    }
  }
}
