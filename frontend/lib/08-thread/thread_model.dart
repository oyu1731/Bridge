class Thread {
  final String id;
  final String title;
  final int type;
  final String description;
  final int entryCriteria;
  final DateTime? lastCommentDate;
  final String timeAgo;

  Thread({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.entryCriteria,
    this.lastCommentDate,
    required this.timeAgo,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    String timeAgoText = "";
    DateTime? lastUpdateDate;

    final lastUpdateStr = json["lastUpdateDate"];
    if (lastUpdateStr != null && lastUpdateStr != "") {
      lastUpdateDate = DateTime.parse(lastUpdateStr);
      timeAgoText = _formatTimeAgo(lastUpdateDate);
    }

    return Thread(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      type: json['type'] != null ? int.parse(json['type'].toString()) : 2,
      description: json['description']?.toString() ?? '',
      entryCriteria: json['entryCriteria'],
      lastCommentDate: lastUpdateDate,
      timeAgo: timeAgoText,
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
