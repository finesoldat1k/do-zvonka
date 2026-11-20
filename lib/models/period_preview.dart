import 'big_break.dart';

class PeriodPreview {
  final int lessonNumber;
  final bool isBreak;
  final bool isBigBreak;
  final BigBreak? bigBreak;
  final DateTime endTime;

  PeriodPreview({
    required this.lessonNumber,
    required this.isBreak,
    required this.isBigBreak,
    this.bigBreak,
    required this.endTime,
  });

  factory PeriodPreview.lesson({
    required int lessonNumber,
    required DateTime endTime,
  }) {
    return PeriodPreview(
      lessonNumber: lessonNumber,
      isBreak: false,
      isBigBreak: false,
      bigBreak: null,
      endTime: endTime,
    );
  }

  factory PeriodPreview.breakTime({
    required int lessonNumber,
    required DateTime endTime,
  }) {
    return PeriodPreview(
      lessonNumber: lessonNumber,
      isBreak: true,
      isBigBreak: false,
      bigBreak: null,
      endTime: endTime,
    );
  }

  factory PeriodPreview.bigBreak({
    required int lessonNumber,
    required BigBreak bigBreak,
    required DateTime endTime,
  }) {
    return PeriodPreview(
      lessonNumber: lessonNumber,
      isBreak: true,
      isBigBreak: true,
      bigBreak: bigBreak,
      endTime: endTime,
    );
  }
}