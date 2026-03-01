import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/glass_container.dart';
import '../../items/application/items_controller.dart';
import '../../items/domain/item.dart';
import '../../items/domain/item_type.dart';
import '../../subjects/application/subjects_controller.dart';
import '../../subjects/domain/subject.dart';

/// Palette for chart lines — one color per subject.
const _chartColors = [
  Color(0xFF5A8AF2), // blue
  Color(0xFF30D158), // green
  Color(0xFFFF9F0A), // orange
  Color(0xFFFF453A), // red
  Color(0xFFBF5AF2), // purple
  Color(0xFF64D2FF), // cyan
  Color(0xFFFFD60A), // yellow
  Color(0xFFFF6482), // pink
];

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final itemsAsync = ref.watch(itemsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: subjectsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
              child: Text('Error: $e',
                  style: AppTypography.body.copyWith(color: AppColors.error))),
          data: (subjects) => itemsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style:
                        AppTypography.body.copyWith(color: AppColors.error))),
            data: (items) =>
                _AnalyticsBody(subjects: subjects, items: items),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final List<Subject> subjects;
  final List<Item> items;

  const _AnalyticsBody({required this.subjects, required this.items});

  @override
  Widget build(BuildContext context) {
    final gradedItems = items.where((i) => i.grade != null).toList();
    final completedItems =
        items.where((i) => i.status == ItemStatus.completed).toList();

    // Overall average grade (simple unweighted across all graded items)
    double? overallAvg;
    if (gradedItems.isNotEmpty) {
      overallAvg = gradedItems.fold<double>(0, (s, i) => s + i.grade!) /
          gradedItems.length;
    }

    // Overall completion rate
    final completionRate =
        items.isEmpty ? 0.0 : completedItems.length / items.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Header
        AnimatedListItem(
          index: 0,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.glassFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text('Analytics', style: AppTypography.headerLarge),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Summary cards
        AnimatedListItem(
          index: 1,
          child: _SummaryRow(
            overallAvg: overallAvg,
            completionRate: completionRate,
            totalItems: items.length,
          ),
        ),
        const SizedBox(height: 24),

        // Grade trends chart
        AnimatedListItem(
          index: 2,
          child: _GradeTrendsSection(
            subjects: subjects,
            items: items,
          ),
        ),
        const SizedBox(height: 24),

        // Completion per subject
        AnimatedListItem(
          index: 3,
          child: _CompletionSection(
            subjects: subjects,
            items: items,
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

// ─── Summary cards ──────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final double? overallAvg;
  final double completionRate;
  final int totalItems;

  const _SummaryRow({
    required this.overallAvg,
    required this.completionRate,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.grade_rounded,
            label: 'Avg Grade',
            value: overallAvg != null ? overallAvg!.toStringAsFixed(1) : '—',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.check_circle_rounded,
            label: 'Completed',
            value: '${(completionRate * 100).toStringAsFixed(0)}%',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.assignment_rounded,
            label: 'Total',
            value: '$totalItems',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      borderRadius: 16,
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.headerLarge.copyWith(
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

// ─── Grade Trends (Line Chart) ──────────────────────────────────────────────

class _GradeTrendsSection extends StatelessWidget {
  final List<Subject> subjects;
  final List<Item> items;

  const _GradeTrendsSection({
    required this.subjects,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // Only subjects that have graded items
    final subjectsWithGrades = subjects.where((s) {
      return items.any((i) => i.subjectId == s.id && i.grade != null);
    }).toList();

    if (subjectsWithGrades.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.show_chart_rounded,
                color: AppColors.textTertiary, size: 40),
            const SizedBox(height: 12),
            Text('No grades yet',
                style: AppTypography.cardTitle
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Grade trends will appear once you add grades',
                style: AppTypography.caption, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    // Find global max grade for Y-axis
    final maxGrade = subjects.fold<double>(
        20, (prev, s) => math.max(prev, s.maxGrade));

    // Build line data per subject
    final lineBars = <LineChartBarData>[];
    for (var si = 0; si < subjectsWithGrades.length; si++) {
      final subject = subjectsWithGrades[si];
      final color = _chartColors[si % _chartColors.length];
      final subjectItems = items
          .where((i) => i.subjectId == subject.id && i.grade != null)
          .toList()
        ..sort((a, b) {
          final aDate = a.dueDate ?? a.createdAt;
          final bDate = b.dueDate ?? b.createdAt;
          return aDate.compareTo(bDate);
        });

      final spots = <FlSpot>[];
      for (var i = 0; i < subjectItems.length; i++) {
        spots.add(FlSpot(i.toDouble(), subjectItems[i].grade!));
      }

      lineBars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: color,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 3.5,
            color: color,
            strokeWidth: 1.5,
            strokeColor: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.08),
        ),
      ));
    }

    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text('GRADE TRENDS', style: AppTypography.sectionTitle),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: lineBars,
                minY: 0,
                maxY: maxGrade,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxGrade / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: maxGrade / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppTypography.caption.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppColors.surfaceCard.withValues(alpha: 0.95),
                    tooltipBorder:
                        const BorderSide(color: AppColors.glassBorder),
                    tooltipRoundedRadius: 10,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final si = lineBars.indexOf(spot.bar);
                        final name = si >= 0 && si < subjectsWithGrades.length
                            ? subjectsWithGrades[si].name
                            : '';
                        return LineTooltipItem(
                          '$name\n${spot.y.toStringAsFixed(1)}',
                          AppTypography.caption.copyWith(
                            color: spot.bar.color,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (var i = 0; i < subjectsWithGrades.length; i++)
                _LegendItem(
                  color: _chartColors[i % _chartColors.length],
                  label: subjectsWithGrades[i].name,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption.copyWith(fontSize: 12)),
      ],
    );
  }
}

// ─── Completion Section ─────────────────────────────────────────────────────

class _CompletionSection extends StatelessWidget {
  final List<Subject> subjects;
  final List<Item> items;

  const _CompletionSection({
    required this.subjects,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('COMPLETION RATE', style: AppTypography.sectionTitle),
        ),
        ...subjects.asMap().entries.map((entry) {
          final subject = entry.value;
          final subjectItems =
              items.where((i) => i.subjectId == subject.id).toList();
          final completed = subjectItems
              .where((i) => i.status == ItemStatus.completed)
              .length;
          final total = subjectItems.length;
          final rate = total == 0 ? 0.0 : completed / total;

          Color barColor;
          if (rate >= 0.8) {
            barColor = AppColors.success;
          } else if (rate >= 0.5) {
            barColor = AppColors.warning;
          } else {
            barColor = AppColors.error;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassContainer(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(subject.name,
                            style: AppTypography.cardTitle,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        total == 0
                            ? 'No items'
                            : '$completed/$total · ${(rate * 100).toStringAsFixed(0)}%',
                        style: AppTypography.cardSubtitle.copyWith(
                          color: barColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 6,
                      backgroundColor: AppColors.glassFill,
                      valueColor: AlwaysStoppedAnimation(barColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
