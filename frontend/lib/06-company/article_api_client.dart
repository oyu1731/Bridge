import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ArticleDTO {
  final int? id;
  final int companyId;
  final String? companyName;
  final String title;
  final String description;
  final int? totalLikes;
  final bool? isDeleted;
  final String? createdAt;
  final int? photo1Id;
  final int? photo2Id;
  final int? photo3Id;

  ArticleDTO({
    this.id,
    required this.companyId,
    this.companyName,
    required this.title,
    required this.description,
    this.totalLikes,
    this.isDeleted,
    this.createdAt,
    this.photo1Id,
    this.photo2Id,
    this.photo3Id,
  });

  factory ArticleDTO.fromJson(Map<String, dynamic> json) {
    return ArticleDTO(
      id: json['id'],
      companyId: json['companyId'] ?? 0,
      companyName: json['companyName'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      totalLikes: json['totalLikes'],
      isDeleted: json['isDeleted'],
      createdAt: json['createdAt'],
      photo1Id: json['photo1Id'],
      photo2Id: json['photo2Id'],
      photo3Id: json['photo3Id'],
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
      'photo1Id': photo1Id,
      'photo2Id': photo2Id,
      'photo3Id': photo3Id,
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

  static Future<ArticleDTO?> getArticleById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));
      
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

  static Future<void> likeArticle(int id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/$id/like'));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to like article: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error liking article: $e');
    }
  }

  static Future<void> unlikeArticle(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id/like'));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to unlike article: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error unliking article: $e');
    }
  }

  static Future<List<ArticleDTO>> getArticlesByCompanyId(int companyId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/company/$companyId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ArticleDTO.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load company articles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching company articles: $e');
    }
  }
}