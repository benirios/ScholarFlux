import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/subjects/presentation/subjects_screen.dart';
import '../../features/subjects/presentation/edit_subject_screen.dart';
import '../../features/items/presentation/edit_item_screen.dart';
import '../../features/items/presentation/item_detail_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/subjects',
      name: 'subjects',
      builder: (context, state) => const SubjectsScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'new-subject',
          builder: (context, state) => const EditSubjectScreen(),
        ),
        GoRoute(
          path: ':subjectId',
          name: 'subject-detail',
          builder: (context, state) {
            final subjectId = state.pathParameters['subjectId']!;
            return SubjectsScreen(subjectId: subjectId);
          },
          routes: [
            GoRoute(
              path: 'edit',
              name: 'edit-subject',
              builder: (context, state) {
                final subjectId = state.pathParameters['subjectId']!;
                return EditSubjectScreen(subjectId: subjectId);
              },
            ),
            GoRoute(
              path: 'items/new',
              name: 'new-item',
              builder: (context, state) {
                final subjectId = state.pathParameters['subjectId']!;
                return EditItemScreen(subjectId: subjectId);
              },
            ),
            GoRoute(
              path: 'items/:itemId',
              name: 'item-detail',
              builder: (context, state) {
                final itemId = state.pathParameters['itemId']!;
                return ItemDetailScreen(itemId: itemId);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'edit-item',
                  builder: (context, state) {
                    final subjectId = state.pathParameters['subjectId']!;
                    final itemId = state.pathParameters['itemId']!;
                    return EditItemScreen(
                      subjectId: subjectId,
                      itemId: itemId,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/calendar',
      name: 'calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
  ],
);
