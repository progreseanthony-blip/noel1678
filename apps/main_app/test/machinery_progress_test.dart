import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_app/src/features/field_operations/presentation/utils/machinery_progress.dart';
import 'package:noel_app/src/features/field_operations/presentation/widgets/machinery_progress_panel.dart';
import 'package:noel_app/src/features/field_operations/presentation/widgets/step_machinery.dart';

Map<String, dynamic> snapshot() => {
  'date': '2026-11-07',
  'calendar': [
    {'date': '2026-11-03', 'partial_ratio': 1},
    {'date': '2026-11-04', 'partial_ratio': 0.5},
  ],
  'machinery': [
    {
      'id': 'truck',
      'quote_service_id': 'service',
      'unit': 'CY',
      'expected_quantity': 2,
      'capacity_per_trip': 10,
      'trips_per_day': 20,
      'assignments': [
        {'start_date': '2026-11-02', 'end_date': '2026-11-13', 'quantity': 2},
      ],
      'units': [
        {'id': 'a', 'name': 'Truck A'},
        {'id': 'b', 'name': 'Truck B'},
      ],
      'actual': [
        {'unit_id': 'a', 'before': 30, 'today_other': 2},
        {'unit_id': 'b', 'before': 10, 'today_other': 3},
        {'unit_id': null, 'before': 5, 'today_other': 0},
      ],
    },
  ],
};

List<Map<String, dynamic>> entries() => [
  {
    'project_machinery_id': 'truck',
    'machinery_inspection_id': 'b',
    'production_value': 7,
  },
  {
    'project_machinery_id': 'truck',
    'machinery_inspection_id': 'a',
    'production_value': 5,
  },
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final isCrew in [true, false]) {
    testWidgets(
      '${isCrew ? 'crew' : 'administrator'} screen shows service, machine and physical unit bars',
      (tester) async {
        tester.view.physicalSize = const Size(1800, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StepMachinery(
                  projectId: 'project',
                  operationalMode: isCrew,
                  progressSnapshot: {
                    ...snapshot(),
                    if (!isCrew) 'scope': 'report',
                  },
                  reportDate: '2026-11-07',
                  plannedMachinery: const [
                    {
                      'id': 'truck',
                      'quote_service_id': 'service',
                      'machinery_name': 'Haul truck',
                      'is_principal': true,
                      'expected_quantity': 2,
                      'quote_services': {
                        'name': 'Clearing',
                        'unit_of_measure': 'CY',
                      },
                      'machinery': {'capacity_yards': 10},
                    },
                  ],
                  machineryLogs: entries(),
                  workers: const [],
                  deviationReasons: const [],
                  laborLogs: const [],
                  plannedLabor: const [],
                  machineryCatalog: const [],
                  isReadOnly: true,
                  onLogsChanged: (_) =>
                      fail('Read-only view must not modify logs'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Service progress'), findsOneWidget);
        expect(find.text('Planned machinery progress'), findsNothing);
        expect(find.text('Unit Truck A'), findsOneWidget);
        expect(find.text('Unit Truck B'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
        expect(
          find.textContaining('To date: ${isCrew ? 370 : 350} / 800 CY'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'administrator counts current crew rows once, including pending entries',
    () {
      final data = snapshot()..['scope'] = 'report';
      final total = MachineryProgress(data, entries()).machine('truck').first;
      expect(total.today, 12);
      expect(total.actualToDate, 57);
    },
  );

  for (final actual in [130.0, 50.0]) {
    testWidgets('plan and actual share a scale for $actual vs 100', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductionComparisonBar(
              planned: 100,
              actual: actual,
              unit: 'CY',
            ),
          ),
        ),
      );
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(actual > 100 ? 1 : actual / 100, 0.00001));
      final track = tester.getRect(find.byType(LinearProgressIndicator));
      final marker = tester.getRect(
        find.byKey(const ValueKey('production-plan-marker')),
      );
      expect(
        (marker.left - track.left) / (track.width - 2),
        closeTo(actual > 100 ? 100 / actual : 1, 0.00001),
      );
    });
  }

  test('calendar applies Saturday, holidays and partial working days', () {
    final progress = MachineryProgress(snapshot(), entries());
    final trips = progress.machine('truck').first;
    expect(trips.dailyPlan, 20);
    expect(trips.plannedToDate, 160);
    expect(progress.weight(DateTime(2026, 11, 8)), 0);
    expect(progress.machine('truck').last.plannedToDate, 1600);
  });

  test('accumulated plan adds half a day on Saturday and zero on Sunday', () {
    for (final day in [
      ('2026-11-06', 40.0, 200.0),
      ('2026-11-07', 20.0, 220.0),
      ('2026-11-08', 0.0, 220.0),
      ('2026-11-09', 40.0, 260.0),
    ]) {
      final data = snapshot()
        ..['date'] = day.$1
        ..['calendar'] = [];
      final measure = MachineryProgress(data, []).machine('truck').first;
      expect(measure.dailyPlan, day.$2, reason: day.$1);
      expect(measure.plannedToDate, day.$3, reason: day.$1);
    }
  });

  test(
    'saved current crew values are replaced by current form values once',
    () {
      final data = snapshot();
      final first = MachineryProgress(data, entries()).machine('truck').first;
      expect(first.today, 17);
      expect(first.crewToday, 12);
      expect(first.actualToDate, 62);
      final changed = entries()..last['production_value'] = 9;
      expect(
        MachineryProgress(data, changed).machine('truck').first.actualToDate,
        66,
      );
      expect(
        MachineryProgress(data, []).machine('truck').first.actualToDate,
        50,
      );
    },
  );

  test('physical identity survives row reordering and multiple segments', () {
    final data = entries().reversed.toList()
      ..add({
        'project_machinery_id': 'truck',
        'machinery_inspection_id': 'a',
        'production_value': 3,
      });
    final progress = MachineryProgress(snapshot(), data);
    final a = progress.machine('truck', physicalUnit: 'a').first;
    expect(a.actualToDate, 40);
    expect(a.dailyPlan, 10);
    expect(a.plannedToDate, 80);
    expect(progress.machine('truck', physicalUnit: 'b').first.actualToDate, 20);
  });

  test('service preserves incompatible production units separately', () {
    final data = snapshot();
    (data['machinery'] as List).add({
      'id': 'grader',
      'quote_service_id': 'service',
      'unit': 'ACRES',
      'performance_per_day': 3,
      'expected_quantity': 1,
      'start_date': '2026-11-02',
      'end_date': '2026-11-13',
    });
    final measures = MachineryProgress(data, entries()).service('service');
    expect(measures.map((m) => m.unit), ['trips', 'CY', 'ACRES']);
    expect(measures.last.plannedToDate, 12);
    expect(MachineryProgress(data, entries()).service('other'), isEmpty);
  });

  test('separate assignments stop accumulating after their end', () {
    final data = snapshot();
    final m = (data['machinery'] as List).first as Map;
    m['assignments'] = [
      {'start_date': '2026-11-02', 'end_date': '2026-11-02', 'quantity': 1},
      {'start_date': '2026-11-06', 'end_date': '2026-11-06', 'quantity': 1},
    ];
    final measure = MachineryProgress(data, []).machine('truck').first;
    expect(measure.dailyPlan, 0);
    expect(measure.plannedToDate, 40);
  });

  test('missing dates do not invent a one-day plan', () {
    final data = snapshot();
    ((data['machinery'] as List).first as Map)['assignments'] = [];
    final progress = MachineryProgress(data, entries());
    expect(progress.hasPlan('truck'), isFalse);
    expect(progress.machine('truck').first.plannedToDate, 0);
  });

  testWidgets('progress labels and bars fit a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MachineryProgressPanel(
              title: 'Service progress',
              measures: MachineryProgress(
                snapshot(),
                entries(),
              ).machine('truck'),
              note: 'Validated production plus this crew’s current entries.',
            ),
          ),
        ),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('Daily plan:'), findsNothing);
    expect(find.textContaining('To date: 620 / 1600 CY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
