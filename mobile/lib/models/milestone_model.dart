import 'package:flutter/material.dart';

enum MilestoneCategory {
  commit,
  streak,
  goal
}

enum MilestoneStatus {
  locked,
  inProgress,
  completed
}

class MilestoneModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final MilestoneCategory category;
  final int targetValue;
  final int currentValue;
  final DateTime? unlockedAt;

  MilestoneModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    this.unlockedAt,
  });

  MilestoneStatus get status {
    if (currentValue >= targetValue) return MilestoneStatus.completed;
    if (currentValue > 0) return MilestoneStatus.inProgress;
    return MilestoneStatus.locked;
  }

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    return MilestoneModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'),
      category: MilestoneCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
      ),
      targetValue: json['targetValue'],
      currentValue: json['currentValue'],
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'category': category.toString(),
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
} 