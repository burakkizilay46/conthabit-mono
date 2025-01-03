import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:conthabit/models/commit_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get _baseUrl {
    return 'https://conthabit-mono.onrender.com';
  }

  static const _storage = FlutterSecureStorage();

  // Authentication
  Future<String?> getAuthToken() async {
    final token = await _storage.read(key: 'auth_token');
    return token;
  }

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<String> _getRequiredAuthToken() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('No auth token found. Please log in.');
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

    debugPrint('Error response: ${response.statusCode}, body: ${response.body}');
    if (response.headers['content-type']?.contains('application/json') == true) {
      final errorMessage = jsonDecode(response.body)['message'] ?? 'Unknown error';
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
      
      // Add mobile redirect URI
      final mobileRedirect = Uri.encodeComponent('conthabit://auth/callback');
      final response = await http
          .get(Uri.parse('$_baseUrl/auth/github/init?mobile_redirect=$mobileRedirect'))
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
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/github/callback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('Token exchange response status: ${response.statusCode}');
      
      final data = _handleResponse(response);
      if (!data.containsKey('token')) {
        debugPrint('Response data: $data');
        throw Exception('Invalid response format: Missing token');
      }
      
      final token = data['token'] as String;
      debugPrint('Received token, saving...');
      
      await saveAuthToken(token);
      debugPrint('Auth token saved successfully');
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
          .timeout(const Duration(seconds: 10));
      final data = _handleResponse(response);
      return (data as List).map((json) => CommitModel.fromJson(json)).toList();
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
          .timeout(const Duration(seconds: 10));
      final data = _handleResponse(response);
      return data['hasCommitted'] as bool;
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
}
