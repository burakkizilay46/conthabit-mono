import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }

  static String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  static Color getProgressColor(double progress) {
    if (progress < 0.3) {
      return Colors.red;
    } else if (progress < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  static String formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
  }
} 