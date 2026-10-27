import 'package:flutter_test/flutter_test.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_app/src/features/projects/presentation/utils/labor_planning_availability.dart';

void main() {
  final labor = <Map<String, dynamic>>[
    {'id': 'a', 'service_key': 'service', 'role_name': 'Foreman'},
    {'id': 'b', 'service_key': 'other', 'role_name': 'Foreman'},
  ];
  final assigned = <Map<String, dynamic>>[
    {
      'id': 'old',
      'project_labor_id': 'a',
      'worker_id': 'old-worker',
      'worker_name': 'Miranda',
      'start_date': '2026-10-25',
      'end_date': '2026-10-29',
    },
  ];
  Map<String, dynamic> request(String worker, String from, String until) => {
    'project_labor_id': 'a',
    'worker_id': worker,
    'worker_name': worker,
    'valid_from': from,
    'valid_until': until,
  };
  test('occupied single slot explains actual worker and interval', () {
    final p = LaborPlanningAvailability(labor, assigned);
    expect(p.available('a', '2026-10-25', '2026-10-29'), 0);
    final error = p.validate([request('Fred', '2026-10-25', '2026-10-29')]);
    expect(error, contains('Miranda'));
    expect(error, contains('2026-10-29'));
  });
  test('dates are inclusive and another service cannot supply a vacancy', () {
    final p = LaborPlanningAvailability(labor, assigned);
    expect(
      p.validate([request('Fred', '2026-10-29', '2026-11-02')]),
      isNotNull,
    );
    expect(p.validate([request('Fred', '2026-10-30', '2026-11-02')]), isNull);
  });
  test(
    'one slot can be reused at different times without deleting history',
    () {
      final p = LaborPlanningAvailability(labor, []);
      expect(
        p.validate([
          request('A', '2026-10-01', '2026-10-03'),
          request('B', '2026-10-04', '2026-10-08'),
        ]),
        isNull,
      );
      expect(
        p.validate([
          request('A', '2026-10-01', '2026-10-03'),
          request('B', '2026-10-03', '2026-10-08'),
        ]),
        isNotNull,
      );
    },
  );
  test(
    'a vacant sibling permits the extra worker while two extra workers exceed it',
    () {
      final p = LaborPlanningAvailability([
        ...labor,
        {'id': 'c', 'service_key': 'service', 'role_name': 'Foreman'},
      ], assigned);
      expect(p.available('a', '2026-10-25', '2026-10-29'), 1);
      expect(p.validate([request('Fred', '2026-10-25', '2026-10-29')]), isNull);
      expect(
        p.validate([
          request('Fred', '2026-10-25', '2026-10-29'),
          request('Other', '2026-10-25', '2026-10-29'),
        ]),
        isNotNull,
      );
    },
  );
  test('overlapping existing worker planning is not duplicated', () {
    final p = LaborPlanningAvailability([
      ...labor,
      {'id': 'c', 'service_key': 'service', 'role_name': 'Foreman'},
    ], assigned);
    expect(
      p.validate([request('old-worker', '2026-10-25', '2026-10-29')]),
      contains('already has an assignment'),
    );
  });
  test(
    'server vacancy error becomes readable without backend exception wrapper',
    () {
      final text = laborPlanningError(
        const PostgrestException(
          message:
              'No planned vacancy covers the full interval for role CONSTRUCTION FORMAN',
          code: 'P0001',
        ),
      );
      expect(text, contains('CONSTRUCTION FORMAN'));
      expect(text, contains('Personnel'));
      expect(text, isNot(contains('PostgrestException')));
      expect(text, isNot(contains('P0001')));
    },
  );
  test(
    'registered counter includes allocations outside the proposed dates',
    () {
      final p = LaborPlanningAvailability(labor, assigned);
      expect(p.registeredSlots('a'), 1);
      expect(p.available('a', '2026-09-07', '2026-09-10'), 1);
      expect(p.registered('a').single['worker_name'], 'Miranda');
      expect(p.registeredSlots('b'), 0);
    },
  );
  test('a reused physical place is counted once in the registered total', () {
    final p = LaborPlanningAvailability(labor, [
      ...assigned,
      {
        'project_labor_id': 'a',
        'worker_id': 'second',
        'start_date': '2026-11-01',
        'end_date': '2026-11-03',
      },
    ]);
    expect(p.registeredSlots('a'), 1);
    expect(p.registered('a'), hasLength(2));
  });
}
