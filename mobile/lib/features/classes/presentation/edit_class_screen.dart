import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../subjects/application/subjects_controller.dart';
import '../application/classes_controller.dart';
import '../domain/class_entry.dart';

class EditClassScreen extends ConsumerStatefulWidget {
  final String? classId;
  const EditClassScreen({super.key, this.classId});

  @override
  ConsumerState<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends ConsumerState<EditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _subjectId;
  int _dayOfWeek = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 30);
  final _roomController = TextEditingController();
  final _floorController = TextEditingController();
  final _teacherController = TextEditingController();
  bool _loaded = false;

  bool get _isEditing => widget.classId != null;

  @override
  void dispose() {
    _roomController.dispose();
    _floorController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  void _loadExisting(ClassEntry entry) {
    if (_loaded) return;
    _loaded = true;
    _subjectId = entry.subjectId;
    _dayOfWeek = entry.dayOfWeek;
    _startTime = _parseTime(entry.startTime);
    _endTime = _parseTime(entry.endTime);
    _roomController.text = entry.room ?? '';
    _floorController.text = entry.floor ?? '';
    _teacherController.text = entry.teacher ?? '';
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona uma disciplina')),
      );
      return;
    }

    final startStr = _formatTime(_startTime);
    final endStr = _formatTime(_endTime);

    if (startStr.compareTo(endStr) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A hora de início deve ser antes da hora de fim')),
      );
      return;
    }

    final notifier = ref.read(classesProvider.notifier);
    if (_isEditing) {
      final existing =
          await ref.read(classByIdProvider(widget.classId!).future);
      if (existing != null) {
        await notifier.updateClass(existing.copyWith(
          subjectId: _subjectId,
          dayOfWeek: _dayOfWeek,
          startTime: startStr,
          endTime: endStr,
          room: _roomController.text.trim().isEmpty
              ? null
              : _roomController.text.trim(),
          floor: _floorController.text.trim().isEmpty
              ? null
              : _floorController.text.trim(),
          teacher: _teacherController.text.trim().isEmpty
              ? null
              : _teacherController.text.trim(),
        ));
      }
    } else {
      await notifier.addClass(
        subjectId: _subjectId!,
        dayOfWeek: _dayOfWeek,
        startTime: startStr,
        endTime: endStr,
        room: _roomController.text.trim().isEmpty
            ? null
            : _roomController.text.trim(),
        floor: _floorController.text.trim().isEmpty
            ? null
            : _floorController.text.trim(),
        teacher: _teacherController.text.trim().isEmpty
            ? null
            : _teacherController.text.trim(),
      );
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);

    if (_isEditing) {
      final classAsync = ref.watch(classByIdProvider(widget.classId!));
      classAsync.whenData((entry) {
        if (entry != null) _loadExisting(entry);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar aula' : 'Nova aula'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Guardar',
                style: TextStyle(color: AppColors.primary, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Subject picker
            Text('Disciplina', style: AppTypography.caption),
            const SizedBox(height: 8),
            subjectsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Erro: $e'),
              data: (subjects) {
                if (subjects.isEmpty) {
                  return Text('Cria uma disciplina primeiro',
                      style: AppTypography.body
                          .copyWith(color: AppColors.textSecondary));
                }
                return DropdownButtonFormField<String>(
                  initialValue: _subjectId,
                  decoration: const InputDecoration(
                    hintText: 'Selecionar disciplina',
                    border: OutlineInputBorder(),
                  ),
                  items: subjects
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _subjectId = v),
                  validator: (v) =>
                      v == null ? 'Seleciona uma disciplina' : null,
                );
              },
            ),
            const SizedBox(height: 20),

            // Day of week picker
            Text('Dia da semana', style: AppTypography.caption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final day = i + 1;
                final isSelected = _dayOfWeek == day;
                return ChoiceChip(
                  label: Text(ClassEntry.weekdayShort[day]),
                  selected: isSelected,
                  selectedColor: AppColors.chipActive,
                  backgroundColor: AppColors.chipDefault,
                  labelStyle: AppTypography.chip.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide.none,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _dayOfWeek = day),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Time pickers
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Início',
                    time: _startTime,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimePicker(
                    label: 'Fim',
                    time: _endTime,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Room
            TextFormField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Sala',
                hintText: 'Ex: B2',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.room_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Floor
            TextFormField(
              controller: _floorController,
              decoration: const InputDecoration(
                labelText: 'Piso',
                hintText: 'Ex: 2',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.layers_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Teacher
            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: 'Professor(a)',
                hintText: 'Ex: Prof. Silva',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: AppTypography.body,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
