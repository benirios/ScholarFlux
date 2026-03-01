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
    TimeOfDay picked = initial;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: 280,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                  Text(isStart ? 'Start Time' : 'End Time',
                      style: AppTypography.cardTitle),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (isStart) {
                          _startTime = picked;
                        } else {
                          _endTime = picked;
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text('Done',
                        style: AppTypography.body
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _TimeWheelPicker(
                initialTime: initial,
                onChanged: (t) => picked = t,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a subject')),
      );
      return;
    }

    final startStr = _formatTime(_startTime);
    final endStr = _formatTime(_endTime);

    if (startStr.compareTo(endStr) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Start time must be before end time')),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Class' : 'New Class',
          style: AppTypography.cardTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Subject picker
            subjectsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (subjects) {
                if (subjects.isEmpty) {
                  return Text('Create a subject first',
                      style: AppTypography.body
                          .copyWith(color: AppColors.textSecondary));
                }
                return DropdownButtonFormField<String>(
                  initialValue: _subjectId,
                  decoration: const InputDecoration(
                    hintText: 'Select subject',
                  ),
                  dropdownColor: AppColors.surfaceCard,
                  style: AppTypography.body,
                  items: subjects
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name, style: AppTypography.body),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _subjectId = v),
                  validator: (v) =>
                      v == null ? 'Select a subject' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Day of week picker
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
            const SizedBox(height: 16),

            // Time pickers
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(isStart: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start',
                        suffixIcon: Icon(Icons.access_time_rounded, size: 18),
                      ),
                      child: Text(
                        _formatTime(_startTime),
                        style: AppTypography.body,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(isStart: false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End',
                        suffixIcon: Icon(Icons.access_time_rounded, size: 18),
                      ),
                      child: Text(
                        _formatTime(_endTime),
                        style: AppTypography.body,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Room
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                hintText: 'Room (e.g. B2)',
              ),
              style: AppTypography.body,
            ),
            const SizedBox(height: 16),

            // Floor
            TextField(
              controller: _floorController,
              decoration: const InputDecoration(
                hintText: 'Floor (e.g. 2)',
              ),
              style: AppTypography.body,
            ),
            const SizedBox(height: 16),

            // Teacher
            TextField(
              controller: _teacherController,
              decoration: const InputDecoration(
                hintText: 'Teacher (optional)',
              ),
              style: AppTypography.body,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _save,
                child: Text(
                  _isEditing ? 'Save Changes' : 'Create Class',
                  style: AppTypography.body,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TimeWheelPicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeWheelPicker({
    required this.initialTime,
    required this.onChanged,
  });

  @override
  State<_TimeWheelPicker> createState() => _TimeWheelPickerState();
}

class _TimeWheelPickerState extends State<_TimeWheelPicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(TimeOfDay(hour: _hour, minute: _minute));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 70,
          child: ListWheelScrollView.useDelegate(
            controller: _hourController,
            itemExtent: 44,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1.2,
            onSelectedItemChanged: (i) {
              setState(() => _hour = i);
              _notify();
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 24,
              builder: (context, index) => Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: AppTypography.headerLarge.copyWith(
                    color: index == _hour
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(':', style: AppTypography.headerLarge),
        SizedBox(
          width: 70,
          child: ListWheelScrollView.useDelegate(
            controller: _minuteController,
            itemExtent: 44,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1.2,
            onSelectedItemChanged: (i) {
              setState(() => _minute = i);
              _notify();
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 60,
              builder: (context, index) => Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: AppTypography.headerLarge.copyWith(
                    color: index == _minute
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
