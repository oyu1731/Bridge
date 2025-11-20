import 'package:flutter/material.dart';
import '../11-common/58-header.dart';

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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  List<String> _selectedTags = [];
  List<String> _selectedImages = [];

  // 利用可能なタグリスト
  final List<String> _availableTags = [
    '説明会開催中', '会社員の日常', '今日のランチ',
    'インターン開催中', '若手社員のリアル', 'リモートワーク事情',
    '就活イベント情報', '先輩インタビュー', '社長の推しポイント',
    '新卒募集中', '新入社員インタビュー', '働く仲間たち',
    '中途採用あり', '会社紹介', '社会人の本音',
    'エントリー受付中', 'オフィス紹介', 'スレッド開設',
    '採用担当のつぶやき', '社内イベント', 'キャリアアドバイス',
    '選考のウラ話', '最新ニュース', '面接のコツ',
  ];

  @override
  void initState() {
    super.initState();
    // 初期値を設定
    _titleController.text = widget.initialTitle;
    _contentController.text = widget.initialContent;
    _selectedTags = List.from(widget.initialTags);
    _selectedImages = List.from(widget.initialImages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 記事編集タイトル
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Color(0xFF424242),
                      size: 20,
                    ),
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
              
              // ボタンセクション
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
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedTags.remove(tag);
              });
            },
            child: Icon(
              Icons.close,
              size: 16,
              color: Color(0xFF1976D2),
            ),
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
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 20,
        ),
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

  Widget _buildImageChip(String imageName) {
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
            imageName,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedImages.remove(imageName);
              });
            },
            child: Icon(
              Icons.close,
              size: 16,
              color: Color(0xFF2E7D32),
            ),
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
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 20,
        ),
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

  Widget _buildActionButtonsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 削除ボタン
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        // 完了ボタン
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTagSelectionModal() {
    // モーダル内で一時的に選択されたタグを管理
    Set<String> tempSelectedTags = Set.from(_selectedTags);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
                          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
                          childAspectRatio: MediaQuery.of(context).size.width > 800 ? 2.2 : 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _availableTags.length,
                        itemBuilder: (context, index) {
                          final tag = _availableTags[index];
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
    // 画像選択のシミュレーション
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('画像選択'),
          content: Text('画像選択機能のデモです。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedImages.add('image${_selectedImages.length + 1}.png');
                });
              },
              child: Text('画像を追加'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(
            '確認',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '本当にこの記事を削除しますか？',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '戻る',
                style: TextStyle(color: Color(0xFF757575)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // ダイアログを閉じる
                _deleteArticle();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD32F2F),
                foregroundColor: Colors.white,
              ),
              child: Text(
                '削除',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteArticle() {
    // 削除処理のシミュレーション
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20),
              Text(
                '記事を削除しました',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // ダイアログを閉じる
                    Navigator.pop(context); // 編集画面を閉じて記事一覧に戻る
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'トップページへ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateArticle() {
    // バリデーション
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('タイトルを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('本文を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 更新処理のシミュレーション
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('記事を更新しました'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );

    // 記事一覧に戻る
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}