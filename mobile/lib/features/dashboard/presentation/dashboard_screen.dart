import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../items/application/items_controller.dart';
import '../../items/domain/item.dart';
import '../../items/domain/item_type.dart';
import '../../subjects/application/subjects_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final upcomingAsync = ref.watch(upcomingItemsProvider);
    final futureAsync = ref.watch(futureItemsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    // Build a subject name lookup map
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
              // Date header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: _DateHeader(date: now),
                ),
              ),
              // Day-of-week chips
              SliverToBoxAdapter(
                child: _WeekdayChips(selectedDay: now.weekday),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // "Aulas" section (placeholder)
              SliverToBoxAdapter(
                child: Text('Aulas', style: AppTypography.sectionTitle),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: _PlaceholderCard(
                  icon: Icons.school_rounded,
                  message: 'No classes scheduled',
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // "Upcoming" section
              SliverToBoxAdapter(
                child: Text('Upcoming', style: AppTypography.sectionTitle),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              upcomingAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(
                    child: Text('Error: $e',
                        style: AppTypography.body
                            .copyWith(color: AppColors.error))),
                data: (items) => items.isEmpty
                    ? SliverToBoxAdapter(
                        child: _PlaceholderCard(
                          icon: Icons.assignment_outlined,
                          message: 'No upcoming assignments',
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ItemCard(
                              item: items[index],
                              subjectName:
                                  subjectNames[items[index].subjectId],
                            ),
                          ),
                          childCount: items.length,
                        ),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // "Trabalhos futuros" section
              SliverToBoxAdapter(
                child: Text('Trabalhos futuros',
                    style: AppTypography.sectionTitle),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              futureAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(
                    child: Text('Error: $e',
                        style: AppTypography.body
                            .copyWith(color: AppColors.error))),
                data: (items) => items.isEmpty
                    ? SliverToBoxAdapter(
                        child: _PlaceholderCard(
                          icon: Icons.event_note_rounded,
                          message: 'No future work items',
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ItemCard(
                              item: items[index],
                              subjectName:
                                  subjectNames[items[index].subjectId],
                            ),
                          ),
                          childCount: items.length,
                        ),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  final String? subjectName;

  const _ItemCard({required this.item, this.subjectName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.goNamed(
        'item-detail',
        pathParameters: {
          'subjectId': item.subjectId,
          'itemId': item.id,
        },
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppTypography.cardTitle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TypeBadge(type: item.type),
                      if (subjectName != null) ...[
                        const SizedBox(width: 8),
                        Text(subjectName!,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (item.dueDate != null)
              Text(
                '${item.dueDate!.day}/${item.dueDate!.month}',
                style: AppTypography.dateLabel,
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final ItemType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.chipDefault,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(type.label,
          style: AppTypography.caption
              .copyWith(color: AppColors.textSecondary, fontSize: 10)),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  static const _weekdays = [
    '', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo',
  ];
  static const _months = [
    '', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${date.day} de ${_months[date.month]}, ',
            style: AppTypography.headerLarge,
          ),
          TextSpan(
            text: _weekdays[date.weekday],
            style: AppTypography.headerAccent,
          ),
        ],
      ),
    );
  }
}

class _WeekdayChips extends StatelessWidget {
  final int selectedDay;
  const _WeekdayChips({required this.selectedDay});

  static const _labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final isActive = selectedDay == i + 1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(_labels[i]),
            selected: isActive,
            selectedColor: AppColors.chipActive,
            backgroundColor: AppColors.chipDefault,
            labelStyle: AppTypography.chip.copyWith(
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide.none,
            showCheckmark: false,
            onSelected: (_) {},
          ),
        );
      }),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _PlaceholderCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text(message, style: AppTypography.cardSubtitle),
        ],
      ),
    );
  }
}
