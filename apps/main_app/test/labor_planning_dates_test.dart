import 'package:flutter_test/flutter_test.dart';
import 'package:noel_app/src/features/projects/presentation/utils/labor_planning_dates.dart';

void main() {
  test(
    'project responsibility spans services and preserves saved individual dates',
    () {
      final roles = LaborPlanningDates.coverageRoles([
        {
          'coverage_scope': 'project',
          'reference_start': '2026-10-05',
          'reference_end': '2026-10-06',
          'start_date': '2026-10-07',
          'end_date': '2026-10-09',
        },
        {
          'coverage_scope': 'service',
          'reference_start': '2026-10-08',
          'reference_end': '2026-10-12',
        },
      ], {});
      expect(roles.first['reference_start'], '2026-10-05');
      expect(roles.first['reference_end'], '2026-10-12');
      expect(roles.first['working_days'], 6.5);
      expect(roles.last['reference_start'], '2026-10-08');
      final proposed = LaborPlanningDates.propose(roles.first, {});
      expect(LaborPlanningDates.iso(proposed.start), '2026-10-07');
      expect(LaborPlanningDates.iso(proposed.end), '2026-10-09');
    },
  );
  test('saved role dates take precedence over service reference', () {
    final p = LaborPlanningDates.propose({
      'start_date': '2026-10-12',
      'end_date': '2026-10-20',
      'reference_start': '2026-10-05',
      'reference_end': '2026-10-10',
      'working_days': 5,
    }, {});
    expect(LaborPlanningDates.iso(p.start), '2026-10-12');
    expect(LaborPlanningDates.iso(p.end), '2026-10-20');
  });
  test('service dates are proposed when role has no saved calendar', () {
    final p = LaborPlanningDates.propose({
      'reference_start': '2026-10-05',
      'reference_end': '2026-10-10',
      'working_days': 5,
    }, {});
    expect(LaborPlanningDates.iso(p.start), '2026-10-05');
    expect(LaborPlanningDates.iso(p.end), '2026-10-10');
  });
  test('missing end uses duration and project calendar', () {
    final p = LaborPlanningDates.propose(
      {'reference_start': '2026-10-09', 'working_days': 2},
      {'2026-10-12': 1},
    );
    expect(LaborPlanningDates.iso(p.end), '2026-10-13');
  });
  test('Saturday contributes half a working day', () {
    expect(
      LaborPlanningDates.iso(
        LaborPlanningDates.endFor(DateTime(2026, 10, 9), 1.5, {}),
      ),
      '2026-10-10',
    );
  });
  test(
    'shifted role start recalculates end without reusing obsolete reference end',
    () {
      final p = LaborPlanningDates.propose({
        'start_date': '2026-10-09',
        'reference_start': '2026-10-05',
        'reference_end': '2026-10-06',
        'working_days': 1.5,
      }, {});
      expect(LaborPlanningDates.iso(p.end), '2026-10-10');
    },
  );
  test(
    'a service without calendar does not invent dates from another resource',
    () {
      final p = LaborPlanningDates.propose({}, {});
      expect(p.start, isNull);
      expect(p.end, isNull);
    },
  );
  test('invalid duration never loops or fabricates a date', () {
    expect(
      LaborPlanningDates.endFor(DateTime(2026, 10, 9), double.infinity, {}),
      isNull,
    );
    expect(LaborPlanningDates.endFor(DateTime(2026, 10, 9), 0, {}), isNull);
  });
}
