import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../application/subjects_controller.dart';
import '../domain/subject.dart';

class EditSubjectScreen extends ConsumerStatefulWidget {
  final String? subjectId;

  const EditSubjectScreen({super.key, this.subjectId});

  @override
  ConsumerState<EditSubjectScreen> createState() => _EditSubjectScreenState();
}

class _EditSubjectScreenState extends ConsumerState<EditSubjectScreen> {
  final _nameController = TextEditingController();
  final _roomController = TextEditingController();
  final _maxGradeController = TextEditingController(text: '20');
  final _formKey = GlobalKey<FormState>();
  List<_DomainRow> _domains = [];
  bool _loaded = false;

  bool get _isEditing => widget.subjectId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    _maxGradeController.dispose();
    for (final d in _domains) {
      d.nameController.dispose();
      d.weightController.dispose();
    }
    super.dispose();
  }

  void _loadExisting(Subject subject) {
    if (_loaded) return;
    _loaded = true;
    _nameController.text = subject.name;
    _roomController.text = subject.room ?? '';
    _maxGradeController.text = subject.maxGrade.toStringAsFixed(0);
    _domains = subject.domains
        .map((d) => _DomainRow(
              id: d.id,
              nameController: TextEditingController(text: d.name),
              weightController:
                  TextEditingController(text: d.weight.toStringAsFixed(0)),
            ))
        .toList();
  }

  void _addDomain() {
    setState(() {
      final index = _domains.length + 1;
      _domains.add(_DomainRow(
        id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
        nameController: TextEditingController(text: 'D$index'),
        weightController: TextEditingController(),
      ));
    });
  }

  void _removeDomain(int index) {
    setState(() {
      _domains[index].nameController.dispose();
      _domains[index].weightController.dispose();
      _domains.removeAt(index);
    });
  }

  List<SubjectDomain> _buildDomains() {
    return _domains
        .map((d) => SubjectDomain(
              id: d.id,
              name: d.nameController.text.trim(),
              weight: double.tryParse(d.weightController.text.trim()) ?? 0,
            ))
        .where((d) => d.name.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final room = _roomController.text.trim();
    final maxGrade =
        double.tryParse(_maxGradeController.text.trim()) ?? 20;
    final domains = _buildDomains();

    // Warn if weights don't sum to 100
    if (domains.isNotEmpty) {
      final totalWeight = domains.fold<double>(0, (s, d) => s + d.weight);
      if ((totalWeight - 100).abs() > 0.01) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            title: Text('Domain weights', style: AppTypography.cardTitle),
            content: Text(
              'Domain weights sum to ${totalWeight.toStringAsFixed(0)}% instead of 100%. Continue anyway?',
              style: AppTypography.body,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Continue')),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    final notifier = ref.read(subjectsProvider.notifier);
    if (_isEditing) {
      final existing =
          await ref.read(subjectByIdProvider(widget.subjectId!).future);
      if (existing != null) {
        await notifier.updateSubject(existing.copyWith(
          name: name,
          room: room.isEmpty ? null : room,
          domains: domains,
          maxGrade: maxGrade,
        ));
      }
    } else {
      await notifier.addSubject(
        name: name,
        room: room.isEmpty ? null : room,
        domains: domains,
        maxGrade: maxGrade,
      );
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Load existing subject data for edit mode
    if (_isEditing && !_loaded) {
      final subjectAsync = ref.watch(subjectByIdProvider(widget.subjectId!));
      subjectAsync.whenData((subject) {
        if (subject != null) _loadExisting(subject);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Subject' : 'New Subject',
          style: AppTypography.cardTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Subject name'),
              style: AppTypography.body,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(hintText: 'Room (optional)'),
              style: AppTypography.body,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxGradeController,
              decoration: const InputDecoration(hintText: 'Max grade (e.g. 20)'),
              style: AppTypography.body,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            // Domains section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Domains', style: AppTypography.sectionTitle),
                IconButton(
                  icon: Icon(Icons.add_circle_outline,
                      color: AppColors.primary, size: 22),
                  onPressed: _addDomain,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_domains.isEmpty)
              Text('No domains added yet. Tap + to add one.',
                  style: AppTypography.caption),
            ..._domains.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: d.nameController,
                        decoration:
                            const InputDecoration(hintText: 'Name'),
                        style: AppTypography.body,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: d.weightController,
                        decoration:
                            const InputDecoration(hintText: 'Weight %'),
                        style: AppTypography.body,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          color: AppColors.error, size: 20),
                      onPressed: () => _removeDomain(i),
                    ),
                  ],
                ),
              );
            }),
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
                  _isEditing ? 'Save Changes' : 'Create Subject',
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

class _DomainRow {
  final String id;
  final TextEditingController nameController;
  final TextEditingController weightController;

  _DomainRow({
    required this.id,
    required this.nameController,
    required this.weightController,
  });
}
