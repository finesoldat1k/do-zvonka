import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'services/storage_service.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  await StorageService().init();

  // Register background callback for widget updates
  try {
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  } catch (_) {
    // Expected on non-Android platforms
  }

  runApp(const DoZvonkaApp());
}

// Background callback for widget updates
Future<void> backgroundCallback(Uri? uri) async {
  try {
    await StorageService().init();
    final settings = await StorageService().loadSettings();
    await StorageService().updateWidgetNow(settings);
  } catch (_) {
    // Non-critical failure
  }
}

class DoZvonkaApp extends StatelessWidget {
  const DoZvonkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'до звонка',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const InitialScreen(),
      routes: {
        '/main': (context) => const MainScreen(),
        '/settings': (context) => const SettingsScreen(isFirstLaunch: false),
      },
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    final settings = await StorageService().loadSettings();
    if (mounted) {
      if (settings.isConfigured) {
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(isFirstLaunch: true),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              'до звонка',
              style: AppTheme.unboundedStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'загрузка...',
              style: AppTheme.onestStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}