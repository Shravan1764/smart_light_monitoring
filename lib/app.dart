import 'package:flutter/material.dart';
import 'package:smart_light_monitoring/screens/dashboard_screen.dart';
import 'package:smart_light_monitoring/theme/app_theme.dart';

/// Root MaterialApp widget for the Smart Light Monitor.
class SmartMonitorApp extends StatelessWidget {
  const SmartMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Light Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
