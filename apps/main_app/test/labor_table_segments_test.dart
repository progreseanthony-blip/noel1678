import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_app/src/features/field_operations/presentation/widgets/step_labor.dart';

const worker = {'id': 'w', 'full_name': 'Worker', 'status': 'Active'};
Map<String, dynamic> segment(
  String id,
  String start,
  String? end, {
  String plan = 'p',
  bool unplanned = false,
}) => {
  'id': id,
  'worker_id': 'w',
  'project_labor_id': plan,
  'check_in_time': start,
  'check_out_time': end,
  'regular_hours': 2.0,
  'overtime_hours': 0.0,
  'total_net_hours': 2.0,
  'break_minutes': 0,
  'is_unplanned': unplanned,
};

Future<void> showLabor(
  WidgetTester tester, {
  required List<Map<String, dynamic>> rows,
  required ValueChanged<List<Map<String, dynamic>>> changed,
  Future<void> Function(Map<String, dynamic>)? reassign,
  double width = 1400,
  bool readOnly = false,
}) async {
  tester.view.physicalSize = Size(width, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StepLabor(
            executionCrewId: 'crew',
            isReadOnly: readOnly,
            plannedLabor: [
              for (final plan in ['p', 'other'])
                {
                  'id': plan,
                  'role_name': 'Operator',
                  'expected_employees': 1,
                  'quote_services': {
                    'name': plan == 'p' ? 'Clearing' : 'Topsoil',
                  },
                  'project_labor_assignments': [
                    {'workers': worker},
                  ],
                },
            ],
            laborLogs: rows,
            workers: const [worker],
            deviationReasons: const [],
            onLogsChanged: changed,
            onReassign: reassign,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Table'));
  await tester.pumpAndSettle();
}

Finder row(String id) => find.byKey(ValueKey('entry:$id'));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'bulk time changes only the selected segment of the same worker',
    (tester) async {
      List<Map<String, dynamic>>? changed;
      await showLabor(
        tester,
        rows: [
          segment('first', '07:00:00', '09:00:00'),
          segment('return', '10:00:00', '12:00:00', unplanned: true),
          segment('other-service', '13:00:00', '16:00:00', plan: 'other'),
        ],
        changed: (rows) => changed = rows,
      );
      expect(row('first'), findsOneWidget);
      expect(row('return'), findsOneWidget);
      expect(row('other-service'), findsOneWidget);
      await tester.tap(
        find.descendant(of: row('return'), matching: find.byType(Checkbox)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '17:00'));
      await tester.pumpAndSettle();
      expect(changed!.map((r) => r['id']), [
        'first',
        'return',
        'other-service',
      ]);
      expect(changed![0]['check_out_time'], '09:00:00');
      expect(changed![1]['check_out_time'], '17:00:00');
      expect(changed![1]['break_minutes'], 30);
      expect(changed![1]['total_net_hours'], 6.5);
      expect(changed![2]['check_out_time'], '16:00:00');
      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Table'));
      await tester.pumpAndSettle();
      expect(find.text('17:00').last, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [1400.0, 400.0]) {
    testWidgets(
      'reassign and removal target the correct segment at width $width',
      (tester) async {
        Map<String, dynamic>? reassigned;
        List<Map<String, dynamic>>? changed;
        await showLabor(
          tester,
          width: width,
          rows: [
            segment('first', '07:00:00', '09:00:00'),
            {
              ...segment('return', '10:00:00', '12:00:00'),
              'transfer_id': 'loan',
            },
          ],
          changed: (rows) => changed = rows,
          reassign: (entry) async => reassigned = entry,
        );
        final action = find.descendant(
          of: row('return'),
          matching: find.byTooltip('Reassign segment'),
        );
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(reassigned!['id'], 'return');
        expect(reassigned!['transfer_id'], 'loan');
        final remove = find.descendant(
          of: row('first'),
          matching: find.byTooltip('Remove segment'),
        );
        await tester.ensureVisible(remove);
        await tester.tap(remove);
        await tester.pumpAndSettle();
        expect(changed, hasLength(1));
        expect(changed!.single['id'], 'return');
        expect(row('return'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'missing filter and select all operate on visible segments only',
    (tester) async {
      List<Map<String, dynamic>>? changed;
      await showLabor(
        tester,
        rows: [
          segment('first', '07:00:00', '09:00:00'),
          segment('return', '10:00:00', null),
          segment('other-service', '13:00:00', '16:00:00', plan: 'other'),
        ],
        changed: (rows) => changed = rows,
      );
      await tester.tap(find.text('Missing'));
      await tester.pumpAndSettle();
      expect(row('first'), findsNothing);
      expect(row('return'), findsOneWidget);
      expect(row('other-service'), findsNothing);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '15:30'));
      await tester.pumpAndSettle();
      expect(changed![0]['check_out_time'], '09:00:00');
      expect(changed![1]['check_out_time'], '15:30:00');
      expect(changed![2]['check_out_time'], '16:00:00');
    },
  );

  testWidgets('read-only table keeps every segment and offers no mutations', (
    tester,
  ) async {
    await showLabor(
      tester,
      readOnly: true,
      rows: [
        segment('first', '07:00:00', '09:00:00'),
        segment('return', '10:00:00', '12:00:00'),
      ],
      changed: (_) => fail('Read-only view must not write'),
    );
    expect(row('first'), findsOneWidget);
    expect(row('return'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byTooltip('Reassign segment'), findsNothing);
    expect(find.byTooltip('Remove segment'), findsNothing);
  });
}
