import 'package:flutter_test/flutter_test.dart';
import 'package:noel_app/src/features/field_operations/presentation/utils/labor_segments.dart';

Map<String, dynamic> segment(
  String id,
  String start,
  String end, {
  String worker = 'w',
}) => newLaborSegment(
  id: id,
  worker: worker,
  labor: 'labor',
  start: start,
  end: end,
  reason: 'Work',
);

void main() {
  for (final sample in [('10:00', '13:00', 5.5), ('13:00', '19:00', 11.5)]) {
    test(
      'split shifts ${sample.$1}/${sample.$2} deduct only one automatic break',
      () {
        final rows = [
          segment('a', '07:00', sample.$1),
          segment('b', sample.$1, sample.$2),
        ];
        reconcileAutomaticLaborBreaks(rows);
        expect(
          rows.fold<num>(0, (sum, r) => sum + (r['break_minutes'] as num)),
          30,
        );
        expect(
          rows.fold<num>(0, (sum, r) => sum + (r['total_net_hours'] as num)),
          sample.$3,
        );
      },
    );
  }
  test('three hours in another crew complete the six-hour threshold', () {
    final rows = [segment('loan', '10:00', '13:00')];
    reconcileAutomaticLaborBreaks(rows, {
      'w': {'elapsed_minutes': 180, 'fixed_break': 0, 'auto_break': 0},
    });
    expect(rows.single['break_minutes'], 30);
    expect(rows.single['total_net_hours'], 2.5);
  });
  test(
    'return to source credits the break already recorded in the destination',
    () {
      final rows = [
        segment('first', '07:00', '10:00'),
        segment('return', '13:00', '16:00'),
      ];
      reconcileAutomaticLaborBreaks(rows, {
        'w': {'elapsed_minutes': 180, 'auto_break': 30, 'fixed_break': 0},
      });
      expect(rows.map((r) => r['break_minutes']), [0, 0]);
      expect(rows.map((r) => r['total_net_hours']), [3.0, 3.0]);
    },
  );
  test('historical recorded and manual deductions remain intact', () {
    final recorded = {
      ...segment('old', '07:00', '10:00'),
      'break_mode': 'recorded',
      'break_minutes': 45,
      'total_net_hours': 2.25,
    };
    final before = Map<String, dynamic>.from(recorded);
    final rows = [recorded, segment('new', '10:00', '16:00')];
    reconcileAutomaticLaborBreaks(rows);
    expect(recorded, before);
    expect(rows.last['break_minutes'], 0);
  });
  test('shortening below six hours clears only automatic deductions', () {
    final rows = [
      segment('first', '07:00', '10:00'),
      segment('second', '10:00', '13:00'),
    ];
    reconcileAutomaticLaborBreaks(rows);
    rows.last['check_out_time'] = '12:00';
    reconcileAutomaticLaborBreaks(rows);
    expect(rows.map((r) => r['break_minutes']), [0, 0]);
  });
  test('workers have independent daily thresholds', () {
    final rows = [
      segment('a', '07:00', '13:00'),
      segment('b', '07:00', '10:00', worker: 'other'),
    ];
    reconcileAutomaticLaborBreaks(rows);
    expect(rows.map((r) => r['break_minutes']), [30, 0]);
  });
}
