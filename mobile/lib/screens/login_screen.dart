import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:conthabit/services/api_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleGitHubLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/dashboard');
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
                ElevatedButton.icon(
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