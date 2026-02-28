import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_helpers.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/theme/typography.dart';
import '../../items/application/items_controller.dart';
import '../../items/domain/item.dart';
import '../../items/domain/item_type.dart';
import '../application/subjects_controller.dart';
import '../domain/subject.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final String subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectAsync = ref.watch(subjectByIdProvider(subjectId));
    final itemsAsync = ref.watch(itemsBySubjectProvider(subjectId));

    return subjectAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          body: Center(
              child: Text('Error: $e',
                  style:
                      AppTypography.body.copyWith(color: AppColors.error)))),
      data: (subject) {
        if (subject == null) {
          return Scaffold(
              body: Center(
                  child: Text('Subject not found',
                      style: AppTypography.cardTitle)));
        }
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(subject.name, style: AppTypography.cardTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => context.goNamed(
                  'edit-subject',
                  pathParameters: {'subjectId': subjectId},
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: AppColors.error),
                onPressed: () => _confirmDelete(context, ref, subject),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Subject header card
                _SubjectHeaderCard(
                    subject: subject, itemsAsync: itemsAsync),
                const SizedBox(height: 24),
                Text('Items', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),
                Expanded(
                  child: itemsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                        child: Text('Error: $e',
                            style: AppTypography.body
                                .copyWith(color: AppColors.error))),
                    data: (items) => items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_outlined,
                                    size: 48,
                                    color: AppColors.textTertiary),
                                const SizedBox(height: 12),
                                Text('No items yet',
                                    style: AppTypography.cardSubtitle),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) =>
                                AnimatedListItem(
                                  index: index,
                                  child: _ItemTile(
                                      item: items[index],
                                      subject: subject),
                                ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 64),
            child: FloatingActionButton.small(
              onPressed: () => context.goNamed(
                'new-item',
                pathParameters: {'subjectId': subjectId},
              ),
              child: const Icon(Icons.add_rounded, size: 20),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Subject subject) async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: 'Delete subject?',
      message: 'This will permanently delete "${subject.name}" and all its items.',
    );
    if (confirmed == true) {
      await ref
          .read(itemsProvider.notifier)
          .deleteItemsBySubject(subject.id);
      await ref.read(subjectsProvider.notifier).deleteSubject(subject.id);
      if (context.mounted) context.pop();
    }
  }
}

class _SubjectHeaderCard extends StatelessWidget {
  final Subject subject;
  final AsyncValue<List<Item>> itemsAsync;

  const _SubjectHeaderCard(
      {required this.subject, required this.itemsAsync});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(subject.name,
                      style: AppTypography.cardTitle)),
              itemsAsync.when(
                data: (items) {
                  final avg = subject.averageGrade(items);
                  final label =
                      avg != null ? avg.toStringAsFixed(0) : '–';
                  return Text('Avg $label',
                      style: AppTypography.badge);
                },
                loading: () =>
                    Text('Avg …', style: AppTypography.badge),
                error: (_, _) =>
                    Text('Avg ?', style: AppTypography.badge),
              ),
            ],
          ),
          if (subject.domains.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: subject.domains.map((d) {
                return Text(
                  '${d.name}-${d.weight.toStringAsFixed(0)}%',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final Item item;
  final Subject subject;

  const _ItemTile({required this.item, required this.subject});

  @override
  Widget build(BuildContext context) {
    final isOverdue = item.isOverdue;
    final isPending = item.status == ItemStatus.pending;
    
    // Find domain name
    String? domainName;
    if (item.domainId != null) {
      final domain = subject.domains.where((d) => d.id == item.domainId).firstOrNull;
      domainName = domain?.name;
    }
    
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => context.goNamed(
        'item-detail',
        pathParameters: {
          'subjectId': subject.id,
          'itemId': item.id,
        },
      ),
      child: Row(
          children: [
            // Status indicator
            Icon(
              item.isCompleted 
                  ? Icons.check_circle
                  : (isOverdue ? Icons.warning_amber_rounded : Icons.circle_outlined),
              size: 20,
              color: item.isCompleted
                  ? AppColors.success
                  : (isOverdue ? AppColors.error : AppColors.textTertiary),
            ),
            const SizedBox(width: 12),
            // Title and type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, 
                      style: AppTypography.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        item.type.label,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      if (item.dueDate != null) ...[
                        Text(' • ', style: AppTypography.caption.copyWith(color: AppColors.textTertiary)),
                        Text(
                          '${item.dueDate!.day}/${item.dueDate!.month}',
                          style: AppTypography.caption.copyWith(
                            color: isOverdue && isPending ? AppColors.error : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Right side info column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grade badge (if graded)
                if (item.grade != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGlow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.grade!.toStringAsFixed(0),
                      style: AppTypography.badge.copyWith(fontSize: 12),
                    ),
                  ),
                // Domain info
                if (domainName != null) ...[
                  if (item.grade != null) const SizedBox(height: 4),
                  Text(
                    domainName,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                // Weight info for tests
                if (item.type == ItemType.test && item.weight != null) ...[
                  if (domainName != null || item.grade != null) const SizedBox(height: 2),
                  Text(
                    '${item.weight!.toStringAsFixed(0)}%',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
    );
  }
}
