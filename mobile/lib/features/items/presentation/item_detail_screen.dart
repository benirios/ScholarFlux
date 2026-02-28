import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../subjects/application/subjects_controller.dart';
import '../application/items_controller.dart';
import '../domain/item.dart';
import '../domain/item_type.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemByIdProvider(itemId));

    return itemAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          body: Center(
              child: Text('Error: $e',
                  style:
                      AppTypography.body.copyWith(color: AppColors.error)))),
      data: (item) {
        if (item == null) {
          return Scaffold(
              body: Center(
                  child:
                      Text('Item not found', style: AppTypography.cardTitle)));
        }

        final subjectAsync = ref.watch(subjectByIdProvider(item.subjectId));

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text('Item Detail', style: AppTypography.cardTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                onPressed: () => context.goNamed(
                  'edit-item',
                  pathParameters: {
                    'subjectId': item.subjectId,
                    'itemId': item.id,
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: AppColors.error),
                onPressed: () => _confirmDelete(context, ref, item),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(item.title,
                                  style: AppTypography.cardTitle)),
                          Text(
                            item.grade != null
                                ? 'Nota-${item.grade!.toStringAsFixed(0)}'
                                : 'Nota-–',
                            style: AppTypography.badge,
                          ),
                        ],
                      ),
                      if (item.domainId != null)
                        subjectAsync.when(
                          data: (subject) {
                            if (subject == null) return const SizedBox.shrink();
                            final domain = subject.domains
                                .where((d) => d.id == item.domainId)
                                .firstOrNull;
                            if (domain == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Domain: ${domain.name} (${domain.weight.toStringAsFixed(0)}%)',
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Toggle complete
                GestureDetector(
                  onTap: () =>
                      ref.read(itemsProvider.notifier).toggleComplete(item),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: item.isCompleted
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.isCompleted
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: item.isCompleted
                              ? AppColors.success
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.isCompleted
                              ? 'Completed'
                              : 'Mark as complete',
                          style: AppTypography.body.copyWith(
                            color: item.isCompleted
                                ? AppColors.success
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Details', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),
                _DetailRow(label: 'Type', value: item.type.label),
                _DetailRow(
                  label: 'Due date',
                  value: item.dueDate != null
                      ? '${item.dueDate!.day}/${item.dueDate!.month}/${item.dueDate!.year}'
                      : '—',
                ),
                _DetailRow(label: 'Priority', value: item.priority.label),
                _DetailRow(label: 'Status', value: item.status.label),
                if (item.origin != null && item.origin!.isNotEmpty)
                  _DetailRow(label: 'Origin', value: item.origin!),
                if (item.grade != null)
                  _DetailRow(
                      label: 'Grade',
                      value: item.grade!.toStringAsFixed(1)),
                if (item.type == ItemType.test && item.weight != null)
                  _DetailRow(
                      label: 'Weight',
                      value: '${item.weight!.toStringAsFixed(0)}%'),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Description', style: AppTypography.sectionTitle),
                  const SizedBox(height: 8),
                  Text(item.description, style: AppTypography.body),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text('Delete item?', style: AppTypography.cardTitle),
        content: Text(
          'This will permanently delete "${item.title}".',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(itemsProvider.notifier).deleteItem(item.id);
      if (context.mounted) context.pop();
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.cardSubtitle),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}
