import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class InterviewPractice extends StatefulWidget {
  const InterviewPractice({super.key});

  @override
  State<InterviewPractice> createState() => _InterviewPracticeState();
}

class _InterviewPracticeState extends State<InterviewPractice> {
  // --- Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController careerController = TextEditingController();

  // --- Dropdown values ---
  String? selectedIndustry;
  String? selectedScale;
  String? selectedAtmosphere;

  // --- Question count ---
  int questionCount = 5;

  // --- Review type ---
  String reviewType = "each"; // each / all

  // --- Question type ---
  String selectedQuestionType = "normal"; // normal / casual / pressure

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _openSettingPopup());
  }

  // -------------------------------------------------------------
  //                    面接設定ポップアップ
  // -------------------------------------------------------------
  void _openSettingPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.88,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル
                Center(
                  child: Text(
                    "面接設定",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),

                // ------------------- あなたの情報 -------------------
                Text(
                  "あなたの情報",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                _inputField("お名前", nameController),
                SizedBox(height: 12),
                _inputField("経歴", careerController, maxLines: 3),

                SizedBox(height: 25),

                // ------------------- 応募先企業の情報 -------------------
                Text(
                  "応募先企業の情報",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                _dropdown("業界", [
                  "IT",
                  "商社",
                  "広告",
                  "メーカー",
                ], (value) => setState(() => selectedIndustry = value)),
                SizedBox(height: 10),

                _dropdown("企業規模", [
                  "大企業",
                  "中小企業",
                  "スタートアップ",
                ], (value) => setState(() => selectedScale = value)),
                SizedBox(height: 10),

                _dropdown("企業の雰囲気", [
                  "堅実",
                  "フランク",
                  "体育会系",
                ], (value) => setState(() => selectedAtmosphere = value)),

                SizedBox(height: 25),

                // ------------------- 想定質問タイプ -------------------
                Text(
                  "想定する質問タイプ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                _buildQuestionTypeCards(),

                SizedBox(height: 25),

                // ------------------- その他設定 -------------------
                Text(
                  "その他設定",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),

                // --- 質問数 ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("想定質問数", style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (questionCount > 1) questionCount--;
                            });
                          },
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          "$questionCount",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (questionCount < 20) questionCount++;
                            });
                          },
                          icon: Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // --- レビュー形式 ---
                Text(
                  "レビュー形式",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                _reviewTypeButtons(),

                SizedBox(height: 30),

                // ------------------- 面接開始 -------------------
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("面接を開始する", style: TextStyle(fontSize: 18)),
                  ),
                ),

                SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // UIパーツ
  // ---------------------------------------------------------
  Widget _inputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            hint: Text("選択してください"),
            underline: SizedBox(),
            value: items.contains(selectedIndustry) ? selectedIndustry : null,
            isExpanded: true,
            items:
                items
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // 質問タイプ カード表示
  Widget _buildQuestionTypeCards() {
    return Column(
      children: [
        _questionTypeCard(
          type: "normal",
          title: "一般質問",
          desc: "就活でよく聞かれる基本的な質問を中心に練習できます。",
          image: "../lib/01-images/question-type-1.png",
          premium: false,
        ),
        SizedBox(height: 12),
        _questionTypeCard(
          type: "casual",
          title: "カジュアル",
          desc: "雑談を交えた自然な会話形式で練習できます。",
          image: "../lib/01-images/question-type-2.png",
          premium: true,
        ),
        SizedBox(height: 12),
        _questionTypeCard(
          type: "pressure",
          title: "圧迫気味",
          desc: "少し緊張感のある質問で本番の緊張に慣れましょう。",
          image: "../lib/01-images/question-type-3.png",
          premium: true,
        ),
      ],
    );
  }

  Widget _questionTypeCard({
    required String type,
    required String title,
    required String desc,
    required String image,
    required bool premium,
  }) {
    final bool selected = selectedQuestionType == type;

    return GestureDetector(
      onTap: () {
        setState(() => selectedQuestionType = type);
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 画像
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),

            SizedBox(width: 12),

            // テキスト
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (premium)
                        Container(
                          margin: EdgeInsets.only(left: 6),
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "PREMIUM",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // レビュー形式の選択ボタン
  Widget _reviewTypeButtons() {
    return Column(
      children: [
        _reviewButton(
          title: "解答ごとにレビュー",
          desc: "各質問の後にフィードバックを得れます。",
          value: "each",
        ),
        SizedBox(height: 10),
        _reviewButton(
          title: "全解答後にまとめてレビュー",
          desc: "すべての質問に回答した後に、総合的なフィードバックを得れます。",
          value: "all",
        ),
      ],
    );
  }

  Widget _reviewButton({
    required String title,
    required String desc,
    required String value,
  }) {
    final bool selected = (reviewType == value);

    return GestureDetector(
      onTap: () => setState(() => reviewType = value),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Colors.blue : Colors.grey,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // 画面本体
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Center(
        child: Text("面接設定が完了するとここに面接画面が表示されます", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
