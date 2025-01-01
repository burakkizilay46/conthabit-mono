class CommitModel {
  final String id;
  final String message;
  final DateTime timestamp;
  final String repository;

  CommitModel({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.repository,
  });

  factory CommitModel.fromJson(Map<String, dynamic> json) {
    return CommitModel(
      id: json['id'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      repository: json['repository'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'repository': repository,
    };
  }
} 