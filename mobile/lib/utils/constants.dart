class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/api';
  
  // GitHub Configuration
  static const String githubClientId = 'YOUR_GITHUB_CLIENT_ID';
  static const String githubRedirectUri = 'conthabit://oauth/callback';
  
  // Storage Keys
  static const String tokenKey = 'github_token';
  static const String themeKey = 'theme_mode';
  static const String reminderKey = 'reminder_time';
  static const String commitGoalKey = 'commit_goal';
  
  // Default Values
  static const int defaultCommitGoal = 1000;
  static const int defaultReminderHour = 20;
  static const int defaultReminderMinute = 0;
  
  // UI Constants
  static const double maxScreenWidth = 600.0;
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 8.0;
} 