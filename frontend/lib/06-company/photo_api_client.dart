import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_config.dart';

class PhotoDTO {
  final int? id;
  final String? photoPath;
  final int? userId;

  PhotoDTO({
    this.id,
    this.photoPath,
    this.userId,
  });

  factory PhotoDTO.fromJson(Map<String, dynamic> json) {
    return PhotoDTO(
      id: json['id'],
      photoPath: json['photoPath'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photoPath': photoPath,
      'userId': userId,
    };
  }
}

class PhotoApiClient {
  static String get baseUrl => ApiConfig.baseUrl + '/api/photos';

  /// 画像をアップロード（XFileを使用してWeb対応）
  static Future<PhotoDTO> uploadPhoto(XFile imageFile, {int? userId}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      
      // XFileからバイトデータを読み込み
      final bytes = await imageFile.readAsBytes();
      
      // 画像ファイルを追加
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
        ),
      );
      
      // ユーザーIDを追加（オプション）
      if (userId != null) {
        request.fields['userId'] = userId.toString();
      }
      
      // リクエストを送信
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return PhotoDTO.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to upload photo: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading photo: $e');
    }
  }

  /// 写真IDから写真情報を取得
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

  /// 写真を削除
  static Future<void> deletePhoto(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete photo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting photo: $e');
    }
  }
}
