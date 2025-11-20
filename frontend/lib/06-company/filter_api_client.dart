import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class IndustryDTO {
  final int id;
  final String industry;

  IndustryDTO({
    required this.id,
    required this.industry,
  });

  factory IndustryDTO.fromJson(Map<String, dynamic> json) {
    return IndustryDTO(
      id: json['id'],
      industry: json['industry'] ?? '',
    );
  }
}

class TagDTO {
  final int id;
  final String tag;

  TagDTO({
    required this.id,
    required this.tag,
  });

  factory TagDTO.fromJson(Map<String, dynamic> json) {
    return TagDTO(
      id: json['id'],
      tag: json['tag'] ?? '',
    );
  }
}

class FilterApiClient {
  // APIパスはバックエンドのコントローラーに合わせて '/api/filters' を使う
  static String get baseUrl => ApiConfig.baseUrl + '/api/filters';

  static Future<List<IndustryDTO>> getAllIndustries() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/industries'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => IndustryDTO.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load industries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching industries: $e');
    }
  }

  static Future<List<TagDTO>> getAllTags() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tags'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => TagDTO.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tags: $e');
    }
  }
}