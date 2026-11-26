import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/settings.dart';
import '../../models/schedule_info.dart';
import '../../models/period_preview.dart';
import '../../models/big_break.dart';
import '../../services/storage_service.dart';
import '../../services/schedule_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/timer_display.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  AppSettings _settings = AppSettings.defaultSettings();
  ScheduleInfo _scheduleInfo = ScheduleInfo.afterSchool(
    currentLessonNumber: 0,
    periodEndTime: DateTime.now(),
  );
  List<PeriodPreview> _nextPeriods = [];
  Timer? _timer;
  DateTime _lastUpdate = DateTime.now();
  bool _isLoading = true;
  String? _loadError;
  int _loadAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateSchedule();
      _updateWidget();
    }
  }

  Future<void> _loadSettings() async {
    _loadAttempts++;
    try {
      final settings = await StorageService().loadSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
          _loadError = null;
        });
        
        if (!settings.isConfigured && _loadAttempts == 1) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            final retrySettings = await StorageService().loadSettings();
            setState(() => _settings = retrySettings);
          }
        }
        
        _updateSchedule();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Ошибка загрузки: $e';
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isLoading) _updateSchedule();
    });
  }

  void _updateSchedule() {
    if (!_settings.isConfigured) return;
    
    final now = DateTime.now();
    final newInfo = ScheduleService.calculateCurrentPeriod(_settings, now);
    final newNextPeriods = ScheduleService.getNextPeriods(_settings, now, 4);
    
    if (mounted) {
      setState(() {
        _scheduleInfo = newInfo;
        _nextPeriods = newNextPeriods;
        _lastUpdate = now;
      });
    }

    if (now.difference(_lastUpdate).inSeconds >= 30) {
      _updateWidget();
    }
  }

  Future<void> _updateWidget() async {
    await StorageService().updateWidgetNow(_settings);
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<AppSettings>(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(initialSettings: _settings),
      ),
    );
    if (result != null && mounted) {
      setState(() => _settings = result);
      _updateSchedule();
      _updateWidget();
    }
  }

  void _forceOpenSettings() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(initialSettings: _settings, isFirstLaunch: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('до звонка', style: AppTheme.unboundedStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppTheme.surfaceColor,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined, color: AppTheme.textPrimary),
          onPressed: _openSettings,
          tooltip: 'настройки',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_loadError != null) {
      return _buildErrorScreen();
    }

    if (!_settings.isConfigured) {
      return _buildNotConfiguredScreen();
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _updateSchedule(),
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.surfaceColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              TimerDisplay(
                scheduleInfo: _scheduleInfo,
                settings: _settings,
                lastUpdate: _lastUpdate,
              ),
              const SizedBox(height: 16),
              _buildCurrentStatusCard(),
              const SizedBox(height: 16),
              _buildScheduleInfoCard(),
              const SizedBox(height: 16),
              _buildNextPeriodsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.schedule_outlined, size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'загрузка расписания...',
            style: AppTheme.onestStyle(fontSize: 15, color: AppTheme.textSecondary),
          ),
          if (_loadAttempts > 1) ...[
            const SizedBox(height: 12),
            Text(
              'попытка $_loadAttempts',
              style: AppTheme.onestStyle(fontSize: 12, color: AppTheme.textDisabled),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 60, color: AppTheme.errorColor),
            const SizedBox(height: 20),
            Text(
              'ошибка загрузки',
              style: AppTheme.unboundedStyle(fontSize: 22, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _loadError!,
              style: AppTheme.onestStyle(fontSize: 15, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSettings,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('повторить'),
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(200, 52),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _forceOpenSettings,
              child: Text('настроить заново', style: AppTheme.onestStyle(fontSize: 14, color: AppTheme.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotConfiguredScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.schedule_outlined, size: 50, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 28),
            Text(
              'расписание не настроено',
              style: AppTheme.unboundedStyle(fontSize: 24, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'нажмите кнопку ниже, чтобы настроить время начала занятий, длительность уроков и перемен',
              style: AppTheme.onestStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: _forceOpenSettings,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('настроить расписание'),
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(280, 56),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: AppTheme.onestStyle(fontSize: 16, fontWeight: FontWeight.w600),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    if (!_settings.isConfigured) return const SizedBox.shrink();

    final now = DateTime.now();
    final startMinutes = _settings.startTime.hour * 60 + _settings.startTime.minute;
    final currentMinutes = now.hour * 60 + now.minute;
    final minutesSinceStart = currentMinutes - startMinutes;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (minutesSinceStart < 0) {
      statusText = 'до начала занятий';
      statusColor = AppTheme.primaryColor;
      statusIcon = Icons.schedule_outlined;
    } else if (_scheduleInfo.remainingSeconds <= 0 && _scheduleInfo.currentLessonNumber >= _settings.lessonsPerDay) {
      statusText = 'занятия окончены';
      statusColor = AppTheme.textSecondary;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (_scheduleInfo.isBigBreak) {
      statusText = _scheduleInfo.currentBigBreak?.name ?? 'большая перемена';
      statusColor = AppTheme.bigBreakColor;
      statusIcon = Icons.restaurant_rounded;
    } else if (_scheduleInfo.isBreak) {
      statusText = 'перемена ${_scheduleInfo.currentLessonNumber}';
      statusColor = AppTheme.accentColor;
      statusIcon = Icons.coffee_outlined;
    } else {
      statusText = 'урок ${_scheduleInfo.currentLessonNumber} из ${_settings.lessonsPerDay}';
      statusColor = AppTheme.lessonColor;
      statusIcon = Icons.menu_book_outlined;
    }

    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: AppTheme.onestStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildUpdateTime(),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _buildStatItem(
                  'начало',
                  ScheduleService.formatTime(_settings.startTime),
                  Icons.access_time_rounded,
                  AppTheme.primaryColor,
                ),
                _buildStatItem(
                  'урок',
                  '${_settings.lessonDurationMinutes} мин',
                  Icons.schedule_rounded,
                  AppTheme.lessonColor,
                ),
                _buildStatItem(
                  'перемена',
                  '${_settings.breakDurationMinutes} мин',
                  Icons.coffee_outlined,
                  AppTheme.accentColor,
                ),
                if (_settings.bigBreaks.isNotEmpty)
                  _buildStatItem(
                    'бол. перемен',
                    '${_settings.bigBreaks.length}',
                    Icons.restaurant_menu_rounded,
                    AppTheme.bigBreakColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateTime() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.update_rounded, size: 12, color: AppTheme.textDisabled),
          const SizedBox(width: 4),
          Text(
            ScheduleService.formatTime(TimeOfDay.fromDateTime(_lastUpdate)),
            style: AppTheme.onestStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.unboundedStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.onestStyle(fontSize: 11, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfoCard() {
    if (!_settings.isConfigured) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'текущий день',
                  style: AppTheme.unboundedStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimelineView(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView() {
    final timeline = ScheduleService.getFullTimeline(_settings);
    if (timeline.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final startMinutes = _settings.startTime.hour * 60 + _settings.startTime.minute;
    final currentMinutes = now.hour * 60 + now.minute;
    final minutesSinceStart = currentMinutes - startMinutes;

    return Column(
      children: timeline.asMap().entries.map((entry) {
        final index = entry.key;
        final period = entry.value;
        final isLast = index == timeline.length - 1;

        bool isCurrent = false;
        bool isPast = false;
        
        if (minutesSinceStart >= 0) {
          final periodStart = period['startMinutes'] as int;
          final periodEnd = period['endMinutes'] as int;
          isCurrent = minutesSinceStart >= periodStart && minutesSinceStart < periodEnd;
          isPast = minutesSinceStart >= periodEnd;
        }

        return _TimelineItem(
          period: period,
          isCurrent: isCurrent,
          isPast: isPast,
          isLast: isLast,
          startMinutes: startMinutes,
        );
      }).toList(),
    );
  }

  Widget _buildNextPeriodsCard() {
    if (!_settings.isConfigured || _nextPeriods.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.upcoming_rounded, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'следующие звонки',
                  style: AppTheme.unboundedStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Column(
            children: _nextPeriods.asMap().entries.map((entry) {
              final index = entry.key;
              final period = entry.value;
              final isLast = index == _nextPeriods.length - 1;
              final isCurrent = index == 0;

              return _NextPeriodTile(
                period: period,
                settings: _settings,
                isCurrent: isCurrent,
                isLast: isLast,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> period;
  final bool isCurrent;
  final bool isPast;
  final bool isLast;
  final int startMinutes;

  const _TimelineItem({
    required this.period,
    required this.isCurrent,
    required this.isPast,
    required this.isLast,
    required this.startMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final type = period['type'] as String;
    final lessonNum = period['lessonNumber'] as int;
    final periodStart = period['startMinutes'] as int;
    final periodEnd = period['endMinutes'] as int;
    final bigBreak = period['bigBreak'] as BigBreak?;

    Color itemColor;
    IconData itemIcon;
    String title;
    String subtitle;

    if (type == 'lesson') {
      itemColor = AppTheme.lessonColor;
      itemIcon = Icons.menu_book_outlined;
      title = 'урок $lessonNum';
      subtitle = '${periodEnd - periodStart} мин';
    } else if (type == 'bigBreak') {
      itemColor = AppTheme.bigBreakColor;
      itemIcon = Icons.restaurant_rounded;
      title = bigBreak?.name ?? 'большая перемена';
      subtitle = 'после $lessonNum урока · ${bigBreak?.durationMinutes ?? 0} мин';
    } else {
      itemColor = AppTheme.accentColor;
      itemIcon = Icons.coffee_outlined;
      title = 'перемена $lessonNum';
      subtitle = '${periodEnd - periodStart} мин';
    }

    final startTime = _formatMinutes(startMinutes + periodStart);
    final endTime = _formatMinutes(startMinutes + periodEnd);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isCurrent ? itemColor : (isPast ? AppTheme.textDisabled : AppTheme.dividerColor),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? itemColor : AppTheme.dividerColor,
                  width: isCurrent ? 3 : 1,
                ),
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 2,
                  color: isPast ? AppTheme.textDisabled.withValues(alpha: 0.5) : AppTheme.dividerColor,
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isCurrent ? itemColor.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isCurrent ? Border.all(color: itemColor.withValues(alpha: 0.3)) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(itemIcon, color: itemColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: AppTheme.onestStyle(
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                              color: isCurrent ? itemColor : AppTheme.textPrimary,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: itemColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'сейчас',
                                style: AppTheme.onestStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: itemColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTheme.onestStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      startTime,
                      style: AppTheme.unboundedStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      endTime,
                      style: AppTheme.onestStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    final hours = (minutes ~/ 60).toString().padLeft(2, '0');
    final mins = (minutes % 60).toString().padLeft(2, '0');
    return '$hours:$mins';
  }
}

class _NextPeriodTile extends StatelessWidget {
  final PeriodPreview period;
  final AppSettings settings;
  final bool isCurrent;
  final bool isLast;

  const _NextPeriodTile({
    required this.period,
    required this.settings,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? _getPeriodColor().withValues(alpha: 0.06) : Colors.transparent,
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getPeriodColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getPeriodIcon(), color: _getPeriodColor(), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getPeriodTitle(),
                      style: AppTheme.onestStyle(
                        fontSize: 15,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                        color: isCurrent ? _getPeriodColor() : AppTheme.textPrimary,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _getPeriodColor().withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'текущий',
                          style: AppTheme.onestStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _getPeriodColor(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getPeriodSubtitle(),
                  style: AppTheme.onestStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ScheduleService.formatTime(TimeOfDay.fromDateTime(period.endTime)),
                style: AppTheme.unboundedStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
              ),
              if (isCurrent && period.bigBreak != null)
                Text(
                  '${period.bigBreak!.durationMinutes} мин',
                  style: AppTheme.onestStyle(fontSize: 11, color: AppTheme.bigBreakColor, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPeriodColor() {
    if (period.isBigBreak) return AppTheme.bigBreakColor;
    if (period.isBreak) return AppTheme.accentColor;
    return AppTheme.lessonColor;
  }

  IconData _getPeriodIcon() {
    if (period.isBigBreak) return Icons.restaurant_rounded;
    if (period.isBreak) return Icons.coffee_outlined;
    return Icons.menu_book_outlined;
  }

  String _getPeriodTitle() {
    if (period.isBigBreak && period.bigBreak != null) {
      return period.bigBreak!.name ?? 'большая перемена';
    }
    if (period.isBreak) {
      return 'перемена ${period.lessonNumber}';
    }
    return 'урок ${period.lessonNumber}';
  }

  String _getPeriodSubtitle() {
    if (period.isBigBreak && period.bigBreak != null) {
      return 'после ${period.bigBreak!.afterLesson} урока · ${period.bigBreak!.durationMinutes} мин';
    }
    if (period.isBreak) {
      return '${settings.breakDurationMinutes} мин';
    }
    return '${settings.lessonDurationMinutes} мин';
  }
}