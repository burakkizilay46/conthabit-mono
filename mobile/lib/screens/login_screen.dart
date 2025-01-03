import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:conthabit/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _loginAttemptKey = 'login_attempt_timestamp';

  @override
  void initState() {
    super.initState();
    _handleInitialUri();
    _handleIncomingLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialUri();
      _checkPendingLogin();
    });
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

    _uriLinkSubscription?.cancel();
    _uriLinkSubscription = uriLinkStream.listen(
      (Uri? uri) {
        if (!mounted) return;
        debugPrint('URI received in stream: $uri');
        if (uri != null) {
          _handleIncomingLink(uri);
        }
      },
      onError: (err) {
        debugPrint('URI stream error: $err');
        if (mounted) {
          Future.delayed(const Duration(seconds: 1), _handleIncomingLinks);
        }
      },
    );
  }

  void _handleIncomingLink(Uri uri) async {
    debugPrint('Handling incoming link: $uri');
    debugPrint('URI scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}');
    debugPrint('Query parameters: ${uri.queryParameters}');
    
    if (!mounted) return;

    // Handle both HTTPS and custom scheme callbacks
    if ((uri.scheme == 'https' && uri.host == 'conthabit-mono.onrender.com' && uri.path.contains('/auth/github/callback')) ||
        (uri.scheme == 'conthabit' && (uri.host == 'auth' || uri.pathSegments.contains('callback')))) {
      
      debugPrint('Received OAuth callback URL');
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      final token = uri.queryParameters['token'];
      
      if (error != null) {
        debugPrint('Received error in callback: $error');
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
        debugPrint('Received token directly, proceeding to save');
        setState(() {
          _isLoading = true;
        });
        
        try {
          await _apiService.saveAuthToken(token);
          if (mounted) {
            debugPrint('Token saved successfully, navigating to dashboard');
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } catch (e) {
          debugPrint('Error saving token: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to complete login: ${e.toString()}'),
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
        return;
      }

      if (code != null) {
        debugPrint('Received code, exchanging for token');
        setState(() {
          _isLoading = true;
        });
        
        try {
          await _apiService.handleAuthCallback(code);
          if (mounted) {
            debugPrint('OAuth completed successfully, navigating to dashboard');
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } catch (e) {
          debugPrint('Error handling auth callback: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to complete login: ${e.toString()}'),
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
      } else {
        debugPrint('No code or token found in callback URL');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid callback URL: No authorization data found'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _checkInitialUri() async {
    try {
      final uri = await getInitialUri();
      if (uri != null) {
        debugPrint('Initial URI on launch: $uri');
        _handleIncomingLink(uri);
      }
    } catch (e) {
      debugPrint('Error handling initial URI: $e');
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
      
      // Store login state before launching URL
      await _persistLoginAttempt();
      
      try {
        final result = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        
        if (!result) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not launch GitHub login. Please try again.'),
                duration: Duration(seconds: 4),
              ),
            );
            // Clear login attempt if URL launch fails
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_loginAttemptKey);
          }
        }
      } catch (urlError) {
        debugPrint('Error launching URL: $urlError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch GitHub login. Please check your internet connection.'),
              duration: Duration(seconds: 4),
            ),
          );
          // Clear login attempt if URL launch throws
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_loginAttemptKey);
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

  Future<void> _persistLoginAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loginAttemptKey, DateTime.now().millisecondsSinceEpoch);
    debugPrint('Login attempt persisted');
  }

  Future<void> _checkPendingLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_loginAttemptKey);
    if (timestamp != null) {
      // Clear the timestamp immediately
      await prefs.remove(_loginAttemptKey);
      
      // If there was a pending login and the app was restarted
      debugPrint('Found pending login from previous session');
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