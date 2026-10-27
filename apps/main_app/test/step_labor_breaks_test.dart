import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_app/src/features/field_operations/presentation/widgets/step_labor.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final sample in [
    ('12:59:00', 0, 359 / 60, 0.0),
    ('13:00:00', 30, 5.5, 0.0),
    ('15:30:00', 30, 8.0, 0.0),
    ('16:00:00', 30, 8.5, 0.5),
  ]) {
    testWidgets('automatic break and net hours for 07:00 to ${sample.$1}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      List<Map<String, dynamic>>? emitted;
      final worker = {
        'id': 'worker',
        'full_name': 'Test Worker',
        'id_number': '1',
        'status': 'Active',
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StepLabor(
                plannedLabor: [
                  {
                    'id': 'labor',
                    'role_name': 'Operator',
                    'expected_employees': 1,
                    'project_labor_assignments': [
                      {'workers': worker},
                    ],
                    'quote_services': const {'name': 'Clearing'},
                  },
                ],
                laborLogs: [
                  {
                    'worker_id': 'worker',
                    'project_labor_id': 'labor',
                    'check_in_time': '07:00:00',
                    'check_out_time': sample.$1,
                    // Cover both missing deductions and a shortened shift
                    // that must clear a previously calculated deduction.
                    'break_minutes': sample.$2 == 0 ? 30 : 0,
                    'total_net_hours': 0.0,
                    'regular_hours': 0.0,
                    'overtime_hours': 0.0,
                  },
                ],
                workers: [worker],
                deviationReasons: const [],
                isReadOnly: false,
                onLogsChanged: (rows) => emitted = rows,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Operator (1/1)'));
      await tester.pumpAndSettle();
      final checkOut = find.text(sample.$1.substring(0, 5));
      await tester.ensureVisible(checkOut);
      await tester.tap(checkOut);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final row = emitted!.single;
      expect(row['break_minutes'], sample.$2);
      expect(row['total_net_hours'], closeTo(sample.$3, 0.0001));
      expect(row['regular_hours'], closeTo(sample.$3.clamp(0, 8), 0.0001));
      expect(row['overtime_hours'], sample.$4);
    });
  }
}
