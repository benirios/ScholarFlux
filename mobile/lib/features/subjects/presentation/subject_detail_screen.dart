import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class SubjectDetailScreen extends StatelessWidget {
  final String subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Subject', style: AppTypography.cardTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Subject header card
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
                      Text('Subject $subjectId',
                          style: AppTypography.cardTitle),
                      Text('Média-0', style: AppTypography.badge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Domínios:', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  Text('No domain data yet', style: AppTypography.caption),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Items section
            Text('Items', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text('No items yet', style: AppTypography.cardSubtitle),
                  ],
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
  }
}
