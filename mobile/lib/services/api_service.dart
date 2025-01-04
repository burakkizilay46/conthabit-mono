import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:conthabit/models/commit_model.dart';
import 'package:conthabit/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:conthabit/models/milestone_model.dart';

class ApiService {
  static String get _baseUrl {
    return 'https://conthabit-mono.onrender.com';
  }

  static String get _mobileRedirectUrl {
    if (kDebugMode) {
      return 'conthabit://oauth/callback';
    }
    return 'com.conthabit.app://oauth/callback';
  }

  static const _storage = FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication
  Future<String?> getAuthToken() async {
    try {
      // Try to get stored token first
      final storedToken = await _storage.read(key: 'auth_token');
      if (storedToken != null) {
        return storedToken;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  Future<void> saveAuthToken(String token) async {
    try {
      // Only save to secure storage
      await _storage.write(key: 'auth_token', value: token);
      debugPrint('Token saved to secure storage');
    } catch (e) {
      debugPrint('Error saving auth token: $e');
      throw Exception('Failed to save authentication token');
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: 'auth_token');
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Ensure storage is cleared even if Firebase logout fails
      await _storage.delete(key: 'auth_token');
    }
  }

  Future<String> _getRequiredAuthToken() async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception('No auth token found. Please log in.');
    }
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getRequiredAuthToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Error Handler
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        if (response.body.isEmpty) {
          return {};
        }
        return jsonDecode(response.body);
      } catch (e) {
        debugPrint('Failed to parse response body: ${response.body}');
        throw Exception('Failed to parse response: $e');
      }
    }

    debugPrint(
        'Error response: ${response.statusCode}, body: ${response.body}');
    if (response.headers['content-type']?.contains('application/json') ==
        true) {
      final errorMessage =
          jsonDecode(response.body)['message'] ?? 'Unknown error';
      throw Exception('Error: $errorMessage');
    }

    switch (response.statusCode) {
      case 401:
        throw Exception('Unauthorized. Please log in again.');
      case 403:
        throw Exception('Access forbidden.');
      case 404:
        throw Exception('Resource not found.');
      case 429:
        throw Exception('Too many requests. Please try again later.');
      default:
        throw Exception('An error occurred: ${response.statusCode}');
    }
  }

  // GitHub OAuth
  Future<String> initiateGitHubOAuth() async {
    try {
      debugPrint('Initiating GitHub OAuth');

      final mobileRedirect = Uri.encodeComponent(_mobileRedirectUrl);
      final backendCallback =
          Uri.encodeComponent('$_baseUrl/auth/github/callback');

      final response = await http
          .get(Uri.parse(
              '$_baseUrl/auth/github/init?mobile_redirect=$mobileRedirect&backend_callback=$backendCallback'))
          .timeout(const Duration(seconds: 10));

      debugPrint('OAuth init response status: ${response.statusCode}');
      debugPrint('OAuth init response body: ${response.body}');

      final data = _handleResponse(response);

      if (!data.containsKey('authUrl')) {
        debugPrint('Response data: $data');
        throw Exception('Invalid response format: Missing authUrl');
      }

      final authUrl = data['authUrl'] as String;
      debugPrint('Received authUrl: $authUrl');

      // Validate the URL
      final uri = Uri.parse(authUrl);
      if (!uri.host.contains('github.com')) {
        throw Exception('Invalid GitHub OAuth URL');
      }

      return authUrl;
    } catch (e) {
      debugPrint('GitHub OAuth initiation error: $e');
      throw Exception('Failed to initiate GitHub OAuth: $e');
    }
  }

  Future<void> handleAuthCallback(String code) async {
    try {
      debugPrint('Exchanging code for token');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/github/callback'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code}),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Token exchange response status: ${response.statusCode}');

      final data = _handleResponse(response);
      if (!data.containsKey('token')) {
        debugPrint('Response data: $data');
        throw Exception('Invalid response format: Missing token');
      }

      final token = data['token'] as String;
      debugPrint('Received token, saving...');

      // Save the token to secure storage
      await saveAuthToken(token);
      debugPrint('Auth token saved successfully');

      // Initialize anonymous Firebase session for app functionality
      if (_auth.currentUser == null) {
        try {
          await _auth.signInAnonymously();
          debugPrint('Anonymous Firebase session created');
        } catch (e) {
          debugPrint('Failed to create anonymous session (non-critical): $e');
          // Continue even if anonymous sign-in fails
        }
      }
    } catch (e) {
      debugPrint('Error handling auth callback: $e');
      throw Exception('Failed to complete authentication: $e');
    }
  }

  // Commit Data
  Future<List<CommitModel>> getCommits() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl/api/commits'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 204) {
        return [];
      }

      final data = _handleResponse(response);
      if (data == null) return [];

      // Handle the new response format
      if (data is Map<String, dynamic> && data.containsKey('commits')) {
        final commits = data['commits'] as List;
        return commits.map((json) => CommitModel.fromJson(json)).toList();
      }

      // Fallback for old format or unexpected response
      if (data is! List) {
        debugPrint('Unexpected response format: ${response.body}');
        return [];
      }

      return data.map((json) => CommitModel.fromJson(json)).toList();
    } on TimeoutException {
      debugPrint('Request timed out while fetching commits');
      throw Exception(
          'Connection timed out. Please check your internet connection and try again.');
    } catch (e) {
      debugPrint('Get commits error: $e');
      throw Exception('Failed to load commits: $e');
    }
  }

  Future<bool> hasCommittedToday() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl/api/commits/today'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 204) {
        return false;
      }

      final data = _handleResponse(response);
      
      // Handle the new response format
      if (data is Map<String, dynamic>) {
        final hasCommitted = data['hasCommitted'] as bool? ?? false;
        
        // If there are new milestones, trigger a celebration
        final newMilestones = data['newMilestones'] as List? ?? [];
        if (newMilestones.isNotEmpty) {
          // Notify the UI about new milestones (you'll need to implement this)
          debugPrint('New milestones unlocked: $newMilestones');
        }
        
        return hasCommitted;
      }
      
      return false;
    } on TimeoutException {
      debugPrint('Request timed out while checking today\'s commits');
      throw Exception(
          'Connection timed out. Please check your internet connection and try again.');
    } catch (e) {
      debugPrint('Check today\'s commit error: $e');
      throw Exception('Failed to check today\'s commit status: $e');
    }
  }

  // Settings
  Future<void> updateReminderTime(TimeOfDay time) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/settings/reminder'),
            headers: headers,
            body: jsonEncode({'hour': time.hour, 'minute': time.minute}),
          )
          .timeout(const Duration(seconds: 10));
      _handleResponse(response);
    } catch (e) {
      debugPrint('Update reminder time error: $e');
      throw Exception('Failed to update reminder time: $e');
    }
  }

  Future<void> updateCommitGoal(int goal) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/settings/goal'),
            headers: headers,
            body: jsonEncode({'goal': goal}),
          )
          .timeout(const Duration(seconds: 10));
      _handleResponse(response);
    } catch (e) {
      debugPrint('Update commit goal error: $e');
      throw Exception('Failed to update commit goal: $e');
    }
  }

  Future<UserModel> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl/auth/user'), headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('User profile response: ${response.body}');
      final data = _handleResponse(response);
      return UserModel.fromJson(data);
    } on TimeoutException {
      debugPrint('Request timed out while fetching user profile');
      throw Exception('Connection timed out. Please check your internet connection and try again.');
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      // Get user data which includes the commit goal
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl/auth/user'), headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('User settings response: ${response.body}');
      final data = _handleResponse(response);
      final commitGoal = data['commitGoal'] ?? 1000;
      debugPrint('Retrieved commit goal from user data: $commitGoal');
      return {
        'commitGoal': commitGoal,
      };
    } catch (e) {
      debugPrint('Error getting user settings: $e');
      throw Exception('Failed to get user settings');
    }
  }

  Future<List<MilestoneModel>> getMilestones() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl/api/milestones'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 204) {
        return _getDefaultMilestones();
      }

      final data = _handleResponse(response);
      if (data == null || data is! List) {
        return _getDefaultMilestones();
      }

      return data.map((json) => MilestoneModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching milestones: $e');
      return _getDefaultMilestones();
    }
  }

  Future<List<MilestoneModel>> _getDefaultMilestones() async {
    final commits = await getCommits();
    final settings = await getUserSettings();
    final commitGoal = settings['commitGoal'] as int? ?? 1000;

    return [
      MilestoneModel(
        id: '1',
        title: '25 Commits',
        description: 'Complete 25 commits',
        icon: Icons.star,
        category: MilestoneCategory.commit,
        targetValue: 25,
        currentValue: commits.length,
      ),
      MilestoneModel(
        id: '2',
        title: '7-Day Streak',
        description: 'Maintain a 7-day commit streak',
        icon: Icons.local_fire_department,
        category: MilestoneCategory.streak,
        targetValue: 7,
        currentValue: 0,
      ),
      MilestoneModel(
        id: '3',
        title: 'Halfway There',
        description: 'Reach 50% of your commit goal',
        icon: Icons.flag,
        category: MilestoneCategory.goal,
        targetValue: 50,
        currentValue: ((commits.length / commitGoal) * 100).round(),
      ),
    ];
  }
}
