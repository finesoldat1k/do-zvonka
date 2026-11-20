import 'big_break.dart';

class ScheduleInfo {
  final bool isBreak;
  final bool isBigBreak;
  final BigBreak? currentBigBreak;
  final int remainingSeconds;
  final int currentLessonNumber;
  final DateTime periodEndTime;

  ScheduleInfo({
    required this.isBreak,
    required this.isBigBreak,
    this.currentBigBreak,
    required this.remainingSeconds,
    required this.currentLessonNumber,
    required this.periodEndTime,
  });

  // Factory for regular lesson
  factory ScheduleInfo.lesson({
    required int remainingSeconds,
    required int currentLessonNumber,
    required DateTime periodEndTime,
  }) {
    return ScheduleInfo(
      isBreak: false,
      isBigBreak: false,
      currentBigBreak: null,
      remainingSeconds: remainingSeconds,
      currentLessonNumber: currentLessonNumber,
      periodEndTime: periodEndTime,
    );
  }

  // Factory for regular break
  factory ScheduleInfo.breakTime({
    required int remainingSeconds,
    required int currentLessonNumber,
    required DateTime periodEndTime,
  }) {
    return ScheduleInfo(
      isBreak: true,
      isBigBreak: false,
      currentBigBreak: null,
      remainingSeconds: remainingSeconds,
      currentLessonNumber: currentLessonNumber,
      periodEndTime: periodEndTime,
    );
  }

  // Factory for big break
  factory ScheduleInfo.bigBreak({
    required BigBreak bigBreak,
    required int remainingSeconds,
    required int currentLessonNumber,
    required DateTime periodEndTime,
  }) {
    return ScheduleInfo(
      isBreak: true,
      isBigBreak: true,
      currentBigBreak: bigBreak,
      remainingSeconds: remainingSeconds,
      currentLessonNumber: currentLessonNumber,
      periodEndTime: periodEndTime,
    );
  }

  // Factory for before school
  factory ScheduleInfo.beforeSchool({
    required int remainingSeconds,
    required DateTime periodEndTime,
  }) {
    return ScheduleInfo(
      isBreak: false,
      isBigBreak: false,
      currentBigBreak: null,
      remainingSeconds: remainingSeconds,
      currentLessonNumber: 0,
      periodEndTime: periodEndTime,
    );
  }

  // Factory for after school
  factory ScheduleInfo.afterSchool({
    required int currentLessonNumber,
    required DateTime periodEndTime,
  }) {
    return ScheduleInfo(
      isBreak: false,
      isBigBreak: false,
      currentBigBreak: null,
      remainingSeconds: 0,
      currentLessonNumber: currentLessonNumber,
      periodEndTime: periodEndTime,
    );
  }

  String get periodTypeLabel {
    if (isBigBreak && currentBigBreak != null) {
      return currentBigBreak!.name ?? 'большая перемена';
    }
    if (isBreak) {
      return 'перемена';
    }
    if (currentLessonNumber == 0) {
      return 'до занятий';
    }
    return 'урок $currentLessonNumber';
  }

  String get periodTypeShort {
    if (isBigBreak) return 'бол. перемена';
    if (isBreak) return 'перемена';
    if (currentLessonNumber == 0) return 'ожидание';
    return 'урок';
  }
}