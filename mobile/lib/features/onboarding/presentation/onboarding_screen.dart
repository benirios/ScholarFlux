import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/storage/app_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppPreferences.setOnboardingSeen();
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background glow accents
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Pages
          PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: const [
              _ChaosPage(),
              _OrganizedPage(),
              _GetStartedPage(),
            ],
          ),

          // Skip button
          if (_currentPage < 2)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: GestureDetector(
                onTap: _finish,
                child: Text(
                  'Skip',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

          // Bottom: dots + button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    32,
                    20,
                    32,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.scaffoldBg.withValues(alpha: 0.0),
                        AppColors.scaffoldBg.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textTertiary.withValues(alpha: 0.4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      // Action button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentPage == 2
                              ? FilledButton(
                                  key: const ValueKey('start'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _finish,
                                  child: Text(
                                    'Get Started',
                                    style: AppTypography.cardTitle.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : OutlinedButton(
                                  key: const ValueKey('next'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.glassBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () => _controller.nextPage(
                                    duration:
                                        const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                  ),
                                  child: Text(
                                    'Next',
                                    style: AppTypography.cardTitle,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Page 1: Chaos — scattered glass cards
// ──────────────────────────────────────────────
class _ChaosPage extends StatefulWidget {
  const _ChaosPage();

  @override
  State<_ChaosPage> createState() => _ChaosPageState();
}

class _ChaosPageState extends State<_ChaosPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Scattered cards illustration
              SizedBox(
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 0,
                      left: 10,
                      child: Transform.rotate(
                        angle: -0.12,
                        child: _MiniCard(
                          icon: Icons.assignment_rounded,
                          label: 'Math HW',
                          color: AppColors.error.withValues(alpha: 0.15),
                          iconColor: AppColors.error,
                          delay: 200,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 30,
                      right: 0,
                      child: Transform.rotate(
                        angle: 0.15,
                        child: _MiniCard(
                          icon: Icons.quiz_rounded,
                          label: 'History Test',
                          color: AppColors.warning.withValues(alpha: 0.15),
                          iconColor: AppColors.warning,
                          delay: 350,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 30,
                      child: Transform.rotate(
                        angle: 0.08,
                        child: _MiniCard(
                          icon: Icons.book_rounded,
                          label: 'Physics Report',
                          color: AppColors.primary.withValues(alpha: 0.15),
                          iconColor: AppColors.primary,
                          delay: 500,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 20,
                      child: Transform.rotate(
                        angle: -0.1,
                        child: _MiniCard(
                          icon: Icons.edit_note_rounded,
                          label: 'Essay Due!',
                          color: AppColors.error.withValues(alpha: 0.15),
                          iconColor: AppColors.error,
                          delay: 650,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'School life\nis chaotic',
                style: AppTypography.headerLarge.copyWith(fontSize: 32),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Assignments, tests, homework — it\'s hard to\nkeep track of everything across all subjects.',
                style: AppTypography.cardSubtitle.copyWith(
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Page 2: Organized — neat glass cards
// ──────────────────────────────────────────────
class _OrganizedPage extends StatefulWidget {
  const _OrganizedPage();

  @override
  State<_OrganizedPage> createState() => _OrganizedPageState();
}

class _OrganizedPageState extends State<_OrganizedPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Organized cards
              Column(
                children: [
                  _OrganizedRow(
                    icon: Icons.calculate_rounded,
                    subject: 'Mathematics',
                    items: ['Algebra HW', 'Exam #2'],
                    color: AppColors.primary,
                    delay: 100,
                  ),
                  const SizedBox(height: 10),
                  _OrganizedRow(
                    icon: Icons.history_edu_rounded,
                    subject: 'History',
                    items: ['Essay Draft', 'Ch. 5 Quiz'],
                    color: AppColors.warning,
                    delay: 250,
                  ),
                  const SizedBox(height: 10),
                  _OrganizedRow(
                    icon: Icons.science_rounded,
                    subject: 'Physics',
                    items: ['Lab Report'],
                    color: AppColors.success,
                    delay: 400,
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                'ScholarFlux\norganizes it all',
                style: AppTypography.headerLarge.copyWith(fontSize: 32),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Subjects, items, calendar, and schedule —\neverything in one place.',
                style: AppTypography.cardSubtitle.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Page 3: Get Started
// ──────────────────────────────────────────────
class _GetStartedPage extends StatefulWidget {
  const _GetStartedPage();

  @override
  State<_GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<_GetStartedPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Glowing logo card
              ScaleTransition(
                scale: _scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: GlassContainer(
                    borderRadius: 60,
                    padding: const EdgeInsets.all(28),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Ready to\nget started?',
                style: AppTypography.headerLarge.copyWith(fontSize: 32),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Create your first subject and take control\nof your school life.',
                style: AppTypography.cardSubtitle.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Shared mini-card widget (chaos page)
// ──────────────────────────────────────────────
class _MiniCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final int delay;

  const _MiniCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    this.delay = 0,
  });

  @override
  State<_MiniCard> createState() => _MiniCardState();
}

class _MiniCardState extends State<_MiniCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GlassContainer(
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 16, color: widget.iconColor),
              ),
              const SizedBox(width: 10),
              Text(widget.label, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Organized row widget (page 2)
// ──────────────────────────────────────────────
class _OrganizedRow extends StatefulWidget {
  final IconData icon;
  final String subject;
  final List<String> items;
  final Color color;
  final int delay;

  const _OrganizedRow({
    required this.icon,
    required this.subject,
    required this.items,
    required this.color,
    this.delay = 0,
  });

  @override
  State<_OrganizedRow> createState() => _OrganizedRowState();
}

class _OrganizedRowState extends State<_OrganizedRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 20, color: widget.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.subject, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      widget.items.join(' · '),
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded,
                  size: 20, color: AppColors.success.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
