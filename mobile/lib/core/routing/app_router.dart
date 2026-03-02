import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'nav_shell.dart';
import '../storage/app_preferences.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/subjects/presentation/subjects_screen.dart';
import '../../features/subjects/presentation/subject_detail_screen.dart';
import '../../features/subjects/presentation/edit_subject_screen.dart';
import '../../features/items/presentation/edit_item_screen.dart';
import '../../features/items/presentation/item_detail_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/classes/presentation/schedule_screen.dart';
import '../../features/classes/presentation/edit_class_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';

/// Smooth fade+slide page transition for inner routes.
CustomTransitionPage<void> _fadeSlide(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Initial location defaults to sign-in; the ClerkAuth widget tree
/// will handle redirecting signed-in users. Onboarding check happens
/// via GoRouter redirect.
final goRouter = GoRouter(
  initialLocation: '/sign-in',
  redirect: (context, state) {
    final path = state.matchedLocation;
    // If on auth routes, let them through
    if (path == '/sign-in' || path == '/sign-up') return null;
    // Check onboarding
    if (!AppPreferences.hasSeenOnboarding && path != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    // Auth routes (no guard)
    GoRoute(
      path: '/sign-in',
      name: 'sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      name: 'sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          NavShell(navigationShell: navigationShell),
      branches: [
        // Tab 0 — Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'analytics',
                  name: 'analytics',
                  pageBuilder: (context, state) =>
                      _fadeSlide(state, const AnalyticsScreen()),
                ),
              ],
            ),
          ],
        ),
        // Tab 1 — Subjects
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/subjects',
              name: 'subjects',
              builder: (context, state) => const SubjectsScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  name: 'new-subject',
                  pageBuilder: (context, state) =>
                      _fadeSlide(state, const EditSubjectScreen()),
                ),
                GoRoute(
                  path: ':subjectId',
                  name: 'subject-detail',
                  pageBuilder: (context, state) {
                    final subjectId = state.pathParameters['subjectId']!;
                    return _fadeSlide(state, SubjectDetailScreen(subjectId: subjectId));
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: 'edit-subject',
                      pageBuilder: (context, state) {
                        final subjectId = state.pathParameters['subjectId']!;
                        return _fadeSlide(state, EditSubjectScreen(subjectId: subjectId));
                      },
                    ),
                    GoRoute(
                      path: 'items/new',
                      name: 'new-item',
                      pageBuilder: (context, state) {
                        final subjectId = state.pathParameters['subjectId']!;
                        return _fadeSlide(state, EditItemScreen(subjectId: subjectId));
                      },
                    ),
                    GoRoute(
                      path: 'items/:itemId',
                      name: 'item-detail',
                      pageBuilder: (context, state) {
                        final itemId = state.pathParameters['itemId']!;
                        return _fadeSlide(state, ItemDetailScreen(itemId: itemId));
                      },
                      routes: [
                        GoRoute(
                          path: 'edit',
                          name: 'edit-item',
                          pageBuilder: (context, state) {
                            final subjectId =
                                state.pathParameters['subjectId']!;
                            final itemId = state.pathParameters['itemId']!;
                            return _fadeSlide(state, EditItemScreen(
                              subjectId: subjectId,
                              itemId: itemId,
                            ));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // Tab 2 — Calendar
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              name: 'calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
          ],
        ),
        // Tab 3 — Schedule (Horário)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/schedule',
              name: 'schedule',
              builder: (context, state) => const ScheduleScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  name: 'new-class',
                  pageBuilder: (context, state) =>
                      _fadeSlide(state, const EditClassScreen()),
                ),
                GoRoute(
                  path: ':classId/edit',
                  name: 'edit-class',
                  pageBuilder: (context, state) {
                    final classId = state.pathParameters['classId']!;
                    return _fadeSlide(state, EditClassScreen(classId: classId));
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
