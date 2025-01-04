class UserModel {
  final String username;
  final String avatarUrl;
  final String name;
  final String? bio;
  final int? commitGoal;

  UserModel({
    required this.username,
    required this.avatarUrl,
    required this.name,
    this.bio,
    this.commitGoal,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Get avatar URL from either Firebase (avatarUrl) or GitHub (avatar_url)
    String? avatar = json['avatarUrl'];
    if (avatar == null || avatar.isEmpty) {
      avatar = json['avatar_url'];
    }
    if (avatar == null || avatar.isEmpty) {
      avatar = 'https://github.com/identicons/default.png';
    }

    return UserModel(
      username: json['username'] ?? json['login'] ?? '',
      avatarUrl: avatar,
      name: json['name'] ?? json['username'] ?? json['login'] ?? '',
      bio: json['bio'],
      commitGoal: json['commitGoal'] is String 
          ? int.tryParse(json['commitGoal']) 
          : json['commitGoal'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'avatarUrl': avatarUrl,
      'name': name,
      'bio': bio,
      'commitGoal': commitGoal,
    };
  }
} 