import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/settings.dart';
import '../../models/big_break.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import 'big_breaks_editor_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings? initialSettings;
  final bool isFirstLaunch;

  const SettingsScreen({
    super.key,
    this.initialSettings,
    this.isFirstLaunch = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TimeOfDay _startTime;
  late TextEditingController _lessonDurationController;
  late TextEditingController _breakDurationController;
  late TextEditingController _lessonsPerDayController;
  late List<BigBreak> _bigBreaks;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.initialSettings ?? AppSettings.defaultSettings();
    _startTime = settings.startTime;
    _lessonDurationController = TextEditingController(text: settings.lessonDurationMinutes.toString());
    _breakDurationController = TextEditingController(text: settings.breakDurationMinutes.toString());
    _lessonsPerDayController = TextEditingController(text: settings.lessonsPerDay.toString());
    _bigBreaks = List.from(settings.bigBreaks);
    _bigBreaks.sort((a, b) => a.afterLesson.compareTo(b.afterLesson));
  }

  @override
  void dispose() {
    _lessonDurationController.dispose();
    _breakDurationController.dispose();
    _lessonsPerDayController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            timePickerTheme: TimePickerThemeData(
              dialHandColor: AppTheme.primaryColor,
              hourMinuteColor: AppTheme.primaryColor,
              dayPeriodColor: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final settings = AppSettings(
      startTime: _startTime,
      lessonDurationMinutes: int.parse(_lessonDurationController.text),
      breakDurationMinutes: int.parse(_breakDurationController.text),
      lessonsPerDay: int.parse(_lessonsPerDayController.text),
      bigBreaks: _bigBreaks,
      isConfigured: true,
    );

    await StorageService().saveSettings(settings);

    if (mounted) {
      setState(() => _isSaving = false);
      if (widget.isFirstLaunch) {
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        Navigator.of(context).pop(settings);
      }
    }
  }

  Future<void> _openBigBreaksEditor() async {
    final result = await Navigator.of(context).push<List<BigBreak>>(
      MaterialPageRoute(
        builder: (context) => BigBreaksEditorScreen(
          initialBigBreaks: _bigBreaks,
          lessonsPerDay: int.tryParse(_lessonsPerDayController.text) ?? 6,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _bigBreaks = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !widget.isFirstLaunch) {
          final settings = AppSettings(
            startTime: _startTime,
            lessonDurationMinutes: int.parse(_lessonDurationController.text),
            breakDurationMinutes: int.parse(_breakDurationController.text),
            lessonsPerDay: int.parse(_lessonsPerDayController.text),
            bigBreaks: _bigBreaks,
            isConfigured: true,
          );
          Navigator.pop(context, settings);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(widget.isFirstLaunch ? 'настройка' : 'настройки'),
          automaticallyImplyLeading: !widget.isFirstLaunch,
          elevation: 0,
        ),
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isFirstLaunch) ...[
                  _buildWelcomeHeader(),
                  const SizedBox(height: 32),
                ],

                _buildTimeSection(),
                const SizedBox(height: 20),
                _buildDurationSection(),
                const SizedBox(height: 20),
                _buildLessonsSection(),
                const SizedBox(height: 20),
                _buildBigBreaksSection(),

                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.school_outlined, size: 40, color: Colors.black),
        ),
        const SizedBox(height: 20),
        Text(
          'добро пожаловать в до звонка',
          style: AppTheme.unboundedStyle(fontSize: 26, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'настройте расписание, чтобы начать отслеживать время до звонка',
          style: AppTheme.onestStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return _SettingsSection(
      title: 'время начала занятий',
      icon: Icons.access_time_rounded,
      child: InkWell(
        onTap: _selectTime,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            children: [
              _buildIconContainer(Icons.access_time_rounded, AppTheme.primaryColor),
              const SizedBox(width: 16),
              Text(
                '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                style: AppTheme.onestStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1.5),
              ),
              const Spacer(),
              Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSection() {
    return Column(
      children: [
        _SettingsSection(
          title: 'длительность урока',
          subtitle: 'минуты',
          icon: Icons.schedule_rounded,
          child: _buildNumberField(
            controller: _lessonDurationController,
            hint: '45',
            icon: Icons.schedule_rounded,
            validator: (v) => _validateRange(v, 1, 180, 'от 1 до 180 минут'),
          ),
        ),
        const SizedBox(height: 14),
        _SettingsSection(
          title: 'длительность обычной перерыва',
          subtitle: 'минуты',
          icon: Icons.coffee_outlined,
          child: _buildNumberField(
            controller: _breakDurationController,
            hint: '10',
            icon: Icons.coffee_outlined,
            validator: (v) => _validateRange(v, 1, 60, 'от 1 до 60 минут'),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsSection() {
    return _SettingsSection(
      title: 'количество уроков в день',
      icon: Icons.numbers_rounded,
      child: _buildNumberField(
        controller: _lessonsPerDayController,
        hint: '6',
        icon: Icons.numbers_rounded,
        validator: (v) => _validateRange(v, 1, 12, 'от 1 до 12 уроков'),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: AppTheme.onestStyle(fontSize: 18, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.onestStyle(fontSize: 18, color: AppTheme.textDisabled),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: validator,
    );
  }

  String? _validateRange(String? value, int min, int max, String message) {
    if (value == null || value.isEmpty) return 'введите значение';
    final val = int.tryParse(value);
    if (val == null || val < min || val > max) return message;
    return null;
  }

  Widget _buildBigBreaksSection() {
    return _SettingsSection(
      title: 'большие перемены',
      subtitle: '${_bigBreaks.length} добавлено',
      icon: Icons.restaurant_menu_rounded,
      trailing: TextButton.icon(
        onPressed: _openBigBreaksEditor,
        icon: Icon(_bigBreaks.isEmpty ? Icons.add_rounded : Icons.edit_rounded, size: 16),
        label: Text(_bigBreaks.isEmpty ? 'добавить' : 'редактировать'),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.bigBreakColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      child: _bigBreaks.isEmpty
          ? _buildEmptyBigBreaks()
          : _buildBigBreaksList(),
    );
  }

  Widget _buildEmptyBigBreaks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.bigBreakColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant_rounded, color: AppTheme.bigBreakColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'больших перемен нет',
                  style: AppTheme.onestStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'добавьте обед или длительные перерывы между уроками',
                  style: AppTheme.onestStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openBigBreaksEditor,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.bigBreakColor,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('добавить', style: AppTheme.onestStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildBigBreaksList() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: _bigBreaks.asMap().entries.map((entry) {
          final index = entry.key;
          final bigBreak = entry.value;
          final isLast = index == _bigBreaks.length - 1;
          
          return InkWell(
            onTap: () => _editBigBreak(bigBreak, index),
            borderRadius: BorderRadius.only(
              topLeft: index == 0 ? const Radius.circular(16) : Radius.zero,
              topRight: index == 0 ? const Radius.circular(16) : Radius.zero,
              bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
              bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: !isLast ? Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 1)) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.bigBreakColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.restaurant_rounded, color: AppTheme.bigBreakColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bigBreak.displayName,
                          style: AppTheme.onestStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'после ${bigBreak.afterLesson} урока · ${bigBreak.durationMinutes} мин',
                          style: AppTheme.onestStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppTheme.textDisabled, size: 22),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _editBigBreak(BigBreak bigBreak, int index) {
    Navigator.of(context).push<List<BigBreak>>(
      MaterialPageRoute(
        builder: (context) => BigBreaksEditorScreen(
          initialBigBreaks: _bigBreaks,
          lessonsPerDay: int.tryParse(_lessonsPerDayController.text) ?? 6,
          initialEditIndex: index,
        ),
      ),
    ).then((result) {
      if (result != null && mounted) {
        setState(() => _bigBreaks = result);
      }
    });
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: AppTheme.onestStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                  )
                : Text(widget.isFirstLaunch ? 'начать' : 'сохранить'),
          ),
        ),
        if (!widget.isFirstLaunch) ...[
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('отмена', style: AppTheme.onestStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
      ],
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final Widget trailing;

  const _SettingsSection({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.child,
    this.trailing = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.unboundedStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTheme.onestStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}