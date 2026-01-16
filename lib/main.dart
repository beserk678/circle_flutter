import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/services/auth_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/error_service.dart';
import 'core/services/app_lifecycle_service.dart';
import 'core/services/scaling_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/security_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/backup_service.dart';
import 'core/services/monitoring_service.dart';
import 'auth/auth_controller.dart';
import 'auth/auth_screen.dart';
import 'circles/circle_controller.dart';
import 'circles/circle_home/circle_home_screen.dart';
import 'circles/circle_selection_screen.dart';
import 'feed/feed_controller.dart';
import 'chat/chat_controller.dart';
import 'tasks/task_controller.dart';
import 'files/file_controller.dart';
import 'notifications/notification_controller.dart';
import 'notifications/notification_service.dart';
import 'profile/profile_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Stage 9 services
  ErrorService.instance.initialize();
  await NotificationService.instance.initialize();
  await AnalyticsService.instance.logAppOpen();

  // Initialize Stage 10 services
  ScalingService.instance.initialize();
  await CacheService.instance.initialize();
  SecurityService.instance.initialize();
  SyncService.instance.initialize();
  BackupService.instance.initialize();
  MonitoringService.instance.initialize();

  runApp(const CircleApp());
}

class CircleApp extends StatelessWidget {
  const CircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CircleController()),
        ChangeNotifierProvider(create: (_) => FeedController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => TaskController()),
        ChangeNotifierProvider(create: (_) => FileController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'Circle',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            home: AppLifecycleWrapper(child: const AuthWrapper()),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes (but not AuthController changes)
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Initialize circles when user is authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<CircleController>().initializeCircles();
            context.read<NotificationController>().initializeNotifications();
            context.read<ProfileController>().initializeProfile();
          });

          return Consumer<CircleController>(
            builder: (context, circleController, child) {
              // Show loading while circles are being initialized
              if (circleController.isLoading &&
                  circleController.userCircles.isEmpty) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // If user has no circles or no selected circle, show selection screen
              if (circleController.userCircles.isEmpty ||
                  circleController.selectedCircle == null) {
                return const CircleSelectionScreen();
              }

              return const CircleHomeScreen();
            },
          );
        }

        return const AuthScreen();
      },
    );
  }
}
