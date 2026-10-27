import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:noel_app/src/features/projects/presentation/utils/project_access_periods.dart';
import 'package:noel_app/src/features/projects/presentation/widgets/project_responsible_dialog.dart';

void main() {
  final periods = [
    ProjectAccessPeriod(
      name: 'Clearing',
      start: DateTime(2026, 11, 2),
      end: DateTime(2026, 11, 10),
      fromEstimate: true,
    ),
    ProjectAccessPeriod(
      name: 'Topsoil',
      start: DateTime(2026, 11, 8),
      end: DateTime(2026, 11, 25),
      workingDays: 16,
      fromEstimate: true,
    ),
  ];
  Future<void> open(
    WidgetTester tester, {
    List<ProjectAccessPeriod>? references,
    Future<void> Function(Map<String, dynamic>)? save,
  }) async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('access-preview'),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showSafeDialog<bool>(
                  context: context,
                  builder: (_) => ProjectResponsibleDialog(
                    periods: references ?? periods,
                    users: const [
                      {
                        'id': 'fred',
                        'name': 'Fred Parra',
                        'role': 'Supervisor',
                        'access_status': 'active',
                      },
                      {
                        'id': 'pending',
                        'name': 'Pending user',
                        'role': 'Foreman',
                        'access_status': 'pending',
                      },
                    ],
                    onSave: save ?? (_) async {},
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> selectPerson(WidgetTester tester) async {
    final selector = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    expect(find.text('Pending user (Foreman)'), findsNothing);
    await tester.tap(find.text('Fred Parra (Supervisor)').last);
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(1280, 950), const Size(390, 844)]) {
    testWidgets('service references and editable defaults fit $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? saved;
      await open(
        tester,
        save: (data) async {
          saved = data;
        },
      );
      expect(find.text('Service periods · reference'), findsOneWidget);
      expect(
        find.textContaining('2026-11-02 → 2026-11-10', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('2026-11-08 → 2026-11-25', findRichText: true),
        findsOneWidget,
      );
      final inputs = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(inputs.at(0)).controller!.text,
        '2026-11-02',
      );
      expect(
        tester.widget<TextFormField>(inputs.at(1)).controller!.text,
        '2026-11-25',
      );
      await selectPerson(tester);
      await tester.tap(find.text('Save Authorization'));
      await tester.pumpAndSettle();
      expect(saved?['valid_from'], '2026-11-02');
      expect(saved?['valid_until'], '2026-11-25');
      expect(saved?['responsibility'], 'Supervisor');
      expect(find.byType(ProjectResponsibleDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'invalid range is rejected and an open-ended authorization is allowed',
    (tester) async {
      Map<String, dynamic>? saved;
      await open(
        tester,
        save: (data) async {
          saved = data;
        },
      );
      await selectPerson(tester);
      final end = find.byType(TextFormField).at(1);
      await tester.ensureVisible(end);
      await tester.enterText(end, '2026-11-01');
      await tester.tap(find.text('Save Authorization'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(
        find.text('End date must be on or after start date'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Use service period'));
      await tester.tap(find.text('Use service period'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(end).controller!.text, '2026-11-25');
      await tester.ensureVisible(end);
      await tester.enterText(end, '');
      await tester.tap(find.text('Save Authorization'));
      await tester.pumpAndSettle();
      expect(saved?['valid_until'], isNull);
    },
  );

  testWidgets(
    'missing references do not invent today; save failures retain input',
    (tester) async {
      await open(
        tester,
        references: [],
        save: (_) async {
          throw StateError('offline');
        },
      );
      final start = find.byType(TextFormField).at(0);
      expect(tester.widget<TextFormField>(start).controller!.text, isEmpty);
      await selectPerson(tester);
      await tester.ensureVisible(start);
      await tester.enterText(start, '2026-11-03');
      await tester.tap(find.text('Save Authorization'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectResponsibleDialog), findsOneWidget);
      expect(
        tester.widget<TextFormField>(start).controller!.text,
        '2026-11-03',
      );
      expect(
        find.textContaining('Could not save this authorization'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
