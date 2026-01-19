import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../11-common/58-header.dart';
import '17-company-article-list.dart';
import 'article_api_client.dart';
import 'filter_api_client.dart';
import 'photo_api_client.dart';

class ArticleEditPage extends StatefulWidget {
  final String articleId;
  final String initialTitle;
  final List<String> initialTags;
  final List<String> initialImages;
  final String initialContent;

  const ArticleEditPage({
    Key? key,
    required this.articleId,
    this.initialTitle = '',
    this.initialTags = const [],
    this.initialImages = const [],
    this.initialContent = '',
  }) : super(key: key);

  @override
  _ArticleEditPageState createState() => _ArticleEditPageState();
}

class _ArticleEditPageState extends State<ArticleEditPage> {
      static const int maxTagCount = 4;
    // 文字数制限
    static const int maxTitleLength = 40;
    static const int maxContentLength = 2000;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  List<String> _selectedTags = [];
  List<XFile> _selectedImages = [];
  List<TagDTO> _availableTags = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  // 既存写真IDと削除フラグ
  int? _photo1Id;
  int? _photo2Id;
  int? _photo3Id;
  bool _deletePhoto1 = false;
  bool _deletePhoto2 = false;
  bool _deletePhoto3 = false;
  int? _companyId;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle;
    _contentController.text = widget.initialContent;
    _selectedTags = List.from(widget.initialTags);
    
    _loadAvailableTags();
    _loadArticleIfNeeded();
  }

  Future<void> _loadArticleIfNeeded() async {
    try {
      final id = int.tryParse(widget.articleId);
      if (id == null) return;
      final article = await ArticleApiClient.getArticleById(id);
      if (article == null) return;
      setState(() {
        // 既存写真ID
        _photo1Id = article.photo1Id;
        _photo2Id = article.photo2Id;
        _photo3Id = article.photo3Id;
        _companyId = article.companyId;
        // タイトル/本文は初期値が空の場合のみ反映
        if (_titleController.text.isEmpty) {
          _titleController.text = article.title;
        }
        if (_contentController.text.isEmpty) {
          _contentController.text = article.description;
        }
        if (_selectedTags.isEmpty && (article.tags ?? []).isNotEmpty) {
          _selectedTags = List.from(article.tags!);
        }
      });
    } catch (e) {
      // ロード失敗は致命的でないためログのみ
      print('記事の読み込みに失敗: $e');
    }
  }

  Future<void> _loadAvailableTags() async {
    try {
      final tags = await FilterApiClient.getAllTags();
      setState(() {
        _availableTags = tags;
      });
    } catch (e) {
      print('タグの取得に失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        border: Border.all(color: Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Color(0xFF424242), size: 20),
                          SizedBox(width: 8),
                          Text(
                            '記事編集',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTitleSection(),
                    const SizedBox(height: 16),
                    _buildTagSection(),
                    const SizedBox(height: 16),
                    _buildImageSection(),
                    const SizedBox(height: 16),
                    _buildContentSection(),
                    const SizedBox(height: 24),
                    _buildActionButtonsSection(),
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
            maxLength: maxTitleLength,
            decoration: InputDecoration(
              hintText: 'タイトルを入力（最大${maxTitleLength}文字）',
              hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
              counterText: '',
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

  Widget _buildTagChip(String tagName) {
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
            tagName,
            style: TextStyle(fontSize: 12, color: Color(0xFF1976D2)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedTags.remove(tagName);
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
            '画像 (最大3枚)',
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
              ..._selectedImages.asMap().entries.map((entry) => _buildImageChip(entry.key)),
              if (_selectedImages.length < _remainingNewSlots()) _buildAddImageButton(),
            ],
          ),
        ),
        SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '追加可能枚数: ${_remainingAddableCount()}枚',
            style: TextStyle(fontSize: 12, color: Color(0xFF424242)),
          ),
        ),
        const SizedBox(height: 8),
        _buildExistingPhotosDeleteSection(),
      ],
    );
  }

  int _remainingNewSlots() {
    int existing = 0;
    if (_photo1Id != null && !_deletePhoto1) existing++;
    if (_photo2Id != null && !_deletePhoto2) existing++;
    if (_photo3Id != null && !_deletePhoto3) existing++;
    final rem = 3 - existing;
    return rem < 0 ? 0 : rem;
  }

  int _remainingAddableCount() {
    final rem = _remainingNewSlots() - _selectedImages.length;
    return rem < 0 ? 0 : rem;
  }

  void _applyCapacityAfterToggle() {
    final capacity = _remainingNewSlots();
    int removed = 0;
    while (_selectedImages.length > capacity) {
      _selectedImages.removeLast();
      removed++;
    }
    if (removed > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('上限超過のため最新の画像を${removed}枚削除しました'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildExistingPhotosDeleteSection() {
    // 既存写真が一つも無ければ表示しない
    final hasAny = _photo1Id != null || _photo2Id != null || _photo3Id != null;
    if (!hasAny) return SizedBox.shrink();

    Widget row({required String label, required int? id, required bool flag, required ValueChanged<bool?> onChanged}) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: Color(0xFF424242))),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: id != null ? Color(0xFFE8F5E9) : Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                id != null ? 'あり(ID:$id)' : 'なし',
                style: TextStyle(
                  fontSize: 11,
                  color: id != null ? Color(0xFF2E7D32) : Color(0xFFC62828),
                ),
              ),
            ),
            Spacer(),
            if (id != null)
              Row(
                children: [
                  Text('削除', style: TextStyle(fontSize: 13, color: Color(0xFF424242))),
                  SizedBox(width: 4),
                  Checkbox(value: flag, onChanged: onChanged),
                ],
              ),
          ],
        ),
      );
    }

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
            '既存画像の削除',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF424242)),
          ),
        ),
        row(
          label: '写真1',
          id: _photo1Id,
          flag: _deletePhoto1,
          onChanged: (v) {
            setState(() {
              _deletePhoto1 = v ?? false;
              _applyCapacityAfterToggle();
            });
          },
        ),
        row(
          label: '写真2',
          id: _photo2Id,
          flag: _deletePhoto2,
          onChanged: (v) {
            setState(() {
              _deletePhoto2 = v ?? false;
              _applyCapacityAfterToggle();
            });
          },
        ),
        row(
          label: '写真3',
          id: _photo3Id,
          flag: _deletePhoto3,
          onChanged: (v) {
            setState(() {
              _deletePhoto3 = v ?? false;
              _applyCapacityAfterToggle();
            });
          },
        ),
      ],
    );
  }

  Widget _buildImageChip(int index) {
    final image = _selectedImages[index];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            image.name,
            style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedImages.removeAt(index);
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
            maxLength: maxContentLength,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: '記事の本文を入力してください（最大${maxContentLength}文字）',
              hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
              counterText: '',
            ),
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 48,
          child: ElevatedButton(
            onPressed: _showDeleteConfirmationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              '削除',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(width: 16),
        Container(
          width: 120,
          height: 48,
          child: ElevatedButton(
            onPressed: _updateArticle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF9800),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              '完了',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _showTagSelectionModal() {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'タグ追加（最大${maxTagCount}個）',
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
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
                          childAspectRatio: MediaQuery.of(context).size.width > 800 ? 2.2 : 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _availableTags.length,
                        itemBuilder: (context, index) {
                          final tag = _availableTags[index].tag;
                          final isSelected = tempSelectedTags.contains(tag);
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  tempSelectedTags.remove(tag);
                                } else {
                                  if (tempSelectedTags.length >= maxTagCount) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('タグは最大${maxTagCount}個まで選択できます'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  tempSelectedTags.add(tag);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFFE3F2FD) : Colors.white,
                                border: Border.all(
                                  color: isSelected ? Color(0xFF1976D2) : Color(0xFFE0E0E0),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                    size: MediaQuery.of(context).size.width > 800 ? 20 : 16,
                                    color: isSelected ? Color(0xFF1976D2) : Color(0xFF757575),
                                  ),
                                  SizedBox(width: MediaQuery.of(context).size.width > 800 ? 8 : 4),
                                  Expanded(
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width > 800 ? 14 : 10,
                                        color: isSelected ? Color(0xFF1976D2) : Color(0xFF424242),
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
                    Container(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
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
    // 事前制限: 残りスロットがない場合拒否
    if (_selectedImages.length >= _remainingNewSlots()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('これ以上追加できません (最大3枚、既存含む)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
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

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            '確認',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '本当にこの記事を削除しますか?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('戻る', style: TextStyle(color: Color(0xFF757575))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteArticle();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD32F2F),
                foregroundColor: Colors.white,
              ),
              child: Text('削除', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteArticle() async {
    setState(() => _isLoading = true);

    try {
      final articleId = int.tryParse(widget.articleId);
      if (articleId == null) {
        throw Exception('無効な記事IDです');
      }

      await ArticleApiClient.deleteArticle(articleId);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20),
                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48),
                SizedBox(height: 16),
                Text(
                  '記事を削除しました',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // ダイアログを閉じる
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyArticleListPage(),
                        ),
                        (route) => route.isFirst, // ホーム画面まで戻る
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '記事一覧へ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('記事の削除に失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateArticle() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('タイトルを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (title.length > maxTitleLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('タイトルは${maxTitleLength}文字以内で入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('本文を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (content.length > maxContentLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('本文は${maxContentLength}文字以内で入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final articleId = int.tryParse(widget.articleId);
      if (articleId == null) {
        throw Exception('無効な記事IDです');
      }

      // 1) 既存写真の削除フラグに応じて削除
      final deleteOps = <Future<void>>[];
      if (_deletePhoto1 && _photo1Id != null) {
        deleteOps.add(PhotoApiClient.deletePhoto(_photo1Id!));
      }
      if (_deletePhoto2 && _photo2Id != null) {
        deleteOps.add(PhotoApiClient.deletePhoto(_photo2Id!));
      }
      if (_deletePhoto3 && _photo3Id != null) {
        deleteOps.add(PhotoApiClient.deletePhoto(_photo3Id!));
      }
      if (deleteOps.isNotEmpty) {
        try {
          await Future.wait(deleteOps);
        } catch (e) {
          // 個別削除失敗しても続行（後続の更新でnullにする）
          print('写真削除に失敗: $e');
        }
      }
      if (_deletePhoto1) _photo1Id = null;
      if (_deletePhoto2) _photo2Id = null;
      if (_deletePhoto3) _photo3Id = null;

      // 2) 新規アップロードして空スロットに割当
      final currentIds = <int?>[_photo1Id, _photo2Id, _photo3Id];
      for (int i = 0; i < _selectedImages.length && i < 3; i++) {
        try {
          final photoDTO = await PhotoApiClient.uploadPhoto(_selectedImages[i]);
          final newId = photoDTO.id;
          if (newId == null) continue;
          final idx = currentIds.indexWhere((e) => e == null);
          if (idx != -1) {
            currentIds[idx] = newId;
          }
        } catch (e) {
          print('画像${i + 1}のアップロードに失敗: $e');
        }
      }

      // 3) 記事更新
      final articleDTO = ArticleDTO(
        id: articleId,
        companyId: _companyId ?? 0,
        title: _titleController.text.trim(),
        description: _contentController.text.trim(),
        photo1Id: currentIds[0],
        photo2Id: currentIds[1],
        photo3Id: currentIds[2],
        tags: _selectedTags,
      );

      await ArticleApiClient.updateArticle(articleId, articleDTO);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('記事を更新しました'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      // 記事一覧画面に遷移
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => CompanyArticleListPage(),
            ),
            (route) => route.isFirst,
          );
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('記事の更新に失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
