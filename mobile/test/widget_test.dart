import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholar_flux/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ScholarFluxApp()),
    );
    // Dashboard is the initial route — verify the bottom nav is present
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Subjects'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
  });
}
