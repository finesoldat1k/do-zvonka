import 'package:flutter/material.dart';
import '../../models/settings.dart';
import '../../models/schedule_info.dart';
import '../../services/schedule_service.dart';
import '../../theme/app_theme.dart';

class TimerDisplay extends StatefulWidget {
  final ScheduleInfo scheduleInfo;
  final AppSettings settings;
  final DateTime lastUpdate;

  const TimerDisplay({
    super.key,
    required this.scheduleInfo,
    required this.settings,
    required this.lastUpdate,
  });

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.settings.isConfigured) {
      return const SizedBox.shrink();
    }

    final isFinished = widget.scheduleInfo.remainingSeconds <= 0;
    final progress = _calculateProgress();
    final timerColor = _getTimerColor();
    final bgGradient = _getBackgroundGradient();

    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.dividerColor),
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isFinished ? 1.0 : _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: bgGradient,
                border: Border.all(
                  color: timerColor.withValues(alpha: isFinished ? 0.2 : 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Period type label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: timerColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: timerColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.scheduleInfo.periodTypeLabel,
                      style: AppTheme.onestStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: widget.scheduleInfo.isBigBreak ? Colors.black : Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Circular timer
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CustomPaint(
                          painter: _TimerPainter(
                            progress: isFinished ? 1.0 : progress,
                            color: timerColor,
                            bgColor: Colors.white.withValues(alpha: 0.15),
                            strokeWidth: 10,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isFinished ? '00:00' : _formatTime(widget.scheduleInfo.remainingSeconds),
                            style: AppTheme.unboundedStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isFinished ? _getFinishedText() : 'осталось до звонка',
                            style: AppTheme.onestStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Period end time
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'заканчивается в ${ScheduleService.formatTime(TimeOfDay.fromDateTime(widget.scheduleInfo.periodEndTime))}',
                          style: AppTheme.onestStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress bar
                  _buildProgressBar(progress, timerColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color color) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              width: MediaQuery.of(context).size.width * 0.8 * progress,
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.scheduleInfo.remainingSeconds <= 0
                  ? _getFinishedText()
                  : 'прошло ${(progress * 100).round()}% времени',
              style: AppTheme.onestStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            if (widget.scheduleInfo.remainingSeconds > 0)
              _buildTimeLabels(),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeLabels() {
    int totalDuration;
    if (widget.scheduleInfo.isBigBreak && widget.scheduleInfo.currentBigBreak != null) {
      totalDuration = widget.scheduleInfo.currentBigBreak!.durationMinutes * 60;
    } else if (widget.scheduleInfo.isBreak) {
      totalDuration = widget.settings.breakDurationMinutes * 60;
    } else {
      totalDuration = widget.settings.lessonDurationMinutes * 60;
    }

    final elapsed = totalDuration - widget.scheduleInfo.remainingSeconds;
    return Row(
      children: [
        Text(
          _formatTime(elapsed),
          style: AppTheme.onestStyle(fontSize: 12, color: AppTheme.textDisabled),
        ),
        const SizedBox(width: 8),
        Text(
          '/',
          style: AppTheme.onestStyle(fontSize: 12, color: AppTheme.textDisabled),
        ),
        const SizedBox(width: 8),
        Text(
          _formatTime(totalDuration),
          style: AppTheme.onestStyle(fontSize: 12, color: AppTheme.textDisabled),
        ),
      ],
    );
  }

  Color _getTimerColor() {
    if (widget.scheduleInfo.isBigBreak) return AppTheme.bigBreakColor;
    if (widget.scheduleInfo.isBreak) return AppTheme.accentColor;
    return AppTheme.lessonColor;
  }

  LinearGradient _getBackgroundGradient() {
    final color = _getTimerColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: 0.18),
        color.withValues(alpha: 0.06),
      ],
    );
  }

  double _calculateProgress() {
    if (!widget.settings.isConfigured) return 0.0;

    int totalDuration;
    if (widget.scheduleInfo.isBigBreak && widget.scheduleInfo.currentBigBreak != null) {
      totalDuration = widget.scheduleInfo.currentBigBreak!.durationMinutes * 60;
    } else if (widget.scheduleInfo.isBreak) {
      totalDuration = widget.settings.breakDurationMinutes * 60;
    } else {
      totalDuration = widget.settings.lessonDurationMinutes * 60;
    }

    if (totalDuration <= 0) return 0.0;

    final elapsed = totalDuration - widget.scheduleInfo.remainingSeconds;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return '00:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getFinishedText() {
    if (widget.scheduleInfo.isBigBreak) return 'большая перемена закончилась';
    if (widget.scheduleInfo.isBreak) return 'перемена закончилась';
    if (widget.scheduleInfo.currentLessonNumber == 0) return 'занятия начинаются';
    return 'урок закончился';
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _TimerPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -3.14159 / 2,
        endAngle: 3 * 3.14159 / 2,
        colors: [color, color.withValues(alpha: 0.8)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _TimerPainter && oldDelegate.progress != progress;
  }
}