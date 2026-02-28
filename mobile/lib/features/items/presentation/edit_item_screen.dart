import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../subjects/application/subjects_controller.dart';
import '../application/items_controller.dart';
import '../domain/item.dart';
import '../domain/item_type.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String? itemId;

  const EditItemScreen({super.key, required this.subjectId, this.itemId});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originController = TextEditingController();
  final _gradeController = TextEditingController();
  final _weightController = TextEditingController();

  ItemType _selectedType = ItemType.assignment;
  ItemPriority _selectedPriority = ItemPriority.medium;
  DateTime? _dueDate;
  String? _selectedDomainId;
  bool _loaded = false;

  bool get _isEditing => widget.itemId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originController.dispose();
    _gradeController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _loadExisting(Item item) {
    if (_loaded) return;
    _loaded = true;
    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _originController.text = item.origin ?? '';
    _gradeController.text =
        item.grade != null ? item.grade!.toStringAsFixed(1) : '';
    _weightController.text =
        item.weight != null ? item.weight!.toStringAsFixed(0) : '';
    _selectedType = item.type;
    _selectedPriority = item.priority;
    _dueDate = item.dueDate;
    _selectedDomainId = item.domainId;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final origin = _originController.text.trim();
    final grade = double.tryParse(_gradeController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    final notifier = ref.read(itemsProvider.notifier);
    if (_isEditing) {
      final existing =
          await ref.read(itemByIdProvider(widget.itemId!).future);
      if (existing != null) {
        await notifier.updateItem(existing.copyWith(
          title: title,
          type: _selectedType,
          description: description,
          dueDate: _dueDate,
          priority: _selectedPriority,
          origin: origin.isEmpty ? null : origin,
          grade: grade,
          weight: weight,
          domainId: _selectedDomainId,
        ));
      }
    } else {
      await notifier.addItem(
        subjectId: widget.subjectId,
        title: title,
        type: _selectedType,
        description: description,
        dueDate: _dueDate,
        priority: _selectedPriority,
        origin: origin.isEmpty ? null : origin,
        grade: grade,
        weight: weight,
        domainId: _selectedDomainId,
      );
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Load existing item data for edit mode
    if (_isEditing && !_loaded) {
      final itemAsync = ref.watch(itemByIdProvider(widget.itemId!));
      itemAsync.whenData((item) {
        if (item != null) _loadExisting(item);
      });
    }

    final subjectAsync = ref.watch(subjectByIdProvider(widget.subjectId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Item' : 'New Item',
          style: AppTypography.cardTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Item title'),
              style: AppTypography.body,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Type chips
            Row(
              children: ItemType.values.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type.label),
                    selected: isSelected,
                    selectedColor: AppColors.chipActive,
                    backgroundColor: AppColors.chipDefault,
                    labelStyle: AppTypography.chip.copyWith(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    showCheckmark: false,
                    onSelected: (_) =>
                        setState(() => _selectedType = type),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(hintText: 'Description'),
              style: AppTypography.body,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Due date
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: _dueDate != null
                        ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                        : 'Due date',
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                  style: AppTypography.body,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Origin
            TextField(
              controller: _originController,
              decoration: const InputDecoration(hintText: 'Origin (who assigned it)'),
              style: AppTypography.body,
            ),
            const SizedBox(height: 16),

            // Priority dropdown
            DropdownButtonFormField<ItemPriority>(
              initialValue: _selectedPriority,
              decoration: const InputDecoration(hintText: 'Priority'),
              dropdownColor: AppColors.surfaceCard,
              style: AppTypography.body,
              items: ItemPriority.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.label, style: AppTypography.body),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedPriority = v);
              },
            ),
            const SizedBox(height: 16),

            // Domain dropdown
            subjectAsync.when(
              data: (subject) {
                if (subject == null || subject.domains.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedDomainId,
                      decoration: const InputDecoration(hintText: 'Domain'),
                      dropdownColor: AppColors.surfaceCard,
                      style: AppTypography.body,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No domain'),
                        ),
                        ...subject.domains.map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text('${d.name} (${d.weight.toStringAsFixed(0)}%)'),
                            )),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedDomainId = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // Grade
            subjectAsync.when(
              data: (subject) {
                final max = subject?.maxGrade.toStringAsFixed(0) ?? '20';
                return TextField(
                  controller: _gradeController,
                  decoration:
                      InputDecoration(hintText: 'Grade (0–$max)'),
                  style: AppTypography.body,
                  keyboardType: TextInputType.number,
                );
              },
              loading: () => TextField(
                controller: _gradeController,
                decoration: const InputDecoration(hintText: 'Grade'),
                style: AppTypography.body,
                keyboardType: TextInputType.number,
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Weight (test only)
            if (_selectedType == ItemType.test) ...[
              TextField(
                controller: _weightController,
                decoration:
                    const InputDecoration(hintText: 'Weight % (grade contribution)'),
                style: AppTypography.body,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),
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
                  _isEditing ? 'Save Changes' : 'Create Item',
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
