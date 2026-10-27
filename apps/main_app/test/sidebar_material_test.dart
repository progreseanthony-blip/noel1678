import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_app/src/shared/widgets/sidebar.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
    'sidebar sign-out paints on Material and remains usable during startup',
    (tester) async {
      var signOuts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Sidebar(
              userName: 'User',
              userEmail: '',
              currentPath: '/daily-reports',
              onLogout: () => signOuts++,
            ),
          ),
        ),
      );
      // Covers the access fallback and the delayed scroll callback.
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Sign out'), findsOneWidget);
      await tester.tap(find.byTooltip('Sign out'));
      await tester.pumpAndSettle();
      expect(signOuts, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 1400.0]) {
    testWidgets(
      'Supervisor shares the admin sidebar style without extra access at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var signedOut = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  Sidebar(
                    userName: 'Supervisor with a long display name',
                    userEmail: 'supervisor@example.test',
                    currentPath: '/projects/assigned',
                    onLogout: () => signedOut = true,
                    accessLoader: () async => const AccessContext(
                      role: 'Supervisor',
                      projects: {'assigned'},
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('CONSTRUCTION'), findsOneWidget);
        for (final label in [
          'Projects',
          'Resource Planning',
          'Daily Reports',
          'Pending Approvals',
          'Labor Cost',
          'Supervisor',
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        for (final label in [
          'Estimates',
          'User Management',
          'Settings',
          'Billing',
          'Catalogs',
        ]) {
          expect(find.text(label), findsNothing);
        }
        expect(
          tester.widget<Text>(find.text('Resource Planning')).style!.color,
          AppTheme.primaryGreen,
        );
        expect(
          tester.widget<Text>(find.text('Projects')).style!.color,
          AppTheme.slate400,
        );
        await tester.tap(find.byTooltip('Sign out'));
        await tester.pumpAndSettle();
        expect(signedOut, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final role in ['Admin', 'Foreman']) {
    testWidgets(
      '$role retains the original permitted menu in the shared shell',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  Sidebar(
                    userName: 'User',
                    userEmail: 'user@example.test',
                    currentPath: role == 'Admin' ? '/quotes' : '/daily-reports',
                    onLogout: () {},
                    accessLoader: () async => AccessContext(role: role),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.text('CONSTRUCTION'), findsOneWidget);
        if (role == 'Admin') {
          expect(find.text('Estimates'), findsOneWidget);
          expect(find.text('User Management'), findsOneWidget);
          expect(find.text('Settings'), findsOneWidget);
        } else {
          expect(find.text('Daily Reports'), findsOneWidget);
          expect(find.text('Labor Cost'), findsOneWidget);
          expect(find.text('Resource Planning'), findsNothing);
          expect(find.text('Estimates'), findsNothing);
          expect(find.text('Settings'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
