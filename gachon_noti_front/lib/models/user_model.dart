class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> subscribedBoards;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.subscribedBoards,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> boards = [];
    if (json['subscribedBoards'] != null) {
      if (json['subscribedBoards'] is List) {
        boards = List<String>.from(json['subscribedBoards']);
      } else if (json['subscribedBoards'] is String) {
        // JSON에서는 문자열 형태일 수 있으므로 변환
        boards = json['subscribedBoards'].toString().split(',');
      }
    }

    return UserModel(
      id: json['\$id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      subscribedBoards: boards,
      fcmToken: json['fcmToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'subscribedBoards': subscribedBoards,
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    List<String>? subscribedBoards,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      subscribedBoards: subscribedBoards ?? this.subscribedBoards,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
