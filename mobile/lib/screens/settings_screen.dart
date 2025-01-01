import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:conthabit/theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  int _commitGoal = 1000;

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      // TODO: Save reminder time
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildSection(
            title: 'Appearance',
            children: [
              _buildThemeSelector(),
            ],
          ),
          SizedBox(height: 24.h),
          _buildSection(
            title: 'Reminders',
            children: [
              _buildReminderTimeSetting(),
            ],
          ),
          SizedBox(height: 24.h),
          _buildSection(
            title: 'Goals',
            children: [
              _buildCommitGoalSetting(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ListTile(
          title: const Text('Theme'),
          subtitle: Text(
            themeProvider.themeMode == ThemeMode.system
                ? 'System'
                : themeProvider.themeMode == ThemeMode.light
                    ? 'Light'
                    : 'Dark',
          ),
          trailing: DropdownButton<ThemeMode>(
            value: themeProvider.themeMode,
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                themeProvider.setThemeMode(newMode);
              }
            },
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReminderTimeSetting() {
    return ListTile(
      title: const Text('Daily Reminder'),
      subtitle: Text(_reminderTime.format(context)),
      trailing: TextButton(
        onPressed: _selectReminderTime,
        child: const Text('Change'),
      ),
    );
  }

  Widget _buildCommitGoalSetting() {
    return ListTile(
      title: const Text('Commit Goal'),
      subtitle: Text('$_commitGoal commits'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          // TODO: Implement commit goal editing
        },
      ),
    );
  }
} 