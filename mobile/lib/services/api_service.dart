import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:conthabit/models/commit_model.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:3000/api'; // TODO: Update with actual API URL
  static const _storage = FlutterSecureStorage();

  // Authentication
  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'github_token');
  }

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: 'github_token', value: token);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'github_token');
  }

  // GitHub OAuth
  Future<String> initiateGitHubOAuth() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/github/init'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['authUrl'];
    } else {
      throw Exception('Failed to initiate GitHub OAuth');
    }
  }

  Future<void> completeGitHubOAuth(String code) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/github/callback'),
      body: {'code': code},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveAuthToken(data['token']);
    } else {
      throw Exception('Failed to complete GitHub OAuth');
    }
  }

  // Commit Data
  Future<List<CommitModel>> getCommits() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/commits'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CommitModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load commits');
    }
  }

  Future<bool> hasCommittedToday() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/commits/today'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hasCommitted'] as bool;
    } else {
      throw Exception('Failed to check today\'s commit status');
    }
  }

  // Settings
  Future<void> updateReminderTime(TimeOfDay time) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/settings/reminder'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'hour': time.hour,
        'minute': time.minute,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update reminder time');
    }
  }

  Future<void> updateCommitGoal(int goal) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/settings/goal'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'goal': goal}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update commit goal');
    }
  }
} 