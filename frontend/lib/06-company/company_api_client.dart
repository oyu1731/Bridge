import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class CompanyDTO {
  final int? id;
  final String name;
  final String address;
  final String phoneNumber;
  final String? email; // メールアドレスを追加
  final String? description;
  final int? planStatus;
  final bool? isWithdrawn;
  final String? createdAt;
  final int? photoId;
  final String? photoPath; // 写真パスを追加
  final String? industry; // 業界情報を追加
  final int? iconId; // ユーザーのアイコンID

  CompanyDTO({
    this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    this.email, // メールアドレスを追加
    this.description,
    this.planStatus,
    this.isWithdrawn,
    this.createdAt,
    this.photoId,
    this.photoPath, // 写真パスを追加
    this.industry, // 業界情報を追加
    this.iconId,
  });

  factory CompanyDTO.fromJson(Map<String, dynamic> json) {
    // バックエンドからのパスをフルURLに変換
    String? photoPath = json['photoPath'];
    String? fullPhotoPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      // /uploads/photos/xxx.jpg のようなパスを http://localhost:8080/uploads/photos/xxx.jpg に変換
      fullPhotoPath = '${ApiConfig.baseUrl}$photoPath';
    }
    
    return CompanyDTO(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'], // メールアドレスを追加
      description: json['description'],
      planStatus: json['planStatus'],
      isWithdrawn: json['isWithdrawn'],
      createdAt: json['createdAt'],
      photoId: json['photoId'],
      photoPath: fullPhotoPath, // フルURLに変換した写真パス
      industry: json['industry'], // 業界情報を追加
      iconId: json['iconId'], // ユーザーのアイコンID
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email, // メールアドレスを追加
      'description': description,
      'planStatus': planStatus,
      'isWithdrawn': isWithdrawn,
      'createdAt': createdAt,
      'photoId': photoId,
      'photoPath': photoPath, // 写真パスを追加
      'industry': industry, // 業界情報を追加
      'iconId': iconId, // ユーザーのアイコンID
    };
  }
}

class CompanyApiClient {
  static String get baseUrl => ApiConfig.companiesUrl;

  static Future<List<CompanyDTO>> getAllCompanies() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => CompanyDTO.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load companies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching companies: $e');
    }
  }

  static Future<List<CompanyDTO>> searchCompaniesByFilters({
    String? industry,
    String? area,
    String? keyword,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/search');
      final Map<String, String> queryParams = {};
      
      if (industry != null && industry.isNotEmpty) {
        queryParams['industry'] = industry;
      }
      if (area != null && area.isNotEmpty) {
        queryParams['area'] = area;
      }
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      
      final searchUri = uri.replace(queryParameters: queryParams);
      final response = await http.get(searchUri);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => CompanyDTO.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search companies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching companies: $e');
    }
  }

  static Future<List<CompanyDTO>> searchCompanies(String keyword) async {
    return searchCompaniesByFilters(keyword: keyword);
  }

  static Future<CompanyDTO?> getCompanyById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode == 200) {
        return CompanyDTO.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load company: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching company: $e');
    }
  }

  static Future<CompanyDTO> createCompany(CompanyDTO company) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(company.toJson()),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return CompanyDTO.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create company: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating company: $e');
    }
  }

  static Future<CompanyDTO> updateCompany(int id, CompanyDTO company) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(company.toJson()),
      );
      
      if (response.statusCode == 200) {
        return CompanyDTO.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update company: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating company: $e');
    }
  }

  static Future<void> deleteCompany(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete company: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting company: $e');
    }
  }

  static Future<List<String>> getIndustries() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/industries'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.cast<String>();
      } else {
        throw Exception('Failed to load industries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching industries: $e');
    }
  }

  static Future<List<String>> getAreas() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/areas'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.cast<String>();
      } else {
        throw Exception('Failed to load areas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching areas: $e');
    }
  }
}