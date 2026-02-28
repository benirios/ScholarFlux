import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/theme/typography.dart';
import '../../items/application/items_controller.dart';
import '../../items/domain/item.dart';
import '../application/subjects_controller.dart';
import '../domain/subject.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 20),
                  child: _SubjectsHeader(),
                ),
              ),
              subjectsAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Error: $e',
                        style: AppTypography.body
                            .copyWith(color: AppColors.error)),
                  ),
                ),
                data: (subjects) => subjects.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book_outlined,
                                  size: 56, color: AppColors.textTertiary),
                              const SizedBox(height: 12),
                              Text('No subjects yet',
                                  style: AppTypography.cardTitle
                                      .copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text('Tap + to add your first subject',
                                  style: AppTypography.cardSubtitle),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => AnimatedListItem(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SubjectCard(subject: subjects[index]),
                            ),
                          ),
                          childCount: subjects.length,
                        ),
                      ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 60, right: 8),
        child: FloatingActionButton(
          onPressed: () => context.goNamed('new-subject'),
          child: const Icon(Icons.add_rounded),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _SubjectCard extends ConsumerWidget {
  final Subject subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsBySubjectProvider(subject.id));

    return GlassContainer(
      onTap: () => context.goNamed(
        'subject-detail',
        pathParameters: {'subjectId': subject.id},
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(subject.name, style: AppTypography.cardTitle),
                ),
                itemsAsync.when(
                  data: (items) => _MediaBadge(subject: subject, items: items),
                  loading: () => Text('Avg …', style: AppTypography.badge),
                  error: (_, _) => Text('Avg ?', style: AppTypography.badge),
                ),
              ],
            ),
            if (subject.domains.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Domains:', style: AppTypography.caption),
              const SizedBox(height: 4),
              itemsAsync.when(
                data: (items) => _DomainScoresRow(
                    subject: subject, items: items),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ],
        ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  final Subject subject;
  final List<Item> items;
  const _MediaBadge({required this.subject, required this.items});

  @override
  Widget build(BuildContext context) {
    final avg = subject.averageGrade(items);
    final label = avg != null ? avg.toStringAsFixed(0) : '–';
    return Text('Avg $label', style: AppTypography.badge);
  }
}

class _DomainScoresRow extends StatelessWidget {
  final Subject subject;
  final List<Item> items;
  const _DomainScoresRow({required this.subject, required this.items});

  @override
  Widget build(BuildContext context) {
    final avgs = subject.domainAverages(items);
    return Wrap(
      spacing: 12,
      children: subject.domains.map((d) {
        final avg = avgs[d.id];
        final label = avg != null ? avg.toStringAsFixed(1) : '0';
        return Text('${d.name}-$label',
            style: AppTypography.caption
                .copyWith(color: AppColors.textSecondary));
      }).toList(),
    );
  }
}

class _SubjectsHeader extends StatelessWidget {
  static const _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${_months[now.month]} ${now.day}, ',
            style: AppTypography.headerLarge,
          ),
          TextSpan(
            text: _weekdays[now.weekday],
            style: AppTypography.headerAccent,
          ),
        ],
      ),
    );
  }
}
