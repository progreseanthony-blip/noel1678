import 'package:flutter_test/flutter_test.dart';
import 'package:noel_app/src/features/projects/presentation/utils/project_access_periods.dart';

void main() {
  test('latest estimate wins and a linked live service is listed once', () {
    final periods = ProjectAccessPeriod.fromSources(
      quoted: [
        {
          'id': 'q',
          'name': 'Original name',
          'quote_service_estimations': [
            {
              'id': 'old',
              'updated_at': '2026-10-01',
              'start_date': '2026-10-01',
              'end_date': '2026-10-10',
            },
            {
              'id': 'new',
              'updated_at': '2026-10-20',
              'start_date': '2026-11-02T00:00:00Z',
              'end_date': '2026-11-19T00:00:00Z',
              'total_working_days': 16,
            },
          ],
        },
      ],
      live: [
        {'id': 'p', 'quote_service_id': 'q', 'name': 'Clearing'},
      ],
      tasks: [
        {
          'quote_service_id': 'q',
          'planned_start_date': '2026-12-01',
          'planned_end_date': '2026-12-30',
        },
      ],
    );
    expect(periods, hasLength(1));
    expect(periods.single.name, 'Clearing');
    expect(periods.single.start, DateTime(2026, 11, 2));
    expect(periods.single.end, DateTime(2026, 11, 19));
    expect(periods.single.workingDays, 16);
    expect(periods.single.fromEstimate, isTrue);
  });

  test('services without estimates use the full service task period', () {
    final periods = ProjectAccessPeriod.fromSources(
      quoted: [],
      live: [
        {'id': 'co', 'name': 'CO service'},
      ],
      tasks: [
        {
          'project_service_id': 'co',
          'planned_start_date': '2026-12-05',
          'planned_end_date': '2026-12-10',
        },
        {
          'project_service_id': 'co',
          'planned_start_date': '2026-12-01',
          'planned_end_date': '2026-12-20',
        },
        {
          'project_service_id': 'other',
          'planned_start_date': '2025-01-01',
          'planned_end_date': '2027-01-01',
        },
      ],
    );
    expect(periods.single.start, DateTime(2026, 12, 1));
    expect(periods.single.end, DateTime(2026, 12, 20));
    expect(periods.single.fromEstimate, isFalse);
  });

  test(
    'missing service dates remain unknown; access spans known references',
    () {
      final periods = ProjectAccessPeriod.fromSources(
        quoted: [
          {
            'id': 'a',
            'name': 'A',
            'quote_service_estimations': {
              'start_date': '2026-11-02',
              'end_date': '2026-11-10',
            },
          },
          {
            'id': 'b',
            'name': 'B',
            'quote_service_estimations': {
              'start_date': '2026-11-08',
              'end_date': '2026-11-25',
            },
          },
          {'id': 'c', 'name': 'C'},
        ],
        live: [],
        tasks: [],
      );
      expect(ProjectAccessPeriod.firstStart(periods), DateTime(2026, 11, 2));
      expect(ProjectAccessPeriod.lastEnd(periods), DateTime(2026, 11, 25));
      expect(periods.last.start, isNull);
      expect(periods.last.end, isNull);
      expect(ProjectAccessPeriod.firstStart([]), isNull);
    },
  );
}
