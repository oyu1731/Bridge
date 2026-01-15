import 'package:bridge/06-company/api_config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/59-global-method.dart';
import '52-payment-input-student.dart';

final globalActions = GlobalActions();

class PlanStatusScreen extends StatefulWidget {
  final String userType;
  const PlanStatusScreen({Key? key, required this.userType}) : super(key: key);

  @override
  State<PlanStatusScreen> createState() => _PlanStatusScreenState();
}

class _PlanStatusScreenState extends State<PlanStatusScreen>
    with SingleTickerProviderStateMixin {
  String _planStatus = '不明';
  String _nickname = 'ゲスト';
  int? _userId;
  String? _startDate;
  String? _endDate;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadPlanStatus();
  }

  Future<void> _loadPlanStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('current_user');

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> userData = jsonDecode(jsonString);
        setState(() {
          _nickname = userData['nickname'] ?? 'ユーザー';
          _userId = userData['id'];
        });

        if (_userId != null) {
          await _fetchSubscription(_userId!);
        } else {
          setState(() {
            _planStatus = '無料';
          });
        }
      } catch (e) {
        setState(() {
          _planStatus = '取得失敗';
        });
      }
    } else {
      setState(() {
        _planStatus = '未ログイン';
      });
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  /// サブスクリプション情報を取得するメソッド
  /// 期限切れやデータなしの場合は 404 を想定し、その場合は無料プランとして扱う
  Future<void> _fetchSubscription(int userId) async {
    try {
      final response = await http.get(
        // Uri.parse('http://localhost:8080/api/subscriptions/user/$userId'),
        Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/user/$userId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _planStatus = 'プレミアム';
          // APIから取得した日付を表示形式(yyyy-MM-dd)に整形
          _startDate =
              data['startDate'] != null
                  ? data['startDate'].toString().substring(0, 10)
                  : null;
          _endDate =
              data['endDate'] != null
                  ? data['endDate'].toString().substring(0, 10)
                  : null;
        });
      } else {
        // 404などのエラー時は、日付データを含めてリセットする
        _resetToFreePlan();
      }
    } catch (e) {
      print('サブスクリプション取得エラー: $e');
      _resetToFreePlan();
    }
  }

  void _resetToFreePlan() {
    if (mounted) {
      setState(() {
        _planStatus = '無料';
        _startDate = null;
        _endDate = null;
      });
    }
  }

  void _upgradeToPremium() async {
    if (_userId == null) return;

    int amount = (widget.userType == '企業') ? 5000 : 500;
    String planType = "プレミアム";

    await startWebCheckout(
      amount: amount,
      currency: "JPY",
      planType: planType,
      userId: _userId!,
      userType: widget.userType,
    );
  }

  Widget _buildUserInfoCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.purple.shade50],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _nickname.isNotEmpty ? _nickname[0] : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nickname,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getUserTypeIcon(),
                          color: Colors.blue.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.userType,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: $_userId',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getUserTypeIcon() {
    switch (widget.userType) {
      case '学生':
        return Icons.school;
      case '社会人':
        return Icons.work;
      case '企業':
        return Icons.business;
      default:
        return Icons.person;
    }
  }

  Widget _buildPlanStatusCard() {
    final bool isPremium = _planStatus == 'プレミアム';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isPremium
                      ? [Colors.green.shade50, Colors.teal.shade50]
                      : [Colors.orange.shade50, Colors.yellow.shade50],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '現在のプラン',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    isPremium
                                        ? [
                                          Colors.green.shade400,
                                          Colors.teal.shade400,
                                        ]
                                        : [
                                          Colors.orange.shade400,
                                          Colors.amber.shade400,
                                        ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (isPremium
                                          ? Colors.green
                                          : Colors.orange)
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPremium ? Icons.star : Icons.star_border,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isPremium ? 'プレミアム' : '無料プラン',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isPremium)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.green,
                        size: 32,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (isPremium && _startDate != null && _endDate != null) ...[
                _buildDateInfo(),
                const SizedBox(height: 24),
              ],
              _buildPlanFeatures(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateInfo() {
    final now = DateTime.now();
    DateTime? end;
    try {
      end = _endDate != null ? DateTime.parse(_endDate!) : null;
    } catch (e) {
      end = null;
    }
    final daysLeft = end != null ? end.difference(now).inDays : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'サブスクリプション期間',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '開始日',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _startDate ?? '--',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '終了日',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _endDate ?? '--',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (daysLeft >= 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    daysLeft <= 7
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      daysLeft <= 7
                          ? Colors.orange.shade200
                          : Colors.green.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    color: daysLeft <= 7 ? Colors.orange : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    daysLeft <= 7 ? 'あと${daysLeft}日で期限切れ' : 'あと${daysLeft}日間有効',
                    style: TextStyle(
                      color: daysLeft <= 7 ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanFeatures() {
    final bool isPremium = _planStatus == 'プレミアム';

    List<Map<String, dynamic>> features = [
      {'icon': Icons.auto_awesome, 'text': 'AIトレーニング機能', 'premium': true},
      {'icon': Icons.business, 'text': '企業情報閲覧', 'premium': true},
      if (widget.userType == '企業')
        {'icon': Icons.work, 'text': '求人掲載（3件まで）', 'premium': true},
      {'icon': Icons.support_agent, 'text': '優先サポート', 'premium': true},
      {'icon': Icons.person, 'text': '基本プロフィール', 'premium': false},
      {'icon': Icons.search, 'text': '基本検索機能', 'premium': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'プラン特典',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) {
          final available = isPremium || !feature['premium'];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        available ? Colors.blue.shade50 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'],
                    color:
                        available ? Colors.blue.shade600 : Colors.grey.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature['text'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: available ? Colors.black87 : Colors.grey.shade500,
                      decoration: available ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
                Icon(
                  available ? Icons.check_circle : Icons.remove_circle_outline,
                  color: available ? Colors.green : Colors.grey.shade400,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildUpgradeButton() {
    if (_planStatus == 'プレミアム') return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.purple.shade400],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _upgradeToPremium,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'プレミアムにアップグレード',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'すべての機能を利用可能に',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.userType == '企業' ? '¥5,000/月' : '¥500/月',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BridgeHeader(),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.shade50.withOpacity(0.1),
                      Colors.purple.shade50.withOpacity(0.1),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildUserInfoCard(),
                        const SizedBox(height: 24),
                        _buildPlanStatusCard(),
                        const SizedBox(height: 24),
                        _buildUpgradeButton(),
                        const SizedBox(height: 30),
                        if (_planStatus == 'プレミアム')
                          Text(
                            '🎉 プレミアムプランをご利用いただきありがとうございます！',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
