import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_helpers.dart';
import '../../subjects/application/subjects_controller.dart';
import '../application/classes_controller.dart';
import '../domain/class_entry.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    final subjectNames = <String, String>{};
    subjectsAsync.whenData((subjects) {
      for (final s in subjects) {
        subjectNames[s.id] = s.name;
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Text('Schedule', style: AppTypography.headerLarge),
                ),
              ),
              classesAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(
                    child: Text('Error: $e',
                        style: AppTypography.body
                            .copyWith(color: AppColors.error))),
                data: (classes) {
                  if (classes.isEmpty) {
                    return SliverToBoxAdapter(
                      child: GlassContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text('No classes registered',
                                style: AppTypography.cardSubtitle),
                            const SizedBox(height: 4),
                            Text('Tap + to add one',
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                    );
                  }

                  // Group by day of week
                  final byDay = <int, List<ClassEntry>>{};
                  for (final c in classes) {
                    byDay.putIfAbsent(c.dayOfWeek, () => []).add(c);
                  }
                  final sortedDays = byDay.keys.toList()..sort();

                  final widgets = <Widget>[];
                  for (final day in sortedDays) {
                    final dayClasses = byDay[day]!
                      ..sort((a, b) => a.compareTo(b));
                    widgets.add(Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        ClassEntry.weekdayLabels[day],
                        style: AppTypography.sectionTitle,
                      ),
                    ));
                    for (final c in dayClasses) {
                      widgets.add(Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ClassTile(
                          entry: c,
                          subjectName: subjectNames[c.subjectId] ?? '',
                          onTap: () => context.goNamed(
                            'edit-class',
                            pathParameters: {'classId': c.id},
                          ),
                          onDelete: () => _confirmDelete(context, ref, c),
                        ),
                      ));
                    }
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => AnimatedListItem(
                        index: i,
                        child: widgets[i],
                      ),
                      childCount: widgets.length,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed('new-class'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ClassEntry entry) async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: 'Delete class?',
      message: 'Are you sure you want to delete this ${entry.weekdayLabel} class?',
    );
    if (confirmed == true) {
      ref.read(classesProvider.notifier).deleteClass(entry.id);
    }
  }
}

class _ClassTile extends StatelessWidget {
  final ClassEntry entry;
  final String subjectName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ClassTile({
    required this.entry,
    required this.subjectName,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      onLongPress: onDelete,
      child: Row(
          children: [
            // Time column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.startTime,
                    style: AppTypography.cardTitle.copyWith(fontSize: 16)),
                Text(entry.endTime,
                    style: AppTypography.cardSubtitle.copyWith(fontSize: 12)),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subjectName, style: AppTypography.cardTitle),
                  if (entry.location != null || entry.teacher != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (entry.location != null)
                          Flexible(
                            child: Text(
                              entry.location!,
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (entry.location != null && entry.teacher != null)
                          Text(' · ',
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.textTertiary)),
                        if (entry.teacher != null)
                          Flexible(
                            child: Text(
                              entry.teacher!,
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
    );
  }
}
