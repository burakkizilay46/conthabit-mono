import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0); // Default 8 PM
  final NotificationService _notificationService = NotificationService();
  late ApiService _apiService;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiService>(context, listen: false);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      developer.log('Checking notification permissions...');
      // Check notification permissions
      _hasPermissions = await _notificationService.checkPermissions();
      developer.log('Notification permissions status: $_hasPermissions');

      developer.log('Fetching notification settings from server...');
      // Get settings from the server
      final settings = await _apiService.getNotificationSettings();
      developer.log('Received settings from server: $settings');
      
      // Update FCM token if we have permissions
      if (_hasPermissions) {
        developer.log('Updating FCM token...');
        final fcmToken = await _notificationService.getFCMToken();
        if (fcmToken != null) {
          developer.log('FCM token obtained, updating on server...');
          await _apiService.updateFCMToken(fcmToken);
          developer.log('FCM token updated successfully');
        } else {
          developer.log('Warning: FCM token is null');
        }
      }

      setState(() {
        _notificationsEnabled = settings['enabled'] ?? true;
        final reminderTime = settings['reminderTime'] ?? '20:00';
        final parts = reminderTime.split(':');
        _reminderTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        _isLoading = false;
      });

      // Schedule local notification if enabled and we have permissions
      if (_notificationsEnabled && _hasPermissions) {
        developer.log('Scheduling daily reminder...');
        await _notificationService.scheduleDailyReminder(_reminderTime);
        developer.log('Daily reminder scheduled successfully');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error loading notification settings',
        error: e,
        stackTrace: stackTrace,
      );
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load notification settings: ${e.toString()}';
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      setState(() => _errorMessage = null);
      
      final granted = await _notificationService.requestPermissions();
      setState(() => _hasPermissions = granted);
      
      if (granted) {
        // Reload settings to enable notifications if previously enabled
        await _loadSettings();
      } else {
        setState(() {
          _errorMessage = 'Please enable notifications in your device settings to receive reminders.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to request notification permissions. Please try again.';
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      setState(() => _errorMessage = null);

      if (_notificationsEnabled && !_hasPermissions) {
        await _requestPermissions();
        if (!_hasPermissions) {
          return;
        }
      }

      // Format time as HH:mm
      final timeString = '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';
      
      // Update server settings
      await _apiService.updateNotificationSettings(
        enabled: _notificationsEnabled,
        reminderTime: timeString,
      );

      // Schedule or cancel local notification
      if (_notificationsEnabled && _hasPermissions) {
        await _notificationService.scheduleDailyReminder(_reminderTime);
      } else {
        await _notificationService.cancelAllNotifications();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save notification settings. Please try again.';
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      await _saveSettings();
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _debugGetFCMToken() async {
    try {
      final fcmToken = await _notificationService.getFCMToken();
      if (fcmToken != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('FCM Token: $fcmToken'),
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () {
                  // Add clipboard functionality if needed
                },
              ),
            ),
          );
        }
        developer.log('FCM Token: $fcmToken');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get FCM token'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting FCM token: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _debugGetFCMToken,
            tooltip: 'Show FCM Token',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (!_hasPermissions)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notifications Disabled',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enable notifications to receive daily reminders about your habits.',
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _requestPermissions,
                            child: const Text('Enable Notifications'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_hasPermissions) ...[
                  SwitchListTile(
                    title: const Text('Enable Daily Reminders'),
                    value: _notificationsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                  if (_notificationsEnabled)
                    ListTile(
                      title: const Text('Reminder Time'),
                      subtitle: Text(_reminderTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: _selectTime,
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _sendTestNotification,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Send Test Notification'),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Choose when you want to receive your daily reminder. We recommend setting it for a time when you\'re usually free to check your habits.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 