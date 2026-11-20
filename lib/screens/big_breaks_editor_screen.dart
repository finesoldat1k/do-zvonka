import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/big_break.dart';
import '../../theme/app_theme.dart';

class BigBreaksEditorScreen extends StatefulWidget {
  final List<BigBreak> initialBigBreaks;
  final int lessonsPerDay;
  final int? initialEditIndex;

  const BigBreaksEditorScreen({
    super.key,
    required this.initialBigBreaks,
    required this.lessonsPerDay,
    this.initialEditIndex,
  });

  @override
  State<BigBreaksEditorScreen> createState() => _BigBreaksEditorScreenState();
}

class _BigBreaksEditorScreenState extends State<BigBreaksEditorScreen> {
  late List<BigBreak> _bigBreaks;

  @override
  void initState() {
    super.initState();
    _bigBreaks = List.from(widget.initialBigBreaks);
    _bigBreaks.sort((a, b) => a.afterLesson.compareTo(b.afterLesson));
    
    // If editing a specific break, open the editor immediately
    if (widget.initialEditIndex != null && widget.initialEditIndex! < _bigBreaks.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editBigBreak(_bigBreaks[widget.initialEditIndex!], widget.initialEditIndex!);
      });
    }
  }

  void _addBigBreak() {
    _showBigBreakSheet();
  }

  void _editBigBreak(BigBreak bigBreak, int index) {
    _showBigBreakSheet(initialBigBreak: bigBreak, editIndex: index);
  }

  void _showBigBreakSheet({BigBreak? initialBigBreak, int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BigBreakEditorSheet(
        lessonsPerDay: widget.lessonsPerDay,
        existingBreaks: _bigBreaks,
        initialBigBreak: initialBigBreak,
        editIndex: editIndex,
        onSave: (updatedList) {
          setState(() => _bigBreaks = updatedList);
        },
      ),
    );
  }

  void _deleteBigBreak(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('удалить большую пересмену?', style: AppTheme.unboundedStyle(fontSize: 18)),
        content: Text(
          'большая перемена после ${_bigBreaks[index].afterLesson} урока будет удалена',
          style: AppTheme.onestStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('отмена', style: AppTheme.onestStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _bigBreaks.removeAt(index));
              Navigator.pop(context);
            },
            child: Text('удалить', style: AppTheme.onestStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('большие перемены'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, _bigBreaks),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _addBigBreak,
            tooltip: 'добавить',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_bigBreaks.isEmpty) {
      return _buildEmptyState();
    }
    return _buildList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.bigBreakColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.restaurant_menu_rounded, size: 50, color: AppTheme.bigBreakColor),
            ),
            const SizedBox(height: 24),
            Text(
              'больших перемен нет',
              style: AppTheme.unboundedStyle(fontSize: 24, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'добавьте обед или длительные перерывы между уроками\nнажмите «+» или кнопку ниже',
              style: AppTheme.onestStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addBigBreak,
              icon: const Icon(Icons.add_rounded),
              label: const Text('добавить большую пересмену'),
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(280, 56),
                backgroundColor: AppTheme.bigBreakColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: AppTheme.onestStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _bigBreaks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final bigBreak = _bigBreaks[index];
        return Dismissible(
          key: ValueKey(bigBreak.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 28),
          ),
          confirmDismiss: (_) async {
            _deleteBigBreak(index);
            return false;
          },
          child: Card(
            elevation: 0,
            color: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.dividerColor),
            ),
            child: InkWell(
              onTap: () => _editBigBreak(bigBreak, index),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bigBreak.displayName,
                            style: AppTheme.onestStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'после ${bigBreak.afterLesson} урока · ${bigBreak.durationMinutes} мин',
                            style: AppTheme.onestStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.textDisabled, size: 22),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BigBreakEditorSheet extends StatefulWidget {
  final int lessonsPerDay;
  final List<BigBreak> existingBreaks;
  final BigBreak? initialBigBreak;
  final int? editIndex;
  final Function(List<BigBreak>) onSave;

  const _BigBreakEditorSheet({
    required this.lessonsPerDay,
    required this.existingBreaks,
    this.initialBigBreak,
    this.editIndex,
    required this.onSave,
  });

  @override
  State<_BigBreakEditorSheet> createState() => _BigBreakEditorSheetState();
}

class _BigBreakEditorSheetState extends State<_BigBreakEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _afterLessonController;
  late TextEditingController _durationController;
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialBigBreak;
    _afterLessonController = TextEditingController(text: initial?.afterLesson.toString() ?? '');
    _durationController = TextEditingController(text: initial?.durationMinutes.toString() ?? '');
    _nameController = TextEditingController(text: initial?.name ?? '');
  }

  @override
  void dispose() {
    _afterLessonController.dispose();
    _durationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Set<int> get _usedLessons {
    final used = widget.existingBreaks
        .where((b) => b.id != widget.initialBigBreak?.id)
        .map((b) => b.afterLesson)
        .toSet();
    return used;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.bigBreakColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.restaurant_rounded, color: AppTheme.bigBreakColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.initialBigBreak == null ? 'новая большая перемена' : 'редактировать',
                        style: AppTheme.unboundedStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        widget.initialBigBreak == null 
                            ? 'добавьте обед или длительный перерыв' 
                            : 'измените параметры большой перемены',
                        style: AppTheme.onestStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: AppTheme.dividerColor, height: 1),
            const SizedBox(height: 20),

            _buildField(
              controller: _afterLessonController,
              label: 'после какого урока',
              hint: 'например: 3',
              icon: Icons.numbers_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) return 'введите номер урока';
                final lesson = int.tryParse(value);
                if (lesson == null) return 'введите число';
                if (lesson < 1 || lesson >= widget.lessonsPerDay) {
                  return 'урок должен быть от 1 до ${widget.lessonsPerDay - 1}';
                }
                if (_usedLessons.contains(lesson)) {
                  return 'большая перемена после этого урока уже есть';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildField(
              controller: _durationController,
              label: 'длительность (минуты)',
              hint: 'например: 30',
              icon: Icons.timer_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) return 'введите длительность';
                final duration = int.tryParse(value);
                if (duration == null) return 'введите число';
                if (duration < 5 || duration > 120) return 'от 5 до 120 минут';
                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildField(
              controller: _nameController,
              label: 'название (необязательно)',
              hint: 'обед, большая перемена...',
              icon: Icons.label_outlined,
              validator: null,
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                if (widget.initialBigBreak != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => _deleteAndReturn(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTheme.onestStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('удалить'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: widget.initialBigBreak != null ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.bigBreakColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: AppTheme.onestStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(widget.initialBigBreak == null ? 'добавить' : 'сохранить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: label.contains('минуты') || label.contains('урока') ? TextInputType.number : TextInputType.text,
      inputFormatters: label.contains('минуты') || label.contains('урока')
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: AppTheme.onestStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
        filled: true,
        fillColor: AppTheme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        labelStyle: AppTheme.onestStyle(color: AppTheme.textSecondary),
        hintStyle: AppTheme.onestStyle(color: AppTheme.textDisabled),
      ),
      validator: validator,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final bigBreak = BigBreak.create(
      afterLesson: int.parse(_afterLessonController.text),
      durationMinutes: int.parse(_durationController.text),
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
    );

    final updatedList = List<BigBreak>.from(widget.existingBreaks);
    if (widget.editIndex != null && widget.editIndex! < updatedList.length) {
      updatedList[widget.editIndex!] = bigBreak;
    } else {
      updatedList.add(bigBreak);
    }
    updatedList.sort((a, b) => a.afterLesson.compareTo(b.afterLesson));

    _isSaving = false;
    widget.onSave(updatedList);
    Navigator.pop(context);
  }

  void _deleteAndReturn() {
    final updatedList = List<BigBreak>.from(widget.existingBreaks);
    if (widget.editIndex != null && widget.editIndex! < updatedList.length) {
      updatedList.removeAt(widget.editIndex!);
    }
    widget.onSave(updatedList);
    Navigator.pop(context);
  }
}