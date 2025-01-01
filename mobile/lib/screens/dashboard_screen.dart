import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:conthabit/models/commit_model.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final commits = await _apiService.getCommits();
      final hasCommittedToday = await _apiService.hasCommittedToday();
      
      setState(() {
        _commits = commits;
        _hasCommittedToday = hasCommittedToday;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  '$totalCommits/$targetCommits commits',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              borderRadius: BorderRadius.circular(4.r),
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