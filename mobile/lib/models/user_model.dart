class UserModel {
  final String username;
  final String avatarUrl;
  final String name;
  final String? bio;

  UserModel({
    required this.username,
    required this.avatarUrl,
    required this.name,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['login'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'avatar_url': avatarUrl,
      'name': name,
      'bio': bio,
    };
  }
} 