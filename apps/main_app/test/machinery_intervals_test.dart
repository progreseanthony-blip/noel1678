import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_app/src/features/field_operations/presentation/utils/machinery_intervals.dart';
import 'package:noel_app/src/features/field_operations/presentation/widgets/step_machinery.dart';

Map<String, dynamic> segment(String start, String end, {String unit = 'u'}) => {
  'project_machinery_id': 'pm',
  'machinery_id': 'machine',
  'machinery_inspection_id': unit,
  'operator_id': 'worker',
  'operation_start': start,
  'operation_end': end,
  'start_meter': 10,
  'end_meter': 11,
};

final attendance = <Map<String, dynamic>>[
  {'worker_id': 'worker', 'check_in_time': '07:00', 'check_out_time': '12:00'},
  {'worker_id': 'worker', 'check_in_time': '13:00', 'check_out_time': '17:00'},
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('empty machinery refers to the future report date, not today', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StepMachinery(
              projectId: 'p',
              reportDate: '2090-11-02',
              progressSnapshot: const {'scope': 'report'},
              plannedMachinery: const [
                {'id': 'pm', 'machinery_name': 'Dozer', 'expected_quantity': 1},
              ],
              machineryLogs: const [],
              workers: const [],
              deviationReasons: const [],
              laborLogs: const [],
              plannedLabor: const [],
              machineryCatalog: const [],
              isReadOnly: true,
              onLogsChanged: (_) => fail('Consolidated view is read-only'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Dozer (0/1)'));
    await tester.pumpAndSettle();
    expect(find.text('No entry for 2090-11-02'), findsOneWidget);
    expect(find.text('Not registered today'), findsNothing);
    expect(find.text('Add'), findsNothing);
  });
  test('same unit and operator can work consecutive intervals', () {
    final a = segment('07:00', '09:00');
    final b = segment('09:00:00', '11:00:00');
    expect(machineryIntervalError(b, [a, b], attendance), isNull);
  });
  test('assigned operators stay reserved while either interval is invalid', () {
    final assigned = segment('08:00', '17:00');
    for (final times in [
      <String, dynamic>{},
      {'operation_start': '08:00'},
      {'operation_start': '08:00', 'operation_end': '05:00'},
      {'operation_start': '08:00', 'operation_end': '08:00'},
      {'operation_start': '09:00', 'operation_end': '16:00'},
    ]) {
      final candidate = {'machinery_inspection_id': 'other', ...times};
      expect(
        machineryIntervalOccupied(
          candidate,
          [assigned, candidate],
          'operator_id',
          'worker',
        ),
        isTrue,
      );
      expect(
        machineryIntervalOccupied(
          candidate,
          [assigned, candidate],
          'operator_id',
          'free-worker',
        ),
        isFalse,
      );
    }
    final incomplete = {'operator_id': 'worker'};
    expect(
      machineryIntervalOccupied(
        assigned,
        [incomplete, assigned],
        'operator_id',
        'worker',
      ),
      isTrue,
    );
    expect(
      machineryIntervalOccupied(assigned, [assigned], 'operator_id', 'worker'),
      isFalse,
    );
  });
  test('unit and operator overlaps are detected independently', () {
    final a = segment('07:00', '10:00');
    final b = segment('09:00', '11:00');
    expect(
      machineryIntervalError(b, [a, b], attendance),
      contains('physical unit'),
    );
    b['machinery_inspection_id'] = 'other';
    expect(machineryIntervalError(b, [a, b], attendance), contains('operator'));
    a['is_standby'] = true;
    expect(machineryIntervalError(b, [a, b], attendance), isNull);
  });
  test('attendance gaps and open attendance do not cover operations', () {
    final row = segment('11:00', '14:00');
    expect(
      machineryIntervalError(row, [row], attendance),
      contains('attendance'),
    );
    expect(
      operatorAttendanceCovers(row, [
        {'worker_id': 'worker', 'check_in_time': '07:00'},
      ], 'worker'),
      isFalse,
    );
  });
  test(
    'missing physical identity, reversed times and excess meters rejected',
    () {
      final row = segment('09:00', '08:00');
      expect(
        machineryIntervalError(row, [row], attendance),
        contains('same day'),
      );
      row['operation_end'] = '10:00';
      row['machinery_inspection_id'] = null;
      expect(
        machineryIntervalError(row, [row], attendance),
        contains('physical unit'),
      );
      row['machinery_inspection_id'] = 'u';
      row['end_meter'] = 12;
      expect(
        machineryIntervalError(row, [row], attendance),
        contains('meter usage'),
      );
    },
  );
  test('legacy occupied row with unknown times blocks reuse', () {
    final row = segment('09:00', '10:00');
    final legacy = {'project_machinery_id': 'pm', 'operator_id': 'other'};
    expect(
      machineryIntervalError(row, [legacy, row], attendance),
      contains('occupied'),
    );
  });
  testWidgets('single received unit allows more intervals and operator reuse', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    List<Map<String, dynamic>>? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StepMachinery(
              projectId: 'p',
              operationalMode: true,
              isReadOnly: false,
              reportDate: '2026-11-02',
              plannedMachinery: const [
                {
                  'id': 'pm',
                  'machinery_id': 'machine',
                  'machinery_name': 'Dozer',
                  'expected_quantity': 1,
                  'quote_service_id': 's',
                  'quote_services': {'name': 'Clearing'},
                  'machinery_inspections': [
                    {'id': 'u', 'internal_id': 'D1'},
                  ],
                },
              ],
              machineryLogs: [
                segment('07:00', '09:00'),
                {...segment('09:00', '11:00'), 'operator_id': null},
              ],
              workers: const [
                {'id': 'worker', 'full_name': 'Operator A', 'status': 'Active'},
              ],
              laborLogs: attendance,
              plannedLabor: const [],
              machineryCatalog: const [],
              deviationReasons: const [],
              onLogsChanged: (rows) => changed = rows,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    final dropdowns = tester.widgetList<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    final operators = dropdowns.where(
      (d) => d.items!.any((item) => item.value == 'worker'),
    );
    expect(operators.length, 2);
    expect(operators.last.items!.any((item) => item.value == 'worker'), isTrue);
    await tester.ensureVisible(find.text('Add operating interval'));
    await tester.tap(find.text('Add operating interval'));
    await tester.pumpAndSettle();
    expect(changed, hasLength(3));
    expect(changed!.last['machinery_inspection_id'], 'u');
    expect(changed!.last['production_value'], 0);
    expect(changed!.last['operation_start'], isNull);
    final updatedDropdowns = tester.widgetList<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    // The new interval has no times yet, so the already assigned operator
    // must not be offered again. Consecutive complete intervals above can reuse it.
    expect(
      updatedDropdowns.last.items!.any((item) => item.value == 'worker'),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
