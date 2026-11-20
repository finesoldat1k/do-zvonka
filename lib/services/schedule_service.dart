import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../models/schedule_info.dart';
import '../models/big_break.dart';
import '../models/period_preview.dart';

class ScheduleService {
  static ScheduleInfo calculateCurrentPeriod(AppSettings settings, DateTime now) {
    if (!settings.isConfigured) {
      return ScheduleInfo.afterSchool(
        currentLessonNumber: 0,
        periodEndTime: now,
      );
    }

    final startMinutes = settings.startTime.hour * 60 + settings.startTime.minute;
    final currentMinutes = now.hour * 60 + now.minute;
    final minutesSinceStart = currentMinutes - startMinutes;

    if (minutesSinceStart < 0) {
      // Before school starts
      final secondsUntilStart = (-minutesSinceStart) * 60;
      return ScheduleInfo.beforeSchool(
        remainingSeconds: secondsUntilStart,
        periodEndTime: DateTime(now.year, now.month, now.day, settings.startTime.hour, settings.startTime.minute),
      );
    }

    // Build timeline with all periods
    final timeline = _buildTimeline(settings);
    
    // Find current period
    for (int i = 0; i < timeline.length; i++) {
      final period = timeline[i];
      final periodStart = period['startMinutes'] as int;
      final periodEnd = period['endMinutes'] as int;
      
      if (minutesSinceStart >= periodStart && minutesSinceStart < periodEnd) {
        final remainingMinutes = periodEnd - minutesSinceStart;
        
        if (period['type'] == 'lesson') {
          return ScheduleInfo.lesson(
            remainingSeconds: remainingMinutes * 60,
            currentLessonNumber: period['lessonNumber'] as int,
            periodEndTime: DateTime(now.year, now.month, now.day, 0, 0).add(Duration(minutes: startMinutes + periodEnd)),
          );
        } else if (period['type'] == 'bigBreak') {
          final bigBreak = period['bigBreak'] as BigBreak;
          return ScheduleInfo.bigBreak(
            bigBreak: bigBreak,
            remainingSeconds: remainingMinutes * 60,
            currentLessonNumber: bigBreak.afterLesson,
            periodEndTime: DateTime(now.year, now.month, now.day, 0, 0).add(Duration(minutes: startMinutes + periodEnd)),
          );
        } else {
          // Regular break
          return ScheduleInfo.breakTime(
            remainingSeconds: remainingMinutes * 60,
            currentLessonNumber: period['lessonNumber'] as int,
            periodEndTime: DateTime(now.year, now.month, now.day, 0, 0).add(Duration(minutes: startMinutes + periodEnd)),
          );
        }
      }
    }

    // After all periods
    final lastPeriod = timeline.last;
    return ScheduleInfo.afterSchool(
      currentLessonNumber: settings.lessonsPerDay,
      periodEndTime: DateTime(now.year, now.month, now.day, 0, 0).add(Duration(minutes: startMinutes + (lastPeriod['endMinutes'] as int))),
    );
  }

  static List<Map<String, dynamic>> _buildTimeline(AppSettings settings) {
    final timeline = <Map<String, dynamic>>[];
    final lessonDuration = settings.lessonDurationMinutes;
    final breakDuration = settings.breakDurationMinutes;
    
    int currentMinute = 0;
    
    for (int lesson = 1; lesson <= settings.lessonsPerDay; lesson++) {
      // Add lesson
      timeline.add({
        'type': 'lesson',
        'lessonNumber': lesson,
        'startMinutes': currentMinute,
        'endMinutes': currentMinute + lessonDuration,
      });
      currentMinute += lessonDuration;
      
      // Check for big break after this lesson
      final bigBreak = settings.getBigBreakAfterLesson(lesson);
      if (bigBreak != null) {
        timeline.add({
          'type': 'bigBreak',
          'lessonNumber': lesson,
          'bigBreak': bigBreak,
          'startMinutes': currentMinute,
          'endMinutes': currentMinute + bigBreak.durationMinutes,
        });
        currentMinute += bigBreak.durationMinutes;
      } else if (lesson < settings.lessonsPerDay) {
        // Regular break (only if not the last lesson and no big break)
        timeline.add({
          'type': 'break',
          'lessonNumber': lesson,
          'startMinutes': currentMinute,
          'endMinutes': currentMinute + breakDuration,
        });
        currentMinute += breakDuration;
      }
    }
    
    return timeline;
  }

  static List<Map<String, dynamic>> getFullTimeline(AppSettings settings) {
    return _buildTimeline(settings);
  }

  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes мин';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '$hours ч $mins мин' : '$hours ч';
    }
  }

  // Get all periods for display (next N periods)
  static List<PeriodPreview> getNextPeriods(AppSettings settings, DateTime now, int count) {
    final periods = <PeriodPreview>[];
    final timeline = _buildTimeline(settings);
    final startMinutes = settings.startTime.hour * 60 + settings.startTime.minute;
    final currentMinutes = now.hour * 60 + now.minute;
    final minutesSinceStart = currentMinutes - startMinutes;

    if (minutesSinceStart < 0) {
      // Before school - first lesson
      final firstLesson = timeline.firstWhere((p) => p['type'] == 'lesson');
      periods.add(PeriodPreview.lesson(
        lessonNumber: firstLesson['lessonNumber'] as int,
        endTime: DateTime(now.year, now.month, now.day, settings.startTime.hour, settings.startTime.minute).add(Duration(minutes: firstLesson['endMinutes'] as int)),
      ));
    } else {
      // Find current position in timeline
      int currentIndex = -1;
      for (int i = 0; i < timeline.length; i++) {
        final period = timeline[i];
        final periodStart = period['startMinutes'] as int;
        final periodEnd = period['endMinutes'] as int;
        
        if (minutesSinceStart >= periodStart && minutesSinceStart < periodEnd) {
          currentIndex = i;
          break;
        }
      }

      // Add current period if found
      if (currentIndex >= 0) {
        final currentPeriod = timeline[currentIndex];
        periods.add(_createPeriodPreview(currentPeriod, now, startMinutes, settings));
      }

      // Add next periods
      for (int i = (currentIndex >= 0 ? currentIndex + 1 : 0); 
           i < timeline.length && periods.length < count; 
           i++) {
        periods.add(_createPeriodPreview(timeline[i], now, startMinutes, settings));
      }
    }

    return periods.take(count).toList();
  }

  static PeriodPreview _createPeriodPreview(
    Map<String, dynamic> period, 
    DateTime now, 
    int startMinutes,
    AppSettings settings,
  ) {
    final endMinutes = period['endMinutes'] as int;
    final endTime = DateTime(now.year, now.month, now.day, 0, 0).add(Duration(minutes: startMinutes + endMinutes));
    
    if (period['type'] == 'lesson') {
      return PeriodPreview.lesson(
        lessonNumber: period['lessonNumber'] as int,
        endTime: endTime,
      );
    } else if (period['type'] == 'bigBreak') {
      return PeriodPreview.bigBreak(
        lessonNumber: period['lessonNumber'] as int,
        bigBreak: period['bigBreak'] as BigBreak,
        endTime: endTime,
      );
    } else {
      return PeriodPreview.breakTime(
        lessonNumber: period['lessonNumber'] as int,
        endTime: endTime,
      );
    }
  }
}