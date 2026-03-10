import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'theme/theme_controller.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  if (Platform.isAndroid) {
    // Ask the user to exempt Healio from battery optimisation so scheduled
    // alarms are not killed when the phone is idle / screen is off.
    await _requestBatteryOptimizationExemption();
  }
  runApp(const HealioApp());
}

/// Opens Android's "Ignore battery optimizations" dialog for this app.
/// If the user accepts, alarms will fire reliably even with the screen off.
Future<void> _requestBatteryOptimizationExemption() async {
  const platform = MethodChannel('android_intent');
  try {
    await platform.invokeMethod('requestIgnoreBatteryOptimizations');
  } catch (_) {
    // Channel not implemented on all builds — safe to ignore
  }
}

class HealioApp extends StatefulWidget {
  const HealioApp({super.key});
  @override
  State<HealioApp> createState() => _HealioAppState();
}

class _HealioAppState extends State<HealioApp> {
  late final ThemeController _themeController;
  @override
  void initState() {
    super.initState();
    _themeController = ThemeController();
  }
  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Healio',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeController.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 450),
          themeAnimationCurve: Curves.easeInOutCubic,
          routerConfig: appRouter,
          builder: (context, child) {
            return ThemeControllerProvider(
              controller: _themeController,
              child: child!,
            );
          },
        );
      },
    );
  }
}

class ThemeControllerProvider extends InheritedWidget {
  final ThemeController controller;
  const ThemeControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  });
  static ThemeController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(provider != null, 'No ThemeControllerProvider found in context');
    return provider!.controller;
  }
  @override
  bool updateShouldNotify(ThemeControllerProvider oldWidget) =>
      controller != oldWidget.controller;
}
