class Thread {
  final String id;
  final String title;
  final int type;
  final String description;
  final int entryCriteria;
  final DateTime? lastCommentDate;
  final DateTime? lastReportedAt;
  final String timeAgo;
  final String? adminTimeAgo;

  Thread({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.entryCriteria,
    this.lastCommentDate,
    this.lastReportedAt,
    required this.timeAgo,
    this.adminTimeAgo,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    String timeAgoText = "";
    String? adminTimeAgoText;
    DateTime? lastUpdateDate;
    DateTime? lastReportedAt;

    final lastUpdateStr = json["lastUpdateDate"];
    if (lastUpdateStr != null && lastUpdateStr != "") {
      lastUpdateDate = DateTime.parse(lastUpdateStr);
      timeAgoText = _formatTimeAgo(lastUpdateDate);
    }

    if (json['lastReportedAt'] != null) {
      lastReportedAt = DateTime.parse(json['lastReportedAt']);
      adminTimeAgoText = _formatTimeAgo(lastReportedAt);
    }

    return Thread(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      type: json['type'] != null ? int.parse(json['type'].toString()) : 2,
      description: json['description']?.toString() ?? '',
      entryCriteria: json['entryCriteria'],
      lastCommentDate: lastUpdateDate,
      lastReportedAt: lastReportedAt,
      timeAgo: timeAgoText,
      adminTimeAgo: adminTimeAgoText,
    );
  }

  static String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }
}
