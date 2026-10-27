import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_app/src/features/field_operations/presentation/utils/labor_segments.dart';
import 'package:noel_app/src/features/field_operations/presentation/widgets/step_labor.dart';
import 'package:noel_app/src/features/field_operations/presentation/widgets/daily_transfers_panel.dart';

Map<String, dynamic> loan({String status = 'approved'}) => {
  'id': 'loan',
  'worker_id': 'w',
  'worker_name': 'Worker',
  'from_crew_id': 'a',
  'to_crew_id': 'b',
  'from_name': 'Crew A',
  'to_name': 'Crew B',
  'project_labor_id': 'target',
  'starts_at': '10:00:00',
  'ends_at': '12:00:00',
  'reason': 'Temporary assistance',
  'status': status,
  'requested_by': 'foreman',
};
const worker = {
  'id': 'w',
  'full_name': 'Worker',
  'id_number': '1',
  'status': 'Active',
};
List<Map<String, dynamic>> plans() => [
  {
    'id': 'target',
    'role_name': 'Operator',
    'expected_employees': 1,
    'quote_services': {'name': 'Clearing'},
    'project_labor_assignments': [],
  },
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test(
    'borrowed workers appear under the destination service without changing planning',
    () {
      final original = plans();
      final result = withBorrowedWorkers(
        original,
        [worker],
        [loan()],
        'b',
        '2026-11-02',
      );
      expect(result.single['project_labor_assignments'], hasLength(1));
      expect(original.single['project_labor_assignments'], isEmpty);
      expect(
        withBorrowedWorkers(
          original,
          [worker],
          [loan(status: 'pending')],
          'b',
          '2026-11-02',
        ).single['project_labor_assignments'],
        isEmpty,
      );
      expect(
        withBorrowedWorkers(
          result,
          [worker],
          [loan()],
          'b',
          '2026-11-02',
        ).single['project_labor_assignments'],
        hasLength(1),
      );
    },
  );
  test(
    'adjacent segments are allowed while open or overlapping attendance blocks reassignment',
    () {
      final row = newLaborSegment(
        id: 'first',
        worker: 'w',
        labor: 'target',
        start: '07:00',
        end: '10:00',
        reason: 'Origin',
      );
      expect(overlapsSegment(row, 'w', '10:00', '12:00'), isFalse);
      expect(overlapsSegment(row, 'w', '09:30', '12:00'), isTrue);
      expect(
        overlapsSegment(
          {...row, 'check_out_time': null},
          'w',
          '10:00',
          '12:00',
        ),
        isTrue,
      );
      expect(
        () => newLaborSegment(
          id: 'bad',
          worker: 'w',
          labor: 'target',
          start: '18:00',
          end: '07:00',
          reason: 'Invalid',
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'new segment preserves authorized loan and calculates its net hours',
    () {
      final row = newLaborSegment(
        id: 'new',
        worker: 'w',
        labor: 'target',
        start: '10:00',
        end: '12:00',
        reason: 'Loan',
        transfer: 'loan',
      );
      expect(row['transfer_id'], 'loan');
      expect(row['total_net_hours'], 2);
      expect(row['break_minutes'], 0);
    },
  );

  Future<void> showLabor(
    WidgetTester tester,
    List<Map<String, dynamic>> rows,
    ValueChanged<List<Map<String, dynamic>>> changed, {
    Future<void> Function(Map<String, dynamic>)? reassign,
    List<Map<String, dynamic>>? loans,
  }) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StepLabor(
              plannedLabor: withBorrowedWorkers(
                plans(),
                [worker],
                [loan()],
                'b',
                '2026-11-02',
              ),
              laborLogs: rows,
              workers: const [worker],
              deviationReasons: const [],
              isReadOnly: false,
              onLogsChanged: changed,
              executionCrewId: 'b',
              transfers: loans ?? [loan()],
              onReassign: reassign,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'destination initializes the authorized interval and loan identity',
    (tester) async {
      List<Map<String, dynamic>>? emitted;
      await showLabor(tester, [], (rows) => emitted = rows);
      await tester.tap(find.text('Add all'));
      await tester.pumpAndSettle();
      expect(emitted!.single['transfer_id'], 'loan');
      expect(emitted!.single['check_in_time'], '10:00:00');
      expect(emitted!.single['check_out_time'], '12:00:00');
      expect(find.text('Table'), findsOneWidget);
    },
  );
  for (final table in [false, true]) testWidgets('a second authorized interval can be added for the same worker (table: $table)', (
    tester,
  ) async {
    List<Map<String, dynamic>>? emitted;
    await showLabor(
      tester,
      [],
      (rows) => emitted = rows,
      loans: [
        loan(),
        {
          ...loan(),
          'id': 'second',
          'starts_at': '13:00:00',
          'ends_at': '14:00:00',
        },
      ],
    );
    await tester.tap(find.text('Add all'));
    await tester.pumpAndSettle();
    if (table) {
      await tester.tap(find.text('Table'));
      await tester.pumpAndSettle();
    }
    await tester.tap(table ? find.byTooltip('Add authorized segment') : find.text('Add authorized segment'));
    await tester.pumpAndSettle();
    expect(emitted!.map((r) => r['transfer_id']), ['loan', 'second']);
  });

  testWidgets(
    'return to the same service displays both IDs and reassigns the chosen segment',
    (tester) async {
      Map<String, dynamic>? selected;
      final rows = [
        newLaborSegment(
          id: 'first',
          worker: 'w',
          labor: 'target',
          start: '07:00',
          end: '10:00',
          reason: 'First',
        ),
        newLaborSegment(
          id: 'return',
          worker: 'w',
          labor: 'target',
          start: '12:00',
          end: '16:00',
          reason: 'Return',
        ),
      ];
      await showLabor(
        tester,
        rows,
        (_) {},
        reassign: (row) async {
          selected = row;
        },
      );
      await tester.tap(find.text('Operator (1/1)'));
      await tester.pumpAndSettle();
      expect(find.text('07:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
      await tester.tap(find.text('Reassign').last);
      await tester.pumpAndSettle();
      expect(selected!['id'], 'return');
    },
  );
  testWidgets(
    'Foreman can cancel own pending request but cannot authorize it',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyTransfersPanel(
              transfers: [loan(status: 'pending')],
              canReview: false,
              readOnly: false,
              currentUser: 'foreman',
              onAction: (_, __) {},
            ),
          ),
        ),
      );
      expect(find.byTooltip('Authorize loan'), findsNothing);
      expect(find.byTooltip('Cancel loan'), findsOneWidget);
    },
  );
}
