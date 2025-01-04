import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:conthabit/models/commit_model.dart';
import 'package:conthabit/models/user_model.dart';
import 'package:conthabit/services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('Starting to load initial data...');
      
      // Load user profile
      debugPrint('Fetching user profile...');
      final userProfile = await _apiService.getUserProfile();
      
      // Load commits
      debugPrint('Fetching commits...');
      final commits = await _apiService.getCommits();
      debugPrint('Commits fetched: ${commits.length}');
      
      // Check today's commit status
      debugPrint('Checking today\'s commit status...');
      final hasCommittedToday = await _apiService.hasCommittedToday();
      debugPrint('Has committed today: $hasCommittedToday');

      // Load user settings
      debugPrint('Fetching user settings...');
      final userSettings = await _apiService.getUserSettings();
      final commitGoal = userSettings['commitGoal'] as int? ?? 1000;

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: {
            'userProfile': userProfile,
            'commits': commits,
            'hasCommittedToday': hasCommittedToday,
            'commitGoal': commitGoal,
          },
        );
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
        // Navigate to dashboard even if there's an error
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ContHabit',
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: 150.w,
              height: 150.w,
              child: Lottie.asset(
                'assets/animations/loading.json',
                controller: _animationController,
                onLoaded: (composition) {
                  _animationController
                    ..duration = composition.duration
                    ..repeat();
                },
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading your progress...',
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 