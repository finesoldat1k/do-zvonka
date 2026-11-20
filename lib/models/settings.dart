import 'package:flutter/material.dart';
import 'big_break.dart';

class AppSettings {
  final TimeOfDay startTime;
  final int lessonDurationMinutes;
  final int breakDurationMinutes;
  final int lessonsPerDay;
  final List<BigBreak> bigBreaks;
  final bool isConfigured;

  AppSettings({
    required this.startTime,
    required this.lessonDurationMinutes,
    required this.breakDurationMinutes,
    required this.lessonsPerDay,
    this.bigBreaks = const [],
    this.isConfigured = true,
  });

  factory AppSettings.defaultSettings() {
    return AppSettings(
      startTime: const TimeOfDay(hour: 8, minute: 30),
      lessonDurationMinutes: 45,
      breakDurationMinutes: 10,
      lessonsPerDay: 6,
      bigBreaks: [],
      isConfigured: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'lessonDurationMinutes': lessonDurationMinutes,
      'breakDurationMinutes': breakDurationMinutes,
      'lessonsPerDay': lessonsPerDay,
      'bigBreaks': bigBreaks.map((b) => b.toJson()).toList(),
      'isConfigured': isConfigured,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final bigBreaksList = <BigBreak>[];
    if (json['bigBreaks'] != null) {
      for (final item in json['bigBreaks'] as List) {
        if (item is Map<String, dynamic>) {
          bigBreaksList.add(BigBreak.fromJson(item));
        }
      }
    }
    // Sort by afterLesson
    bigBreaksList.sort((a, b) => a.afterLesson.compareTo(b.afterLesson));

    return AppSettings(
      startTime: TimeOfDay(
        hour: json['startHour'] ?? 8,
        minute: json['startMinute'] ?? 30,
      ),
      lessonDurationMinutes: json['lessonDurationMinutes'] ?? 45,
      breakDurationMinutes: json['breakDurationMinutes'] ?? 10,
      lessonsPerDay: json['lessonsPerDay'] ?? 6,
      bigBreaks: bigBreaksList,
      isConfigured: json['isConfigured'] ?? false,
    );
  }

  AppSettings copyWith({
    TimeOfDay? startTime,
    int? lessonDurationMinutes,
    int? breakDurationMinutes,
    int? lessonsPerDay,
    List<BigBreak>? bigBreaks,
    bool? isConfigured,
  }) {
    return AppSettings(
      startTime: startTime ?? this.startTime,
      lessonDurationMinutes: lessonDurationMinutes ?? this.lessonDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      lessonsPerDay: lessonsPerDay ?? this.lessonsPerDay,
      bigBreaks: bigBreaks ?? this.bigBreaks,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }

  // Helper to get big break after a specific lesson
  BigBreak? getBigBreakAfterLesson(int lessonNumber) {
    try {
      return bigBreaks.firstWhere((b) => b.afterLesson == lessonNumber);
    } catch (e) {
      return null;
    }
  }

  // Check if a lesson has a big break after it
  bool hasBigBreakAfterLesson(int lessonNumber) {
    return bigBreaks.any((b) => b.afterLesson == lessonNumber);
  }
}