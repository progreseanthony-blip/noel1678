import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_app/src/features/projects/presentation/utils/machinery_planning_dates.dart';
import 'package:noel_app/src/features/projects/presentation/widgets/machinery_batch_schedule_dialog.dart';

void main() {
  final start = DateTime(2026, 11, 2), end = DateTime(2026, 11, 19);
  Map<String, dynamic> machine(
    String id, {
    int expected = 3,
    int planned = 0,
    String service = 'Clearing',
  }) => {
    'id': id,
    'machinery_name': id,
    'service_name': service,
    'expected_quantity': expected,
    'project_machinery_assignments': [
      if (planned > 0)
        {
          'id': 'assignment-$id',
          'start_date': '2026-10-01',
          'end_date': '2026-10-05',
          'quantity': planned,
        },
    ],
  };
  test(
    'unplanned machinery proposes service dates without today or seven-day defaults',
    () {
      final proposal = MachineryPlanningDates.propose(
        machine('m'),
        referenceStart: start,
        referenceEnd: end,
      );
      expect(proposal.start, start);
      expect(proposal.end, end);
      final missing = MachineryPlanningDates.propose(machine('m'));
      expect(missing.start, isNull);
      expect(missing.end, isNull);
    },
  );
  test('saved unit dates win over summary and service reference', () {
    final m = machine('m', planned: 1)
      ..addAll({'start_date': '2026-09-01', 'end_date': '2026-09-02'});
    final proposal = MachineryPlanningDates.propose(
      m,
      referenceStart: start,
      referenceEnd: end,
    );
    expect(proposal.start, DateTime(2026, 10, 1));
    expect(proposal.end, DateTime(2026, 10, 5));
  });
  test(
    'missing end uses service working days and calendar from shifted saved start',
    () {
      final proposal = MachineryPlanningDates.propose(
        {'start_date': '2026-11-06'},
        referenceStart: start,
        referenceEnd: end,
        workingDays: 2,
        calendar: {'2026-11-09': 1},
      );
      expect(proposal.end, DateTime(2026, 11, 10));
    },
  );
  test('multi-unit summary spans every assignment, not first group', () {
    final m = machine('m', planned: 1);
    (m['project_machinery_assignments'] as List).add({
      'id': 'later',
      'start_date': '2026-10-10',
      'end_date': '2026-10-30',
      'quantity': 2,
    });
    final proposal = MachineryPlanningDates.propose(
      m,
      referenceStart: start,
      referenceEnd: end,
    );
    expect(proposal.start, DateTime(2026, 10, 1));
    expect(proposal.end, DateTime(2026, 10, 30));
    expect(MachineryPlanningDates.missingUnits(m), 0);
    expect(MachineryPlanningDates.missingUnits(machine('m', planned: 2)), 1);
  });
  test('different service references do not invent a common period', () {
    expect(
      MachineryPlanningDates.common([
        MachineryPlanningDates(start, end),
        MachineryPlanningDates(start, end.add(const Duration(days: 3))),
      ]),
      isNull,
    );
    expect(
      MachineryPlanningDates.common([
        MachineryPlanningDates(start, end),
        MachineryPlanningDates(start, end),
      ])?.end,
      end,
    );
  });
  test('optimistic snapshot is stable and preserves each group quantity', () {
    final m = machine('m', planned: 2);
    final snapshot = MachineryPlanningService.snapshot(
      m['project_machinery_assignments'] as List,
    );
    expect(snapshot.single['quantity'], 2);
    expect(snapshot.single['start_date'], '2026-10-01');
  });

  Future<void> open(
    WidgetTester tester,
    List<Map<String, dynamic>> machines, {
    Map<String, Map<String, DateTime?>>? references,
    Map<String, double?> durations = const {},
    Map<String, double> calendar = const {},
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => MachineryBatchScheduleDialog(
                  machines: machines,
                  references:
                      references ??
                      {
                        'Clearing': {'start': start, 'end': end},
                      },
                  durations: durations,
                  calendar: calendar,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> replace(WidgetTester tester) async {
    final field = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace dates for all shown units').last);
    await tester.pumpAndSettle();
  }

  Future<void> pickDay(WidgetTester tester, String field, int day) async {
    await tester.tap(find.text(field));
    await tester.pumpAndSettle();
    await tester.tap(find.text('$day').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'changed start proposes working-day end and permits manual override',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await open(
        tester,
        [machine('m')],
        durations: {'Clearing': 2},
        calendar: {'2026-11-09': 1},
      );
      // Existing reference is shown until the planner changes the start.
      expect(find.text('2026-11-19'), findsOneWidget);
      await pickDay(tester, 'Start Date', 1);
      expect(find.text('2026-11-03'), findsOneWidget);
      // Friday + half Saturday + holiday Monday => Tuesday.
      await pickDay(tester, 'Start Date', 6);
      expect(find.text('2026-11-10'), findsOneWidget);
      await pickDay(tester, 'End Date', 12);
      expect(find.text('2026-11-12'), findsOneWidget);
      await pickDay(tester, 'Start Date', 6);
      expect(find.text('2026-11-12'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bulk proposal covers longest service duration', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await open(
      tester,
      [machine('m1'), machine('m2', service: 'Topsoil')],
      references: {
        'Clearing': {'start': start, 'end': end},
        'Topsoil': {'start': start, 'end': end},
      },
      durations: {'Clearing': 1, 'Topsoil': 2},
      calendar: {'2026-11-09': 1},
    );
    await pickDay(tester, 'Start Date', 6);
    expect(find.text('2026-11-10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing duration retains the manually editable end', (
    tester,
  ) async {
    await open(tester, [machine('m')]);
    await pickDay(tester, 'Start Date', 6);
    expect(find.text('2026-11-19'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending counts missing units; replacement includes all shown units',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await open(tester, [
        machine('m1', planned: 2),
        machine('m2', expected: 2, planned: 2),
      ]);
      expect(
        find.text('1 machine(s) · 1 unit(s) will be updated.'),
        findsOneWidget,
      );
      expect(find.text('2026-11-02'), findsWidgets);
      await replace(tester);
      expect(
        find.text('2 machine(s) · 5 unit(s) will be updated.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'fully scheduled machinery can switch to correcting existing dates',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await open(tester, [machine('m', planned: 3)]);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Apply dates'),
            )
            .onPressed,
        isNull,
      );
      await replace(tester);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Apply dates'),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        find.text('1 machine(s) · 3 unit(s) will be updated.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('different references leave common dates unselected', (
    tester,
  ) async {
    await open(
      tester,
      [machine('m1'), machine('m2', service: 'Topsoil')],
      references: {
        'Clearing': {'start': start, 'end': end},
        'Topsoil': {
          'start': DateTime(2026, 12, 1),
          'end': DateTime(2026, 12, 20),
        },
      },
    );
    expect(find.text('Choose...'), findsNWidgets(2));
    expect(find.textContaining('Clearing · 2026-11-02'), findsOneWidget);
    expect(find.textContaining('Topsoil · 2026-12-01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
