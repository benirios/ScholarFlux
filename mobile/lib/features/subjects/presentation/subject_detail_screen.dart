import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../items/application/items_controller.dart';
import '../../items/domain/item.dart';
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
                                _ItemTile(
                                    item: items[index],
                                    subject: subject),
                          ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.goNamed(
              'new-item',
              pathParameters: {'subjectId': subjectId},
            ),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text('Delete subject?', style: AppTypography.cardTitle),
        content: Text(
          'This will permanently delete "${subject.name}" and all its items.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
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
    return Container(
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
                  child: Text(subject.name,
                      style: AppTypography.cardTitle)),
              itemsAsync.when(
                data: (items) {
                  final avg = subject.averageGrade(items);
                  final label =
                      avg != null ? avg.toStringAsFixed(0) : '–';
                  return Text('Média-$label',
                      style: AppTypography.badge);
                },
                loading: () =>
                    Text('Média-…', style: AppTypography.badge),
                error: (_, _) =>
                    Text('Média-?', style: AppTypography.badge),
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
    return GestureDetector(
      onTap: () => context.goNamed(
        'item-detail',
        pathParameters: {
          'subjectId': subject.id,
          'itemId': item.id,
        },
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCardLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child:
                        Text(item.title, style: AppTypography.cardTitle)),
                if (item.grade != null)
                  Text('Nota-${item.grade!.toStringAsFixed(0)}',
                      style: AppTypography.badge),
              ],
            ),
            if (item.domainId != null) ...[
              const SizedBox(height: 6),
              Builder(builder: (_) {
                final domainScores = <String>[];
                for (final d in subject.domains) {
                  if (d.id == item.domainId && item.grade != null) {
                    domainScores.add('${d.name}-${item.grade!.toStringAsFixed(1)}');
                  }
                }
                if (domainScores.isEmpty) return const SizedBox.shrink();
                return Text(
                  'Domínios: ${domainScores.join("  ")}',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
