class AdminArticleDTO {
  final int? id;
  final int companyId;
  final String companyName;
  final String title;
  final String description;
  final int? totalLikes;
  final String? createdAt;

  // 👇 これが無いと画像取得できない
  final int? photo1Id;
  final int? photo2Id;
  final int? photo3Id;

  final List<String> tags;

  AdminArticleDTO({
    this.id,
    required this.companyId,
    required this.companyName,
    required this.title,
    required this.description,
    this.totalLikes,
    this.createdAt,
    this.photo1Id,
    this.photo2Id,
    this.photo3Id,
    required this.tags,
  });

  factory AdminArticleDTO.fromJson(Map<String, dynamic> json) {
    return AdminArticleDTO(
      id: json['id'],
      companyId: json['companyId'],
      companyName: json['companyName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      totalLikes: json['totalLikes'],
      createdAt: json['createdAt'],

      // 👇 これ
      photo1Id: json['photo1Id'],
      photo2Id: json['photo2Id'],
      photo3Id: json['photo3Id'],

      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    );
  }
}
