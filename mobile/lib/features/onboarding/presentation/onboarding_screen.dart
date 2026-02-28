import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          children: const [
            _OnboardingPage(
              icon: Icons.warning_amber_rounded,
              title: 'School life is chaotic',
              subtitle:
                  'Assignments, tests, homework — it\'s hard to keep track of everything across all your subjects.',
            ),
            _OnboardingPage(
              icon: Icons.auto_awesome_rounded,
              title: 'ScholarFlux helps',
              subtitle:
                  'Organize subjects, track items, and see everything on a calendar. Never miss a deadline again.',
            ),
            _OnboardingPage(
              icon: Icons.rocket_launch_rounded,
              title: 'Get started',
              subtitle: 'Create your first subject and start organizing your school life.',
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: AppColors.primary),
          const SizedBox(height: 32),
          Text(title, style: AppTypography.headerLarge, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(subtitle, style: AppTypography.cardSubtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
