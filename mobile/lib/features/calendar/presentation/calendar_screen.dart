import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../items/application/items_controller.dart';
import '../../items/domain/item.dart';
import '../../subjects/application/subjects_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
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

  late int _selectedMonth;
  late int _selectedYear;
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;

    final monthItemsAsync = ref.watch(
      itemsByMonthProvider((year: _selectedYear, month: _selectedMonth)),
    );
    final subjectsAsync = ref.watch(subjectsProvider);

    // Build a map of subjectId -> name for display
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
              // Date header (always today)
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
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final isActive = i == _selectedMonth - 1;
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
                        onSelected: (_) {
                          setState(() {
                            _selectedMonth = i + 1;
                            _selectedDay = null;
                          });
                        },
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
                child: monthItemsAsync.when(
                  data: (items) {
                    final daysWithItems = <int>{};
                    for (final item in items) {
                      if (item.dueDate != null) {
                        daysWithItems.add(item.dueDate!.day);
                      }
                    }
                    return _CalendarGrid(
                      daysInMonth: daysInMonth,
                      firstWeekday: firstWeekday,
                      today: (_selectedYear == now.year &&
                              _selectedMonth == now.month)
                          ? now.day
                          : null,
                      daysWithItems: daysWithItems,
                      selectedDay: _selectedDay,
                      onDayTap: (day) {
                        setState(() {
                          _selectedDay = _selectedDay == day ? null : day;
                        });
                      },
                    );
                  },
                  loading: () => _CalendarGrid(
                    daysInMonth: daysInMonth,
                    firstWeekday: firstWeekday,
                    today: (_selectedYear == now.year &&
                            _selectedMonth == now.month)
                        ? now.day
                        : null,
                    daysWithItems: const {},
                    selectedDay: _selectedDay,
                    onDayTap: (_) {},
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // Selected day items (if a day is tapped)
              if (_selectedDay != null)
                ..._buildSelectedDaySection(now, subjectNames),
              // Trabalhos futuros
              SliverToBoxAdapter(
                child: Text('Trabalhos futuros',
                    style: AppTypography.sectionTitle),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              _buildFutureWorkSection(monthItemsAsync, subjectNames, now),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSelectedDaySection(
      DateTime now, Map<String, String> subjectNames) {
    final selectedDate =
        DateTime(_selectedYear, _selectedMonth, _selectedDay!);
    final dayItemsAsync = ref.watch(itemsByDateProvider(selectedDate));

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '$_selectedDay de ${_months[_selectedMonth]}',
            style: AppTypography.sectionTitle,
          ),
        ),
      ),
      dayItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Sem trabalhos neste dia',
                  style: AppTypography.cardSubtitle,
                ),
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FutureWorkTile(
                    item: item,
                    subjectName: subjectNames[item.subjectId] ?? '',
                    isOverdue: item.isOverdue,
                  ),
                );
              },
              childCount: items.length,
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  Widget _buildFutureWorkSection(
    AsyncValue<List<Item>> monthItemsAsync,
    Map<String, String> subjectNames,
    DateTime now,
  ) {
    return monthItemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return SliverToBoxAdapter(
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
                  Text('Sem trabalhos este mês',
                      style: AppTypography.cardSubtitle),
                ],
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FutureWorkTile(
                  item: item,
                  subjectName: subjectNames[item.subjectId] ?? '',
                  isOverdue: item.isOverdue,
                ),
              );
            },
            childCount: items.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final int daysInMonth;
  final int firstWeekday;
  final int? today;
  final Set<int> daysWithItems;
  final int? selectedDay;
  final ValueChanged<int> onDayTap;

  const _CalendarGrid({
    required this.daysInMonth,
    required this.firstWeekday,
    required this.today,
    required this.daysWithItems,
    required this.selectedDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final isToday = day == today;
      final hasItems = daysWithItems.contains(day);
      final isSelected = day == selectedDay;
      cells.add(
        GestureDetector(
          onTap: () => onDayTap(day),
          child: Container(
            width: 36,
            height: 36,
            decoration: isToday
                ? const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  )
                : isSelected
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      )
                    : null,
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: AppTypography.calendarDay.copyWith(
                color: isToday
                    ? Colors.white
                    : hasItems
                        ? AppColors.primary
                        : AppColors.textPrimary,
                fontWeight:
                    (isToday || hasItems) ? FontWeight.w600 : FontWeight.w400,
              ),
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

class _FutureWorkTile extends StatelessWidget {
  final Item item;
  final String subjectName;
  final bool isOverdue;

  const _FutureWorkTile({
    required this.item,
    required this.subjectName,
    required this.isOverdue,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${(date.year % 100).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subjectName.isNotEmpty)
                  Text(
                    subjectName,
                    style: AppTypography.cardSubtitle.copyWith(
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (item.dueDate != null)
            Text(
              _formatDate(item.dueDate!),
              style: AppTypography.cardSubtitle.copyWith(
                color: isOverdue ? Colors.redAccent : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
