import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:conthabit/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _initialUriIsHandled = false;
  StreamSubscription? _uriLinkSubscription;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
    _handleInitialUri();
  }

  @override
  void dispose() {
    _uriLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleInitialUri() async {
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      try {
        final uri = await getInitialUri();
        if (uri != null) {
          debugPrint('Initial URI received $uri');
          _handleIncomingLink(uri);
        }
      } catch (e) {
        debugPrint('Failed to get initial URI: $e');
      }
    }
  }

  void _handleIncomingLinks() {
    if (!mounted) return;
    
    _uriLinkSubscription = uriLinkStream.listen((Uri? uri) {
      if (!mounted) return;
      debugPrint('URI received $uri');
      if (uri != null) {
        _handleIncomingLink(uri);
      }
    }, onError: (err) {
      debugPrint('Failed to handle incoming links: $err');
    });
  }

  void _handleIncomingLink(Uri uri) async {
    debugPrint('Handling incoming link: $uri');
    if (!mounted) return;

    if (uri.toString().startsWith('https://conthabit-mono.onrender.com/auth/github/callback')) {
      // This is handled by the backend now
      debugPrint('Received GitHub callback, waiting for auth redirect');
    } else if (uri.scheme == 'conthabit' && uri.host == 'auth') {
      final token = uri.queryParameters['token'];
      final error = uri.queryParameters['error'];
      
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: $error'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      if (token != null) {
        try {
          await _apiService.saveAuthToken(token);
          if (mounted) {
            debugPrint('OAuth completed successfully, navigating to dashboard');
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } catch (e) {
          debugPrint('Error saving auth token: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to complete login: ${e.toString()}'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _handleGitHubCallback(String code) async {
    try {
      debugPrint('Processing GitHub callback');
      await _apiService.completeGitHubOAuth(code);
      if (mounted) {
        debugPrint('OAuth completed successfully, navigating to dashboard');
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      debugPrint('Error in GitHub callback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete GitHub login: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleGitHubLogin(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String authUrl = await _apiService.initiateGitHubOAuth();
      debugPrint('Received auth URL: $authUrl');
      
      if (!mounted) return;

      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        final result = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!result) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not launch GitHub login. Please try again.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch GitHub login. Please check your internet connection.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in GitHub login: $e');
      if (mounted) {
        String errorMessage = 'Login failed';
        if (e.toString().contains('Failed to initiate GitHub OAuth')) {
          errorMessage = 'Could not connect to the server. Please make sure the backend is running and properly configured.';
        } else if (e.toString().contains('Invalid response format')) {
          errorMessage = 'Server configuration error. Please check GitHub OAuth setup.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ContHabit',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Track your GitHub commits',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 48.h),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: () => _handleGitHubLogin(context),
                        icon: const Icon(Icons.code),
                        label: const Text('Connect with GitHub'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 