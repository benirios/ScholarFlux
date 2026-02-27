import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomScrollView(
            slivers: [
              // Date header (same style as dashboard)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 20),
                  child: _SubjectsHeader(),
                ),
              ),
              // Empty state
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined,
                          size: 56, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      Text('No subjects yet',
                          style: AppTypography.cardTitle.copyWith(
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Tap + to add your first subject',
                          style: AppTypography.cardSubtitle),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed('new-subject'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _SubjectsHeader extends StatelessWidget {
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
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${now.day} de ${_months[now.month]}, ',
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
