import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import '../models/settings.dart';
import '../services/schedule_service.dart';

class StorageService {
  static const String _settingsKey = 'app_settings';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  bool _widgetInitialized = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Mark widget as initialized (home_widget doesn't have init method)
    _widgetInitialized = true;
  }

  Future<void> saveSettings(AppSettings settings) async {
    // Save to SharedPreferences first (fast, always works)
    await _prefs?.setString(_settingsKey, jsonEncode(settings.toJson()));
    
    // Update widget in background, don't await
    _updateWidgetDataAsync(settings);
  }

  Future<AppSettings> loadSettings() async {
    final settingsString = _prefs?.getString(_settingsKey);
    if (settingsString != null && settingsString.isNotEmpty) {
      try {
        final map = jsonDecode(settingsString) as Map<String, dynamic>;
        return AppSettings.fromJson(map);
      } catch (e) {
        return AppSettings.defaultSettings();
      }
    }
    return AppSettings.defaultSettings();
  }

  void _updateWidgetDataAsync(AppSettings settings) {
    // Fire and forget - don't block the UI
    Future.microtask(() async {
      try {
        await _updateWidgetData(settings);
      } catch (e) {
        // Widget update failed, but that's non-critical
      }
    });
  }

  Future<void> _updateWidgetData(AppSettings settings) async {
    if (!_widgetInitialized) return;

    final now = DateTime.now();
    final scheduleInfo = ScheduleService.calculateCurrentPeriod(settings, now);
    final remainingSeconds = scheduleInfo.remainingSeconds;

    String periodType;
    if (scheduleInfo.isBigBreak) {
      periodType = scheduleInfo.currentBigBreak?.name ?? 'большая перемена';
    } else if (scheduleInfo.isBreak) {
      periodType = 'перемена';
    } else if (scheduleInfo.currentLessonNumber == 0) {
      periodType = 'до занятий';
    } else {
      periodType = 'урок ${scheduleInfo.currentLessonNumber}';
    }

    await HomeWidget.saveWidgetData<String>('remaining_text', _formatRemaining(remainingSeconds));
    await HomeWidget.saveWidgetData<String>('period_type', periodType);
    await HomeWidget.saveWidgetData<int>('remaining_seconds', remainingSeconds);
    await HomeWidget.saveWidgetData<String>('last_update', now.toIso8601String());

    // Request widget update with timeout
    try {
      await HomeWidget.updateWidget(
        name: 'DoZvonkaWidget',
        iOSName: 'DoZvonkaWidget',
        androidName: 'DoZvonkaWidget',
      ).timeout(const Duration(seconds: 3));
    } on TimeoutException {
      // Widget update timed out, non-critical
    }
  }

  String _formatRemaining(int seconds) {
    if (seconds <= 0) return '00:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> updateWidgetNow(AppSettings settings) async {
    await _updateWidgetData(settings);
  }
}