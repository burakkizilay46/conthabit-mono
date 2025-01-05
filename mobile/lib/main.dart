import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:conthabit/theme/app_theme.dart';
import 'package:conthabit/theme/theme_provider.dart';
import 'package:conthabit/screens/login_screen.dart';
import 'package:conthabit/screens/dashboard_screen.dart';
import 'package:conthabit/screens/settings_screen.dart';
import 'package:conthabit/screens/splash_screen.dart';
import 'package:conthabit/screens/onboarding_screen.dart';
import 'package:conthabit/screens/notification_settings_screen.dart';
import 'package:conthabit/services/api_service.dart';
import 'package:conthabit/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with proper options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize API service and check authentication state
  final apiService = ApiService();
  final hasToken = await apiService.getAuthToken() != null;
  
  // Check if onboarding is completed
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;

  String initialRoute = '/onboarding';
  if (hasCompletedOnboarding) {
    initialRoute = hasToken ? '/splash' : '/login';
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider.value(value: apiService),
        Provider.value(value: notificationService),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'ContHabit',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              initialRoute: initialRoute,
              routes: {
                '/login': (context) => const LoginScreen(),
                '/splash': (context) => const SplashScreen(),
                '/dashboard': (context) => const DashboardScreen(),
                '/settings': (context) => const SettingsScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
                '/notification_settings': (context) => const NotificationSettingsScreen(),
              },
            );
          },
        );
      },
    );
  }
}
