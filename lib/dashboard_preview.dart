import 'package:flutter/material.dart';
import 'main.dart';

void main() {
  runApp(const DashboardPreviewApp());
}

/// Lightweight preview entrypoint for dashboard iteration.
class DashboardPreviewApp extends StatelessWidget {
  const DashboardPreviewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard Preview',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        fontFamily: 'Plus Jakarta Sans',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Plus Jakarta Sans',
      ),
      themeMode: ThemeMode.dark,
      home: MainHomeScreen(
        selectedLayout: WheelLayoutType.centerWheel,
        isDarkMode: true,
        onToggleTheme: (_) {},
        onChangeLayout: (_) {},
      ),
      onGenerateRoute: (settings) {
        // In preview mode, route taps open a simple placeholder screen.
        return MaterialPageRoute(
          builder: (_) => _PreviewRouteScreen(routeName: settings.name ?? 'unknown'),
          settings: settings,
        );
      },
    );
  }
}

class _PreviewRouteScreen extends StatelessWidget {
  final String routeName;

  const _PreviewRouteScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Route')),
      body: Center(
        child: Text(
          'Tapped route: $routeName',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

