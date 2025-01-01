import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:conthabit/models/commit_model.dart';
import 'package:flutter/material.dart';

class ApiService {
  static String get _baseUrl {
    if (Platform.isAndroid) {
      // Android emulator needs 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:3000';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://127.0.0.1:3000';
    } else {
      // For physical devices, you should use your actual backend URL
      return 'http://127.0.0.1:3000';
    }
  }
  static const _storage = FlutterSecureStorage();

  // Authentication
  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  // Error Handler
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print('Response body: ${response.body}');
        throw Exception('Failed to parse response: $e');
      }
    }

    print('Error response body: ${response.body}');
    switch (response.statusCode) {
      case 401:
        throw Exception('Unauthorized. Please login again.');
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
      print('Initiating GitHub OAuth with URL: $_baseUrl/auth/github/init');
      final response = await http.get(Uri.parse('$_baseUrl/auth/github/init'));
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      final data = jsonDecode(response.body);
      return data['authUrl'];
    } catch (e) {
      print('GitHub OAuth initiation error details: $e');
      throw Exception('Failed to initiate GitHub OAuth: $e');
    }
  }

  Future<void> completeGitHubOAuth(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/github/callback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to complete GitHub OAuth');
      }

      final data = jsonDecode(response.body);
      await saveAuthToken(data['token']);
    } catch (e) {
      throw Exception('Failed to complete GitHub OAuth: $e');
    }
  }

  // Commit Data
  Future<List<CommitModel>> getCommits() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/commits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = _handleResponse(response);
      return (data as List).map((json) => CommitModel.fromJson(json)).toList();
    } catch (e) {
      print('Get commits error: $e');
      throw Exception('Failed to load commits: $e');
    }
  }

  Future<bool> hasCommittedToday() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/commits/today'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = _handleResponse(response);
      return data['hasCommitted'] as bool;
    } catch (e) {
      print('Check today\'s commit error: $e');
      throw Exception('Failed to check today\'s commit status: $e');
    }
  }

  // Settings
  Future<void> updateReminderTime(TimeOfDay time) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/settings/reminder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'hour': time.hour,
          'minute': time.minute,
        }),
      );
      _handleResponse(response);
    } catch (e) {
      print('Update reminder time error: $e');
      throw Exception('Failed to update reminder time: $e');
    }
  }

  Future<void> updateCommitGoal(int goal) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/settings/goal'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'goal': goal}),
      );
      _handleResponse(response);
    } catch (e) {
      print('Update commit goal error: $e');
      throw Exception('Failed to update commit goal: $e');
    }
  }
} 