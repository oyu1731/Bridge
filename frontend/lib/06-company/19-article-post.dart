import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../11-common/58-header.dart';
import '17-company-article-list.dart';
import 'article_api_client.dart';
import 'filter_api_client.dart';
import 'photo_api_client.dart';

class ArticlePostPage extends StatefulWidget {
  const ArticlePostPage({Key? key}) : super(key: key);

  @override
  State<ArticlePostPage> createState() => _ArticlePostPageState();
}

class _ArticlePostPageState extends State<ArticlePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  List<String> _selectedTags = [];
  List<XFile> _selectedImages = []; // XFileとして保持（Web対応）
  List<TagDTO> _availableTags = []; // 動的タグリスト
  bool _isLoading = false;
  bool _isLoadingTags = true;
  int? _currentCompanyId; // 企業ID
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([_loadCompanyId(), _loadAvailableTags()]);
  }

  Future<void> _loadCompanyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // サインイン情報からcompanyIdを取得
      final userDataString = prefs.getString('current_user');
      if (userDataString == null) {
        setState(() {
          _errorMessage = 'ログインしていません。サインインしてください。';
        });
        return;
      }

      final userData = jsonDecode(userDataString);
      final int? companyId = userData['companyId'];

      if (companyId == null) {
        setState(() {
          _errorMessage = '企業アカウントでログインしてください。';
        });
        return;
      }

      setState(() {
        _currentCompanyId = companyId;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '企業情報の取得に失敗しました: ${e.toString()}';
      });
    }
  }

  Future<void> _loadAvailableTags() async {
    try {
      final tags = await FilterApiClient.getAllTags();
      setState(() {
        _availableTags = tags;
        _isLoadingTags = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'タグの取得に失敗しました: ${e.toString()}';
        _isLoadingTags = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // エラーメッセージがある場合は表示
    if (_errorMessage != null && _currentCompanyId == null) {
      return Scaffold(
        appBar: BridgeHeader(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('戻る'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: BridgeHeader(),
      body:
          _isLoadingTags
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 記事投稿タイトル
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          border: Border.all(color: Color(0xFFE0E0E0)),
                        ),
                        child: Text(
                          '記事投稿',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // タイトル入力
                      _buildTitleSection(),

                      const SizedBox(height: 16),

                      // タグ選択
                      _buildTagSection(),

                      const SizedBox(height: 16),

                      // 画像選択
                      _buildImageSection(),

                      const SizedBox(height: 16),

                      // 本文入力
                      _buildContentSection(),

                      const SizedBox(height: 24),

                      // 投稿ボタン
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F5),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          child: Text(
            'タイトル',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0)),
            color: Colors.white,
          ),
          child: TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'タイトルを入力',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F5),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          child: Text(
            'タグ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(minHeight: 60),
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0)),
            color: Colors.white,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._selectedTags.map((tag) => _buildTagChip(tag)),
              _buildAddTagButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: TextStyle(fontSize: 12, color: Color(0xFF1976D2)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedTags.remove(tag);
              });
            },
            child: Icon(Icons.close, size: 16, color: Color(0xFF1976D2)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTagButton() {
    return GestureDetector(
      onTap: _showTagSelectionModal,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Color(0xFF1976D2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F5),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          child: Text(
            '画像',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(minHeight: 60),
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0)),
            color: Colors.white,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._selectedImages.map((image) => _buildImageChip(image)),
              _buildAddImageButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageChip(XFile imageFile) {
    final fileName = imageFile.name;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image, size: 16, color: Color(0xFF2E7D32)),
          const SizedBox(width: 4),
          Text(
            fileName.length > 15 ? '${fileName.substring(0, 12)}...' : fileName,
            style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedImages.remove(imageFile);
              });
            },
            child: Icon(Icons.close, size: 16, color: Color(0xFF2E7D32)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Color(0xFF1976D2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F5),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          child: Text(
            '本文',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0)),
            color: Colors.white,
          ),
          child: TextField(
            controller: _contentController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: '記事の本文を入力してください',
              hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: Container(
        width: 120,
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitArticle,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLoading ? Colors.grey : Color(0xFFFF9800),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child:
              _isLoading
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(
                    '投稿',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
        ),
      ),
    );
  }

  void _showTagSelectionModal() {
    // タグがまだ読み込まれていない場合
    if (_availableTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('タグを読み込んでいます...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // モーダル内で一時的に選択されたタグを管理
    Set<String> tempSelectedTags = Set.from(_selectedTags);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    // モーダルヘッダー
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'タグ追加',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // タグリスト
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 800 ? 3 : 2,
                          childAspectRatio:
                              MediaQuery.of(context).size.width > 800
                                  ? 2.2
                                  : 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _availableTags.length,
                        itemBuilder: (context, index) {
                          final tagDto = _availableTags[index];
                          final tag = tagDto.tag;
                          final isSelected = tempSelectedTags.contains(tag);

                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  tempSelectedTags.remove(tag);
                                } else {
                                  tempSelectedTags.add(tag);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Color(0xFFE3F2FD)
                                        : Colors.white,
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Color(0xFF1976D2)
                                          : Color(0xFFE0E0E0),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size:
                                        MediaQuery.of(context).size.width > 800
                                            ? 20
                                            : 16,
                                    color:
                                        isSelected
                                            ? Color(0xFF1976D2)
                                            : Color(0xFF757575),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width > 800
                                            ? 8
                                            : 4,
                                  ),
                                  Expanded(
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width >
                                                    800
                                                ? 14
                                                : 10,
                                        color:
                                            isSelected
                                                ? Color(0xFF1976D2)
                                                : Color(0xFF424242),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // タグを追加ボタン
                    Container(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          // 実際にタグを追加
                          setState(() {
                            _selectedTags = tempSelectedTags.toList();
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          'タグを追加',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      // 画像選択ダイアログを表示
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('画像を選択'),
            content: Text('画像の選択方法を選んでください'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt),
                    SizedBox(width: 8),
                    Text('カメラ'),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library),
                    SizedBox(width: 8),
                    Text('ギャラリー'),
                  ],
                ),
              ),
            ],
          );
        },
      );

      if (source == null) return;

      // 画像を選択
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(pickedFile);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像を追加しました'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の選択に失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitArticle() async {
    // バリデーション
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('タイトルを入力してください'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('本文を入力してください'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_currentCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('企業情報を取得できません'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 画像アップロード処理
      int? photo1Id;
      int? photo2Id;
      int? photo3Id;

      if (_selectedImages.isNotEmpty) {
        // 最大3枚まで画像をアップロード
        for (int i = 0; i < _selectedImages.length && i < 3; i++) {
          try {
            final photoDTO = await PhotoApiClient.uploadPhoto(
              _selectedImages[i],
              userId: _currentCompanyId,
            );

            if (i == 0) {
              photo1Id = photoDTO.id;
            } else if (i == 1) {
              photo2Id = photoDTO.id;
            } else if (i == 2) {
              photo3Id = photoDTO.id;
            }
          } catch (e) {
            // 画像アップロードに失敗した場合もエラーとして扱う
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('画像${i + 1}のアップロードに失敗しました: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      }

      // タグを正規化（trim/重複排除）
      final normalizedTags =
          _selectedTags
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList();

      // 記事データを作成
      final articleDTO = ArticleDTO(
        companyId: _currentCompanyId!,
        title: _titleController.text,
        description: _contentController.text,
        tags: normalizedTags.isNotEmpty ? normalizedTags : null,
        totalLikes: 0,
        isDeleted: false,
        photo1Id: photo1Id,
        photo2Id: photo2Id,
        photo3Id: photo3Id,
      );

      // API呼び出しで記事を作成
      final createdArticle = await ArticleApiClient.createArticle(articleDTO);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('記事「${createdArticle.title}」を投稿しました'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      // 投稿後は記事一覧画面に遷移
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CompanyArticleListPage()),
        (route) => route.isFirst,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('投稿に失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
