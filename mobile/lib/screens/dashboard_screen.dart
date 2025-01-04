import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:conthabit/models/commit_model.dart';
import 'package:conthabit/models/user_model.dart';
import 'package:conthabit/models/milestone_model.dart';
import 'package:conthabit/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:confetti/confetti.dart';
import 'dart:collection';
import 'dart:math';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  List<CommitModel>? _commits;
  bool? _hasCommittedToday;
  bool _isLoading = false;
  UserModel? _userProfile;
  int _commitGoal = 1000;
  List<MilestoneModel>? _milestones;
  bool _isMilestonesExpanded = true;
  late ConfettiController _confettiController;
  Set<String> _celebratedMilestones = {};

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      setState(() {
        _userProfile = args['userProfile'] as UserModel?;
        _commits = args['commits'] as List<CommitModel>?;
        _hasCommittedToday = args['hasCommittedToday'] as bool?;
        _commitGoal = args['commitGoal'] as int? ?? _commitGoal;
      });
    } else {
      _loadData();
    }
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

      debugPrint('Fetching user settings...');
      final settings = await _apiService.getUserSettings();
      final commitGoal = settings['commitGoal'] as int? ?? 1000;
      debugPrint('Commit goal loaded: $commitGoal');

      debugPrint('Fetching milestones...');
      final milestones = await _apiService.getMilestones();
      debugPrint('Milestones loaded: ${milestones.length}');

      // Check for newly completed milestones
      final newlyCompletedMilestones = milestones.where((milestone) =>
          milestone.status == MilestoneStatus.completed &&
          !_celebratedMilestones.contains(milestone.id));

      if (newlyCompletedMilestones.isNotEmpty) {
        _confettiController.play();
        _celebratedMilestones.addAll(
          newlyCompletedMilestones.map((m) => m.id),
        );
      }

      setState(() {
        _userProfile = userProfile;
        _commits = commits;
        _hasCommittedToday = hasCommittedToday;
        _commitGoal = commitGoal;
        _milestones = milestones;
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

  Map<String, int> _getRepositoryStats() {
    if (_commits == null) return {};
    
    final repoStats = <String, int>{};
    for (var commit in _commits!) {
      repoStats[commit.repository] = (repoStats[commit.repository] ?? 0) + 1;
    }
    
    // Sort by commit count
    final sortedEntries = repoStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(5)); // Top 5 repositories
  }

  List<FlSpot> _getLastTenDaysCommits() {
    if (_commits == null) return [];
    
    final now = DateTime.now();
    final tenDaysAgo = now.subtract(const Duration(days: 10));
    
    // Initialize map with all dates
    final dailyCommits = SplayTreeMap<DateTime, int>();
    for (int i = 0; i < 10; i++) {
      final date = DateTime(
        now.subtract(Duration(days: i)).year,
        now.subtract(Duration(days: i)).month,
        now.subtract(Duration(days: i)).day,
      );
      dailyCommits[date] = 0;
    }
    
    // Count commits for each day
    for (var commit in _commits!) {
      if (commit.timestamp.isAfter(tenDaysAgo)) {
        final date = DateTime(
          commit.timestamp.year,
          commit.timestamp.month,
          commit.timestamp.day,
        );
        dailyCommits[date] = (dailyCommits[date] ?? 0) + 1;
      }
    }
    
    // Convert to FlSpot list
    final spots = <FlSpot>[];
    var index = 0;
    dailyCommits.forEach((date, count) {
      spots.add(FlSpot(index.toDouble(), count.toDouble()));
      index++;
    });
    
    return spots.reversed.toList();
  }

  Widget _buildBestRepositoriesCard(BuildContext context) {
    final repoStats = _getRepositoryStats();
    if (repoStats.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Best Repositories',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ...repoStats.entries.map((entry) {
              final isTopRepo = entry == repoStats.entries.first;
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    if (isTopRepo)
                      Icon(Icons.star, color: Colors.amber, size: 24.w)
                    else
                      SizedBox(width: 24.w),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: isTopRepo ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          LinearProgressIndicator(
                            value: entry.value / repoStats.entries.first.value,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      '${entry.value} commits',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: isTopRepo ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitGraphCard(BuildContext context) {
    final spots = _getLastTenDaysCommits();
    if (spots.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 10 Days Activity',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 200.h,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10.sp,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.now().subtract(
                            Duration(days: 9 - value.toInt()),
                          );
                          return Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesCard(BuildContext context) {
    if (_milestones == null || _milestones!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Milestones & Achievements',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                _isMilestonesExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () {
                setState(() {
                  _isMilestonesExpanded = !_isMilestonesExpanded;
                });
              },
            ),
          ),
          if (_isMilestonesExpanded)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: _milestones!.map((milestone) {
                  final isCompleted = milestone.status == MilestoneStatus.completed;
                  final isLocked = milestone.status == MilestoneStatus.locked;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isLocked ? 0.5 : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            children: [
                              Container(
                                width: 48.w,
                                height: 48.w,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  milestone.icon,
                                  color: isCompleted
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.primary,
                                  size: 24.w,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            milestone.title,
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (isCompleted) ...[
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20.w,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            milestone.unlockedAt != null
                                                ? _formatDate(milestone.unlockedAt!)
                                                : '',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      milestone.description,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.7),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4.r),
                                          child: LinearProgressIndicator(
                                            value: milestone.progress,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            minHeight: 8.h,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${milestone.currentValue}/${milestone.targetValue} ${_getMilestoneUnit(milestone.category)}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        Text(
                                          '${(milestone.progress * 100).toInt()}%',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getMilestoneUnit(MilestoneCategory category) {
    switch (category) {
      case MilestoneCategory.commit:
        return 'commits';
      case MilestoneCategory.streak:
        return 'days';
      case MilestoneCategory.goal:
        return '%';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.pushNamed(context, '/settings')
                    .then((_) => _loadData()),
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
                            SizedBox(height: 24.h),
                            _buildBestRepositoriesCard(context),
                            SizedBox(height: 24.h),
                            _buildCommitGraphCard(context),
                            SizedBox(height: 24.h),
                            _buildMilestonesCard(context),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    if (_commits == null) return const SizedBox.shrink();

    final totalCommits = _commits!.length;
    final progress = totalCommits / _commitGoal;

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
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 8.w,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(progress * 100).toInt().clamp(0, 100)}%',
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
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
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
                    'out of $_commitGoal goal',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
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
          _hasCommittedToday!
              ? 'You\'ve committed today!'
              : 'No commits yet today',
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
