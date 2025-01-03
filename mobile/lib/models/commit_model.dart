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
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? 'No message',
      timestamp: json['date'] != null 
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      repository: json['repository']?.toString() ?? 'Unknown repository',
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