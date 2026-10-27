import 'package:flutter_test/flutter_test.dart';
import 'package:noel_app/src/features/quotes/presentation/widgets/quote_form_dialog.dart';

void main() {
  List<ServiceEntry> pair({
    int secondStart = 1,
    int secondEnd = 10,
    double firstMonths = 1,
    double secondMonths = 1,
  }) {
    final first = LaborEntry(
      roleName: 'Supervisor',
      operationalRole: 'Supervisor',
      teamResourceId: 'shared',
      teamResourceLabel: 'Supervisor 1',
      monthsToWork: firstMonths,
      hourlyRate: 50,
    );
    final second = LaborEntry(
      roleName: 'Supervisor',
      operationalRole: 'Supervisor',
      teamResourceId: 'shared',
      teamResourceLabel: 'Supervisor 1',
      monthsToWork: secondMonths,
      hourlyRate: 50,
    );
    return [
      ServiceEntry(
        name: 'A',
        labors: [first],
        estimationData: {
          'start_date': DateTime(2026, 11, 1),
          'end_date': DateTime(2026, 11, 10),
        },
      ),
      ServiceEntry(
        name: 'B',
        labors: [second],
        estimationData: {
          'start_date': DateTime(2026, 11, secondStart),
          'end_date': DateTime(2026, 11, secondEnd),
        },
      ),
    ];
  }

  test(
    'full simultaneous coverage counts one resource and allocation is idempotent',
    () {
      final services = pair();
      expect(LeadershipBudget.allocate(services), hasLength(1));
      expect(services.first.labors.single.effectiveMonths, closeTo(0.5, 1e-9));
      expect(services.last.labors.single.effectiveMonths, closeTo(0.5, 1e-9));
      LeadershipBudget.allocate(services);
      expect(
        services.fold<double>(0, (sum, s) => sum + s.totalLabor),
        closeTo(11000, 1e-6),
      );
    },
  );
  test(
    'partial overlap retains full exclusive time; touching end dates overlap',
    () {
      final services = pair(secondStart: 6, secondEnd: 15);
      LeadershipBudget.allocate(services);
      expect(services.first.labors.single.effectiveMonths, closeTo(0.75, 1e-9));
      expect(services.last.labors.single.effectiveMonths, closeTo(0.75, 1e-9));
      final touching = pair(secondStart: 10, secondEnd: 19);
      expect(LeadershipBudget.allocate(touching), hasLength(1));
      expect(touching.first.labors.single.effectiveMonths, closeTo(0.95, 1e-9));
    },
  );
  test('consecutive and disjoint services retain full duration', () {
    for (final start in [11, 20]) {
      final services = pair(secondStart: start, secondEnd: start + 9);
      expect(LeadershipBudget.allocate(services), isEmpty);
      expect(services.first.labors.single.effectiveMonths, closeTo(1, 1e-9));
      expect(services.last.labors.single.effectiveMonths, closeTo(1, 1e-9));
    }
  });
  test(
    'different estimated durations share the largest daily capacity, not their sum',
    () {
      final services = pair(firstMonths: 1, secondMonths: 2);
      LeadershipBudget.allocate(services);
      expect(
        services.first.labors.single.effectiveMonths,
        closeTo(2 / 3, 1e-9),
      );
      expect(services.last.labors.single.effectiveMonths, closeTo(4 / 3, 1e-9));
    },
  );
  test(
    'primary service bears all union cost without removing other coverage',
    () {
      final services = pair(secondStart: 6, secondEnd: 15);
      services.first.labors.single.costPrimary = true;
      LeadershipBudget.allocate(services);
      expect(services.first.labors.single.effectiveMonths, closeTo(1.5, 1e-9));
      expect(services.last.labors.single.effectiveMonths, 0);
      expect(services.last.labors.single.teamResourceId, 'shared');
      services.first.labors.single.costPrimary = false;
      services.last.labors.single.costPrimary = true;
      LeadershipBudget.allocate(services);
      expect(services.first.labors.single.effectiveMonths, 0);
      expect(services.last.labors.single.effectiveMonths, closeTo(1.5, 1e-9));
    },
  );
  test(
    'three concurrent services divide capacity once and independent resources stay separate',
    () {
      final services = pair();
      services.add(
        ServiceEntry(
          name: 'C',
          labors: [
            LaborEntry(
              teamResourceId: 'shared',
              monthsToWork: 1,
              hourlyRate: 50,
            ),
          ],
          estimationData: services.first.estimationData,
        ),
      );
      LeadershipBudget.allocate(services);
      expect(
        services.fold<double>(
          0,
          (sum, s) => sum + s.labors.single.effectiveMonths,
        ),
        closeTo(1, 1e-9),
      );
      services.last.labors.single.teamResourceId = 'independent';
      LeadershipBudget.allocate(services);
      expect(services.last.labors.single.effectiveMonths, closeTo(1, 1e-9));
      services.removeLast();
      services.removeLast();
      LeadershipBudget.allocate(services);
      expect(services.first.labors.single.effectiveMonths, closeTo(1, 1e-9));
    },
  );

  test(
    'shared commitment distinguishes simultaneous and consecutive services',
    () {
      final supervisor = LaborEntry(
        roleName: 'Supervisor',
        operationalRole: 'Supervisor',
        monthsToWork: 1,
        hourlyRate: 50,
      );
      final foreman = LaborEntry(
        roleName: 'Foreman',
        operationalRole: 'Foreman',
        monthsToWork: 1,
        hourlyRate: 40,
      );
      final secondSupervisor = LeadershipBudget.share(supervisor, 1);
      final secondForeman = LeadershipBudget.share(foreman, 1);
      for (final line in [
        supervisor,
        foreman,
        secondSupervisor,
        secondForeman,
      ]) {
        line.dedication = 50;
      }
      final services = [
        ServiceEntry(
          name: 'A',
          labors: [supervisor, foreman],
          estimationData: {
            'start_date': DateTime(2026, 11, 2),
            'end_date': DateTime(2026, 11, 10),
          },
        ),
        ServiceEntry(
          name: 'B',
          labors: [secondSupervisor, secondForeman],
          estimationData: {
            'start_date': DateTime(2026, 11, 2),
            'end_date': DateTime(2026, 11, 10),
          },
        ),
      ];
      expect(LeadershipBudget.validate(services), isNull);
      secondSupervisor.dedication = 100;
      expect(LeadershipBudget.validate(services), isNull);
      expect(LeadershipBudget.allocate(services), hasLength(2));
      expect(supervisor.effectiveMonths, closeTo(0.5, 1e-9));
      expect(secondSupervisor.effectiveMonths, closeTo(0.5, 1e-9));
      services.last.estimationData = {
        'start_date': DateTime(2026, 11, 11),
        'end_date': DateTime(2026, 11, 20),
      };
      expect(LeadershipBudget.validate(services), isNull);
    },
  );
  test('sharing distributes dedication and preserves projected workers', () {
    final projected = LaborEntry(
      roleName: 'TRUCK OPERATOR',
      monthsToWork: 0.6,
      employeesQuantity: 2,
      hourlyRate: 39,
    );
    final source = LaborEntry(
      roleName: 'Superintendent',
      operationalRole: 'Supervisor',
      monthsToWork: 1,
      hourlyRate: 50,
    );
    final shared = LeadershipBudget.share(source, 1);
    final services = [
      ServiceEntry(name: 'A', labors: [projected, source]),
      ServiceEntry(name: 'B', labors: [shared]),
    ];
    source.dedication = 50;
    shared.dedication = 50;
    expect(source.teamResourceId, shared.teamResourceId);
    expect(source.totalFinal + shared.totalFinal, 11000);
    LeadershipBudget.update(services, shared, (line) => line.hourlyRate = 60);
    expect(source.hourlyRate, 60);
    expect(source.totalFinal + shared.totalFinal, 13200);
    expect(projected.operationalRole, 'none');
    expect(projected.monthsToWork, 0.6);
    expect(projected.employeesQuantity, 2);
    expect(projected.totalFinal, 10296);
    services.first.labors.remove(source);
    expect(services.last.labors.single.teamResourceId, shared.teamResourceId);
    expect(shared.totalFinal, 6600);
  });
  test(
    'project coverage and responsibility never duplicate the labor cost',
    () {
      final line = LaborEntry(
        roleName: 'Superintendent',
        monthsToWork: 1,
        employeesQuantity: 2,
        hourlyRate: 50,
      );
      final original = line.totalFinal;
      line.operationalRole = 'Supervisor';
      line.coverageScope = 'project';
      expect(line.totalFinal, original);
      expect(line.totalFinal, 22000);
      line.operationalRole = 'Foreman';
      line.coverageScope = 'service';
      expect(line.totalFinal, original);
    },
  );
}
