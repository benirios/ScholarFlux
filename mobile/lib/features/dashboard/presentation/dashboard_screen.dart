import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
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
              // "Aulas" section
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
              SliverToBoxAdapter(
                child: _PlaceholderCard(
                  icon: Icons.assignment_outlined,
                  message: 'No upcoming assignments',
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // "Trabalhos futuros" section
              SliverToBoxAdapter(
                child:
                    Text('Trabalhos futuros', style: AppTypography.sectionTitle),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: _PlaceholderCard(
                  icon: Icons.event_note_rounded,
                  message: 'No future work items',
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
