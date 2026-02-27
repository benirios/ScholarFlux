import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  static const _monthLabels = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];
  static const _weekdayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const _months = [
    '', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];
  static const _weekdays = [
    '', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;

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
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_ios_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: '${now.day} de ${_months[now.month]}, ',
                            style: AppTypography.headerLarge,
                          ),
                          TextSpan(
                            text: _weekdays[now.weekday],
                            style: AppTypography.headerAccent,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              // Month chips
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _monthLabels.length,
                    separatorBuilder: (_, i) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final isActive = i == now.month - 1;
                      return ChoiceChip(
                        label: Text(_monthLabels[i]),
                        selected: isActive,
                        selectedColor: AppColors.chipActive,
                        backgroundColor: AppColors.chipDefault,
                        labelStyle: AppTypography.chip.copyWith(
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide.none,
                        showCheckmark: false,
                        onSelected: (_) {},
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // Weekday headers
              SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _weekdayLabels
                      .map((d) => SizedBox(
                            width: 36,
                            child: Center(
                              child: Text(d, style: AppTypography.caption),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              // Calendar grid
              SliverToBoxAdapter(
                child: _CalendarGrid(
                  daysInMonth: daysInMonth,
                  firstWeekday: firstWeekday,
                  today: now.day,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // Future work section
              SliverToBoxAdapter(
                child: Text('Trabalhos futuros',
                    style: AppTypography.sectionTitle),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_note_rounded,
                          size: 36, color: AppColors.textTertiary),
                      const SizedBox(height: 8),
                      Text('No future work items',
                          style: AppTypography.cardSubtitle),
                    ],
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

class _CalendarGrid extends StatelessWidget {
  final int daysInMonth;
  final int firstWeekday; // 1 = Monday
  final int today;

  const _CalendarGrid({
    required this.daysInMonth,
    required this.firstWeekday,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    // Empty cells before first day
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final isToday = day == today;
      cells.add(
        Container(
          width: 36,
          height: 36,
          decoration: isToday
              ? const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: AppTypography.calendarDay.copyWith(
              color: isToday ? Colors.white : AppColors.textPrimary,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }
    return Wrap(
      spacing: (MediaQuery.of(context).size.width - 32 - 7 * 36) / 6,
      runSpacing: 6,
      children: cells,
    );
  }
}
