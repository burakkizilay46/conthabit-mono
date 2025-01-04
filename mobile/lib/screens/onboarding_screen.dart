import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Track Your Habits',
      description: 'Create and monitor your daily habits with ease',
      icon: Icons.check_circle_outline,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Set Goals',
      description: 'Define your personal goals and track your progress',
      icon: Icons.flag_rounded,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Earn Milestones',
      description: 'Complete challenges and unlock achievements',
      icon: Icons.military_tech_rounded,
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Stay Motivated',
      description: 'Build streaks and maintain your consistency',
      icon: Icons.local_fire_department_rounded,
      color: Colors.red,
    ),
  ];

  void _onNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: EdgeInsets.only(right: 8.w),
                        height: 8.w,
                        width: 8.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? _pages[index].color
                              : _pages[index].color.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _onNextPage,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160.w,
            height: 160.w,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                page.icon,
                size: 80.w,
                color: page.color,
              ),
            ),
          ),
          SizedBox(height: 40.h),
          Text(
            page.title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
} 