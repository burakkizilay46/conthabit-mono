import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:conthabit/models/commit_model.dart';
import 'package:conthabit/models/user_model.dart';
import 'package:conthabit/services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  List<CommitModel>? _commits;
  bool? _hasCommittedToday;
  bool _isLoading = true;
  UserModel? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    debugPrint('Starting to load dashboard data...');
    setState(() => _isLoading = true);
    try {
      debugPrint('Fetching user profile...');
      final userProfile = await _apiService.getUserProfile();
      
      debugPrint('Fetching commits...');
      final commits = await _apiService.getCommits();
      debugPrint('Commits fetched: ${commits.length}');
      
      debugPrint('Checking today\'s commit status...');
      final hasCommittedToday = await _apiService.hasCommittedToday();
      debugPrint('Has committed today: $hasCommittedToday');
      
      setState(() {
        _userProfile = userProfile;
        _commits = commits;
        _hasCommittedToday = hasCommittedToday;
        _isLoading = false;
      });
      debugPrint('Dashboard data loaded successfully');
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_userProfile != null) ...[
              CircleAvatar(
                backgroundImage: NetworkImage(_userProfile!.avatarUrl),
                radius: 20.r,
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _userProfile!.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${_userProfile!.username}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Progress',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildProgressCard(context),
                        SizedBox(height: 24.h),
                        _buildDailyStatusCard(context),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    if (_commits == null) return const SizedBox.shrink();

    final totalCommits = _commits!.length;
    const targetCommits = 1000; // You might want to make this configurable
    final progress = totalCommits / targetCommits;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            SizedBox(
              width: 120.w,
              height: 120.w,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      width: 100.w,
                      height: 100.w,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8.w,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Complete',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Commits',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '$totalCommits',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'out of $targetCommits goal',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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

  Widget _buildDailyStatusCard(BuildContext context) {
    if (_hasCommittedToday == null) return const SizedBox.shrink();

    return Card(
      child: ListTile(
        leading: Icon(
          _hasCommittedToday! ? Icons.check_circle : Icons.warning,
          color: _hasCommittedToday!
              ? Colors.green
              : Theme.of(context).colorScheme.error,
          size: 32.w,
        ),
        title: Text(
          _hasCommittedToday! ? 'You\'ve committed today!' : 'No commits yet today',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _hasCommittedToday!
              ? 'Keep up the good work!'
              : 'Don\'t forget to make a commit today to maintain your streak.',
        ),
      ),
    );
  }
} 