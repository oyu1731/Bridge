import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../06-company/photo_api_client.dart';

class CompanyPhotoModal extends StatelessWidget {
  final void Function(int photoId, String photoUrl)? onPhotoUploaded;
  const CompanyPhotoModal({super.key, this.onPhotoUploaded});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: _CompanyPhotoUploadContent(onPhotoUploaded: onPhotoUploaded),
    );
  }
}

class _CompanyPhotoUploadContent extends StatefulWidget {
  final void Function(int photoId, String photoUrl)? onPhotoUploaded;
  const _CompanyPhotoUploadContent({this.onPhotoUploaded});
  @override
  State<_CompanyPhotoUploadContent> createState() => _CompanyPhotoUploadContentState();
}

class _CompanyPhotoUploadContentState extends State<_CompanyPhotoUploadContent> {
  Uint8List? _imageBytes;
  String? _fileName;
  bool _uploading = false;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imageBytes = result.files.first.bytes;
          _fileName = result.files.first.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像選択失敗: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_imageBytes == null || _fileName == null) return;
    setState(() => _uploading = true);
    try {
      // bytesからXFile生成（Web対応）
      final xfile = XFile.fromData(_imageBytes!, name: _fileName!, mimeType: 'image/jpeg');
      final photo = await PhotoApiClient.uploadPhoto(xfile);
      if (photo.id != null && photo.photoPath != null) {
        if (widget.onPhotoUploaded != null) {
          widget.onPhotoUploaded!(photo.id!, photo.photoPath!);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アップロード完了')),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception('photoIdまたはphotoPathが取得できませんでした');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アップロード失敗: $e')),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('企業写真を追加', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (_imageBytes != null)
            Column(
              children: [
                Image.memory(_imageBytes!, width: 160, height: 160, fit: BoxFit.cover),
                const SizedBox(height: 8),
                Text(_fileName ?? '', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 16),
              ],
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.image),
            label: const Text('画像を選択'),
            onPressed: _uploading ? null : _pickImage,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload),
            label: const Text('アップロード'),
            onPressed: _uploading || _imageBytes == null ? null : _uploadImage,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _uploading ? null : () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
