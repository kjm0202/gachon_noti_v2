class NotificationItem {
  final String id;
  final String boardId;
  final String articleId;
  final String title;
  final String link;
  final String pubDate;
  final String author;
  final String description;
  final String createdAt;

  NotificationItem({
    required this.id,
    required this.boardId,
    required this.articleId,
    required this.title,
    required this.link,
    required this.pubDate,
    required this.author,
    required this.description,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['\$id'] ?? '',
      boardId: json['boardId'] ?? '',
      articleId: json['articleId'] ?? '',
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      pubDate: json['pubDate'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'boardId': boardId,
      'articleId': articleId,
      'title': title,
      'link': link,
      'pubDate': pubDate,
      'author': author,
      'description': description,
      'createdAt': createdAt,
    };
  }

  String getBoardName() {
    Map<String, String> boardNames = {
      'bachelor': '학사공지',
      'scholarship': '장학공지',
      'student': '학생공지',
      'job': '취업공지',
      'extracurricular': '교외활동',
      'other': '기타공지',
      'dormGlobal': '글로벌 기숙사',
      'dormMedical': '메디컬 기숙사',
    };

    return boardNames[boardId] ?? boardId;
  }
}
