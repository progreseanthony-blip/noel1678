import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_app/src/features/projects/presentation/widgets/labor_crew_panel.dart';

Map<String, dynamic> snapshot({String status = 'active'}) => {
  'project': {'id': 'project', 'status': status},
  'labor': [
    <String, dynamic>{
      'id': 'labor-a',
      'service_key': 'q:service',
      'service_name': 'Drenaje',
      'role_id': 'role-a',
      'role_name': 'Operador',
      'start_date': '2026-10-01',
      'end_date': '2026-10-25',
    },
    {
      'id': 'labor-b',
      'service_key': 'q:service',
      'service_name': 'Drenaje',
      'role_id': 'role-b',
      'role_name': 'Ayudante',
      'start_date': '2026-10-01',
      'end_date': '2026-10-25',
    },
    <String, dynamic>{
      'id': 'vacant-a',
      'service_key': 'q:service',
      'service_name': 'Drenaje',
      'role_id': 'role-a',
      'role_name': 'Operador',
      'start_date': '2026-10-01',
      'end_date': '2026-10-25',
    },
    <String, dynamic>{
      'id': 'vacant-b',
      'service_key': 'q:service',
      'service_name': 'Drenaje',
      'role_id': 'role-b',
      'role_name': 'Ayudante',
      'start_date': '2026-10-01',
      'end_date': '2026-10-25',
    },
    {
      'id': 'labor-c',
      'service_key': 'p:co',
      'service_name': 'CO',
      'role_name': 'Ayudante',
    },
  ],
  'assignments': [
    {
      'id': 'assignment-a',
      'worker_id': 'worker-a',
      'worker_name': 'Ana',
      'project_labor_id': 'labor-a',
      'role_name': 'Operador',
      'service_key': 'q:service',
      'start_date': '2026-10-01',
      'end_date': '2026-10-20',
    },
    {
      'id': 'assignment-b',
      'worker_id': 'worker-b',
      'worker_name': 'Luis',
      'project_labor_id': 'labor-b',
      'role_name': 'Ayudante',
      'service_key': 'q:service',
      'start_date': '2026-10-05',
      'end_date': '2026-10-25',
    },
  ],
  'workers': [
    <String, dynamic>{
      'id': 'new-worker',
      'full_name': 'Pedro',
      'role_id': 'role-a',
      'role_name': 'Operador',
    },
  ],
  'foremen': [
    {'id': 'foreman', 'name': 'Carlos', 'valid_from': '2026-01-01'},
  ],
  'crews': [],
  'members': [],
  'leaders': [],
  'periods': [],
};

class FakePlanning extends LaborCrewPlanningService {
  FakePlanning() : super(SupabaseClient('http://localhost', 'test-key'));
  Map<String, dynamic> data = snapshot();
  final calls = <Map<String, dynamic>>[];
  final changes = <Map<String, dynamic>>[];
  @override
  Future<void> changeWorker(
    String id,
    String action,
    String? until,
    String reason,
  ) async {
    changes.add({'id': id, 'action': action, 'until': until, 'reason': reason});
    if (fail) throw StateError('Cambio rechazado');
  }

  @override
  Future<void> changeForeman(
    String id,
    String profile,
    String mode,
    String? from,
    String reason,
  ) async {
    changes.add({
      'id': id,
      'profile': profile,
      'mode': mode,
      'from': from,
      'reason': reason,
    });
    if (fail) throw StateError('Cambio rechazado');
  }

  bool fail = false;
  @override
  Future<Map<String, dynamic>> load(String projectId) async => data;
  final requests = <String>[];
  Set<String> busy = {};
  Set<String> Function(String from, String until)? busyForPeriod;
  bool availabilityFails = false;
  @override
  Future<List<Map<String, dynamic>>> workerBookings(
    String projectId,
    String from,
    String until,
  ) async => (await busyWorkers(projectId, from, until))
      .map(
        (id) => <String, dynamic>{
          'worker_id': id,
          'project_title': 'Otra obra de prueba',
          'role_name': 'Operador',
          'start_date': from,
          'end_date': until,
        },
      )
      .toList();
  @override
  Future<Set<String>> busyWorkers(
    String projectId,
    String from,
    String until,
  ) async {
    requests.add('$from/$until');
    if (availabilityFails) throw StateError('Disponibilidad no accesible');
    return busyForPeriod?.call(from, until) ?? busy;
  }

  @override
  Future<void> save({
    required String projectId,
    required String serviceKey,
    required List<Map<String, dynamic>> rows,
    String? crewId,
    String? crewName,
    String? foremanId,
  }) async {
    calls.add({
      'service': serviceKey,
      'rows': rows,
      'crew': crewId,
      'name': crewName,
      'foreman': foremanId,
    });
    if (fail) throw StateError('Conflicto de vigencias');
  }
}

Future<void> openDialog(
  WidgetTester tester,
  FakePlanning api, {
  bool newPeople = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => LaborCrewDialog(
                projectId: 'project',
                serviceKey: 'q:service',
                data: api.data,
                initialRows: newPeople
                    ? []
                    : List<Map<String, dynamic>>.from(
                        api.data['assignments'] as List,
                      ),
                newPeople: newPeople,
                service: api,
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

Future<void> chooseForeman(WidgetTester tester) async {
  final dropdown = find.byType(DropdownButtonFormField<String>).last;
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Carlos').last);
  await tester.pumpAndSettle();
}

Future<void> acceptCurrentRole(WidgetTester tester) async {
  final accept = find.byKey(const ValueKey('accept-role'));
  await tester.ensureVisible(accept);
  await tester.tap(accept);
  await tester.pumpAndSettle();
}

Future<void> changeRole(WidgetTester tester, String name) async {
  final role = find.byType(DropdownButtonFormField<String>).first;
  await tester.ensureVisible(role);
  await tester.tap(role);
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('$name ·').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('covered service reuses the original shared personnel slot', (
    tester,
  ) async {
    final api = FakePlanning();
    for (final l in api.data['labor'] as List) {
      if (['labor-a', 'vacant-a'].contains(l['id'])) {
        l['team_resource_id'] = 'shared';
        l['team_resource_label'] = 'Foreman 1';
        l['operational_role'] = 'Foreman';
      }
    }
    api.data['shared_team_resources'] = [
      {
        'resource_id': 'shared',
        'label': 'Foreman 1',
        'responsibility': 'Foreman',
        'owner_service_key': 'q:service',
        'slots': ['labor-a', 'vacant-a'],
        'services': [
          {
            'service_key': 'q:service',
            'name': 'Drenaje',
            'start_date': '2026-10-01',
            'end_date': '2026-10-20',
            'dedication': 50,
          },
          {
            'service_key': 'p:co',
            'name': 'CO',
            'start_date': '2026-10-01',
            'end_date': '2026-10-20',
            'dedication': 50,
          },
        ],
      },
    ];
    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LaborCrewPanel(
            projectId: 'project',
            service: api,
            serviceFilter: 'CO',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Foreman 1 · Foreman'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    await tester.tap(find.text('Asignar personal al recurso compartido'));
    await tester.pumpAndSettle();
    final dialog = tester.widget<LaborCrewDialog>(find.byType(LaborCrewDialog));
    expect(dialog.serviceKey, 'q:service');
    expect(dialog.onlyTeamResourceId, 'shared');
    expect(find.text('Crew'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('finish worker uses selected assignment and explicit last day', (
    tester,
  ) async {
    final api = FakePlanning();
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LaborCrewPanel(projectId: 'project', service: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Modificar asignación').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar asignación al servicio'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '2026-10-09');
    await tester.enterText(
      find.byType(TextFormField).last,
      'Trabajo terminado',
    );
    await tester.tap(find.text('Guardar cambio'));
    await tester.pumpAndSettle();
    expect(api.changes.single, {
      'id': 'assignment-a',
      'action': 'finish',
      'until': '2026-10-09',
      'reason': 'Trabajo terminado',
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('Foreman correction keeps original period and asks for reason', (
    tester,
  ) async {
    final api = FakePlanning();
    api.data['crews'] = [
      {'id': 'crew', 'name': 'Cuadrilla A'},
    ];
    api.data['periods'] = [
      {
        'id': 'period',
        'crew_id': 'crew',
        'service_key': 'q:service',
        'valid_from': '2026-10-01',
        'valid_until': '2026-10-20',
      },
    ];
    api.data['leaders'] = [
      {
        'id': 'leader',
        'crew_id': 'crew',
        'profile_id': 'foreman',
        'name': 'Carlos',
        'valid_from': '2026-10-01',
        'valid_until': '2026-10-20',
      },
    ];
    (api.data['foremen'] as List).add({'id': 'new-foreman', 'name': 'Elena'});
    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LaborCrewPanel(projectId: 'project', service: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuadrillas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cambiar Foreman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corregir Foreman asignado'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elena').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambio'));
    await tester.pumpAndSettle();
    expect(api.changes, isEmpty);
    await tester.enterText(
      find.byType(TextFormField).last,
      'Error de selección',
    );
    await tester.tap(find.text('Guardar cambio'));
    await tester.pumpAndSettle();
    expect(api.changes.single, {
      'id': 'leader',
      'profile': 'new-foreman',
      'mode': 'correct',
      'from': null,
      'reason': 'Error de selección',
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'budgeted Foreman cannot be selected without linked active user',
    (tester) async {
      final api = FakePlanning();
      for (final l in api.data['labor'] as List) {
        if (['labor-a', 'vacant-a'].contains(l['id']))
          l['operational_role'] = 'Foreman';
      }
      await openDialog(tester, api, newPeople: true);
      await tester.ensureVisible(find.text('Pedro'));
      final tile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Pedro'),
      );
      expect(tile.onChanged, isNull);
      expect(find.textContaining('Requires an active linked'), findsOneWidget);
      expect(api.calls, isEmpty);
    },
  );

  testWidgets(
    'matching trade appears first and another trade can fill its vacancy',
    (tester) async {
      final api = FakePlanning();
      (api.data['workers'] as List).insert(0, {
        'id': 'other-worker',
        'full_name': 'Aaron',
        'role_id': 'role-b',
        'role_name': 'Ayudante',
      });
      await openDialog(tester, api, newPeople: true);
      await tester.ensureVisible(find.text('Pedro'));
      expect(
        tester.getTopLeft(find.text('Pedro')).dy,
        lessThan(tester.getTopLeft(find.text('Aaron')).dy),
      );
      await tester.tap(find.text('Aaron'));
      await tester.pumpAndSettle();
      await acceptCurrentRole(tester);
      expect(find.text('Trade: Operador'), findsOneWidget);
      await tester.tap(find.text('Save Personnel and Crew'));
      await tester.pumpAndSettle();
      final row = (api.calls.single['rows'] as List).single;
      expect(row['worker_id'], 'other-worker');
      expect(row['project_labor_id'], 'labor-a');
      expect((api.data['workers'] as List).first['role_name'], 'Ayudante');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shared service filter updates personnel and clears selection', (
    tester,
  ) async {
    final api = FakePlanning();
    (api.data['assignments'] as List).add({
      'id': 'assignment-c',
      'worker_id': 'worker-c',
      'worker_name': 'Eva',
      'project_labor_id': 'labor-c',
      'role_name': 'Ayudante',
      'service_key': 'p:co',
      'start_date': '2026-10-01',
      'end_date': '2026-10-20',
    });
    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Widget page(String filter) => MaterialApp(
      home: Scaffold(
        body: LaborCrewPanel(
          projectId: 'project',
          service: api,
          serviceFilter: filter,
        ),
      ),
    );
    await tester.pumpWidget(page('Drenaje'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Eva'), findsNothing);
    await tester.tap(find.text('Seleccionar disponibles'));
    await tester.pumpAndSettle();
    expect(find.text('2 seleccionados'), findsOneWidget);
    await tester.pumpWidget(page('CO'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsNothing);
    expect(find.text('Eva'), findsOneWidget);
    expect(find.text('0 seleccionados'), findsOneWidget);
    await tester.pumpWidget(page('All Services'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Eva'), findsOneWidget);
    expect(find.text('Servicio'), findsOneWidget);
    await tester.tap(find.text('Seleccionar disponibles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asignar cuadrilla'));
    await tester.pumpAndSettle();
    expect(find.byType(LaborCrewDialog), findsNothing);
    expect(
      find.textContaining('Selecciona trabajadores de un solo servicio'),
      findsOneWidget,
    );
    await tester.tap(find.text('Agregar personal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CO').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<LaborCrewDialog>(find.byType(LaborCrewDialog)).serviceKey,
      'p:co',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi selection across trades inherits each source period', (
    tester,
  ) async {
    final api = FakePlanning();
    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LaborCrewPanel(projectId: 'project', service: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seleccionar disponibles'));
    await tester.pumpAndSettle();
    expect(find.text('2 seleccionados'), findsOneWidget);
    await tester.tap(find.text('Asignar cuadrilla'));
    await tester.pumpAndSettle();
    final dialog = tester.widget<LaborCrewDialog>(find.byType(LaborCrewDialog));
    expect(dialog.initialRows.map((r) => r['id']), [
      'assignment-a',
      'assignment-b',
    ]);
    expect(dialog.initialRows.map((r) => r['start_date']), [
      '2026-10-01',
      '2026-10-05',
    ]);
    expect(dialog.initialRows.map((r) => r['end_date']), [
      '2026-10-20',
      '2026-10-25',
    ]);
    expect(api.calls, isEmpty);
  });
  testWidgets('one atomic save preserves source IDs and individual dates', (
    tester,
  ) async {
    final api = FakePlanning();
    await openDialog(tester, api);
    await tester.enterText(
      find.byKey(const ValueKey('crew-name')),
      'Cuadrilla A',
    );
    await chooseForeman(tester);
    await tester.tap(find.text('Save Personnel and Crew'));
    await tester.pumpAndSettle();
    expect(api.calls, hasLength(1));
    final call = api.calls.single;
    expect(call['service'], 'q:service');
    expect(call['foreman'], 'foreman');
    expect((call['rows'] as List).map((r) => r['assignment_id']), [
      'assignment-a',
      'assignment-b',
    ]);
    expect((call['rows'] as List).map((r) => r['valid_from']), [
      '2026-10-01',
      '2026-10-05',
    ]);
    expect(find.byType(LaborCrewDialog), findsNothing);
  });
  testWidgets('failed save keeps draft and selection open', (tester) async {
    final api = FakePlanning()..fail = true;
    await openDialog(tester, api);
    await tester.enterText(
      find.byKey(const ValueKey('crew-name')),
      'Cuadrilla A',
    );
    await chooseForeman(tester);
    await tester.tap(find.text('Save Personnel and Crew'));
    await tester.pumpAndSettle();
    expect(find.byType(LaborCrewDialog), findsOneWidget);
    expect(find.textContaining('Conflicto de vigencias'), findsOneWidget);
    expect(api.calls, hasLength(1));
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Luis'), findsOneWidget);
  });
  testWidgets(
    'new personnel inherits role dates and can be planned without a crew',
    (tester) async {
      final api = FakePlanning();
      await openDialog(tester, api, newPeople: true);
      await tester.ensureVisible(find.text('Pedro'));
      await tester.tap(find.text('Pedro'));
      await tester.pumpAndSettle();
      await acceptCurrentRole(tester);
      await tester.tap(find.text('Save Personnel and Crew'));
      await tester.pumpAndSettle();
      expect(api.calls, hasLength(1));
      final row = (api.calls.single['rows'] as List).single;
      expect(row['worker_id'], 'new-worker');
      expect(row['project_labor_id'], 'labor-a');
      expect(row['valid_from'], '2026-10-01');
      expect(row['valid_until'], '2026-10-25');
      expect(api.calls.single['crew'], isNull);
    },
  );
  testWidgets('completed planning only permits consultation', (tester) async {
    final api = FakePlanning()..data = snapshot(status: 'completed');
    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LaborCrewPanel(projectId: 'project', service: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Agregar personal'), findsNothing);
    expect(find.text('Asignar cuadrilla'), findsNothing);
    expect(find.textContaining('Planificación en consulta'), findsOneWidget);
    await tester.tap(find.text('Cuadrillas'));
    await tester.pumpAndSettle();
    expect(api.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'service reference fills a new assignment when role dates are absent',
    (tester) async {
      final api = FakePlanning();
      final role = (api.data['labor'] as List).first as Map<String, dynamic>;
      role.remove('start_date');
      role.remove('end_date');
      role.addAll({
        'reference_start': '2026-11-02',
        'reference_end': '2026-11-14',
        'working_days': 10,
        'reference_source': 'estimation',
      });
      await openDialog(tester, api, newPeople: true);
      expect(find.text('ESTIMATED PERIOD (REFERENCE)'), findsOneWidget);
      await tester.ensureVisible(find.text('Pedro'));
      await tester.tap(find.text('Pedro'));
      await tester.pumpAndSettle();
      await acceptCurrentRole(tester);
      await tester.tap(find.text('Save Personnel and Crew'));
      await tester.pumpAndSettle();
      final row = (api.calls.single['rows'] as List).single;
      expect(row['valid_from'], '2026-11-02');
      expect(row['valid_until'], '2026-11-14');
    },
  );
  testWidgets(
    'mobile modal keeps footer and fields usable with keyboard insets',
    (tester) async {
      final api = FakePlanning();
      await tester.binding.setSurfaceSize(const Size(390, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          home: LaborCrewDialog(
            projectId: 'project',
            serviceKey: 'q:service',
            data: api.data,
            initialRows: [],
            newPeople: true,
            service: api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text('Save Personnel and Crew').hitTestable(),
        findsOneWidget,
      );
      final end = find.byKey(const ValueKey('common-end'));
      await tester.ensureVisible(end);
      await tester.pumpAndSettle();
      expect(end.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('desktop external labels remain clear of input fields', (
    tester,
  ) async {
    final api = FakePlanning();
    final r = (api.data['labor'] as List).first as Map<String, dynamic>;
    r.addAll({
      'reference_start': '2026-10-01',
      'reference_end': '2026-10-25',
      'working_days': 19.5,
      'reference_source': 'estimation',
    });
    await tester.binding.setSurfaceSize(const Size(1100, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const boundaryKey = ValueKey('modal-preview');
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          home: LaborCrewDialog(
            projectId: 'project',
            serviceKey: 'q:service',
            data: api.data,
            initialRows: [],
            newPeople: true,
            service: api,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final label = find.text('Planned trade');
    expect(
      tester
          .getSize(find.byKey(const ValueKey('labor-period-reference')))
          .height,
      lessThan(100),
    );
    expect(
      tester.getSize(find.byType(CheckboxListTile).first).height,
      lessThanOrEqualTo(64),
    );
    final input = find.byType(DropdownButtonFormField<String>).first;
    expect(
      tester.getBottomLeft(label).dy,
      lessThan(tester.getTopLeft(input).dy),
    );
    expect(find.text('Save Personnel and Crew').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_MODAL')) {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundaryKey),
        );
        final picture = await boundary.toImage(pixelRatio: 1);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../../scratch/labor_crew_modal_desktop.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }
  });
  testWidgets(
    'accepted workers remain visibly associated when switching trades',
    (tester) async {
      final api = FakePlanning();
      (api.data['workers'] as List).add(<String, dynamic>{
        'id': 'helper',
        'full_name': 'Elena',
        'role_id': 'role-b',
        'role_name': 'Ayudante',
      });
      await openDialog(tester, api, newPeople: true);
      await tester.ensureVisible(find.text('Pedro'));
      await tester.tap(find.text('Pedro'));
      await tester.pumpAndSettle();
      await acceptCurrentRole(tester);
      final summary = find.byKey(const ValueKey('accepted-personnel'));
      expect(
        find.descendant(of: summary, matching: find.text('Pedro')),
        findsOneWidget,
      );
      expect(api.calls, isEmpty);
      await changeRole(tester, 'Ayudante');
      expect(
        find.descendant(of: summary, matching: find.text('Pedro')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Elena'));
      await tester.tap(find.text('Elena'));
      await tester.pumpAndSettle();
      await acceptCurrentRole(tester);
      expect(find.text('Confirmed personnel · 2'), findsOneWidget);
      await tester.tap(find.text('Save Personnel and Crew'));
      await tester.pumpAndSettle();
      expect(api.calls, hasLength(1));
      final rows = api.calls.single['rows'] as List;
      expect(rows.map((r) => r['project_labor_id']), ['labor-a', 'labor-b']);
      expect(rows.map((r) => r['worker_id']), ['new-worker', 'helper']);
    },
  );
  testWidgets(
    'unaccepted selection cannot silently be saved or lost on changing trade',
    (tester) async {
      final api = FakePlanning();
      await openDialog(tester, api, newPeople: true);
      await tester.ensureVisible(find.text('Pedro'));
      await tester.tap(find.text('Pedro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Personnel and Crew'));
      await tester.pumpAndSettle();
      expect(api.calls, isEmpty);
      expect(
        find.textContaining('Confirm each trade selection'),
        findsOneWidget,
      );
      await changeRole(tester, 'Ayudante');
      await changeRole(tester, 'Operador');
      final tile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Pedro'),
      );
      expect(tile.value, isTrue);
      await acceptCurrentRole(tester);
      expect(find.text('Confirmed personnel · 1'), findsOneWidget);
      final summary = find.byKey(const ValueKey('accepted-personnel'));
      final chip = find.descendant(
        of: summary,
        matching: find.byType(InputChip),
      );
      await tester.ensureVisible(chip);
      tester.widget<InputChip>(chip).onDeleted!();
      await tester.pumpAndSettle();
      expect(find.text('Confirmed personnel · 0'), findsOneWidget);
      expect(api.calls, isEmpty);
    },
  );
  testWidgets(
    'picking a start proposes finish for the service duration before acceptance',
    (tester) async {
      final api = FakePlanning();
      ((api.data['labor'] as List).first
              as Map<String, dynamic>)['working_days'] =
          4;
      await openDialog(tester, api, newPeople: true);
      final start = find.byKey(const ValueKey('common-start'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final end = tester.widget<TextFormField>(
        find.byKey(const ValueKey('common-end')),
      );
      expect(end.controller!.text, '2026-10-08');
      await tester.ensureVisible(find.text('Pedro'));
      await tester.tap(find.text('Pedro'));
      await tester.pumpAndSettle();
      await acceptCurrentRole(tester);
      await tester.tap(find.text('Save Personnel and Crew'));
      await tester.pumpAndSettle();
      final row = (api.calls.single['rows'] as List).single;
      expect(row['valid_from'], '2026-10-05');
      expect(row['valid_until'], '2026-10-08');
    },
  );
  testWidgets('occupied role displays 1/1 and disables new worker selection', (
    tester,
  ) async {
    final api = FakePlanning();
    (api.data['labor'] as List).removeWhere((l) => l['id'] == 'vacant-a');
    await openDialog(tester, api, newPeople: true);
    expect(
      find.text('Period occupancy: 1/1 · Available positions: 0'),
      findsOneWidget,
    );
    expect(find.textContaining('Assigned: Ana'), findsOneWidget);
    final tile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Pedro'),
    );
    expect(tile.onChanged, isNull);
    expect(tile.value, isFalse);
    expect(api.calls, isEmpty);
  });
  testWidgets(
    '1/2 occupied only allows one additional worker and deselection frees that place',
    (tester) async {
      final api = FakePlanning();
      (api.data['workers'] as List).add(<String, dynamic>{
        'id': 'extra',
        'full_name': 'Raul',
        'role_id': 'role-a',
        'role_name': 'Operador',
      });
      await openDialog(tester, api, newPeople: true);
      expect(
        find.text('Period occupancy: 1/2 · Available positions: 1'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Pedro'));
      await tester.tap(find.text('Pedro'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Raul'),
            )
            .onChanged,
        isNull,
      );
      await tester.tap(find.text('Pedro'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Raul'),
            )
            .onChanged,
        isNotNull,
      );
      expect(api.calls, isEmpty);
    },
  );
  testWidgets(
    'role keeps its registered 1/1 count when reference is in a different month',
    (tester) async {
      final api = FakePlanning();
      (api.data['labor'] as List).removeWhere((l) => l['id'] == 'vacant-a');
      final role = (api.data['labor'] as List).first as Map<String, dynamic>;
      role['start_date'] = '2026-09-07';
      role['end_date'] = '2026-09-10';
      api.data['assignments'] = [
        <String, dynamic>{
          'id': 'assignment-a',
          'worker_id': 'worker-a',
          'worker_name': 'Miranda',
          'project_labor_id': 'labor-a',
          'role_name': 'Operador',
          'service_key': 'q:service',
          'start_date': '2026-10-25',
          'end_date': '2026-10-29',
        },
      ];
      await openDialog(tester, api, newPeople: true);
      expect(find.text('Operador · 1/1 assigned'), findsOneWidget);
      expect(find.text('Registered positions: 1/1'), findsOneWidget);
      expect(
        find.text('Period occupancy: 0/1 · Available positions: 1'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Miranda · 2026-10-25 → 2026-10-29 · Outside this period',
        ),
        findsOneWidget,
      );
      expect(api.calls, isEmpty);
    },
  );
  testWidgets(
    'booked worker stays disabled with its project and becomes available in a free period',
    (tester) async {
      final api = FakePlanning();
      ((api.data['labor'] as List).first
              as Map<String, dynamic>)['working_days'] =
          4;
      api.busyForPeriod = (start, end) =>
          start == '2026-10-01' ? {'new-worker'} : {};
      await openDialog(tester, api, newPeople: true);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Pedro'),
            )
            .onChanged,
        isNull,
      );
      expect(
        find.textContaining('Booked in Otra obra de prueba'),
        findsOneWidget,
      );
      final start = find.byKey(const ValueKey('common-start'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Pedro'),
            )
            .onChanged,
        isNotNull,
      );
      expect(
        find.textContaining('Booked in Otra obra de prueba'),
        findsNothing,
      );
      expect(api.requests, contains('2026-10-05/2026-10-08'));
      expect(api.calls, isEmpty);
    },
  );
  testWidgets(
    'availability failure never leaves unverified workers selectable',
    (tester) async {
      final api = FakePlanning()..availabilityFails = true;
      await openDialog(tester, api, newPeople: true);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text('Retry availability'), findsOneWidget);
      api.availabilityFails = false;
      final retry = find.text('Retry availability');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(CheckboxListTile, 'Pedro'), findsOneWidget);
    },
  );
  testWidgets(
    'a booking created after acceptance prevents saving without losing confirmed personnel',
    (tester) async {
      final api = FakePlanning();
      await openDialog(tester, api, newPeople: true);
      await tester.ensureVisible(find.text('Pedro'));
      await tester.tap(find.text('Pedro'));
      await tester.pumpAndSettle();
      await acceptCurrentRole(tester);
      api.busy = {'new-worker'};
      await tester.tap(find.text('Save Personnel and Crew'));
      await tester.pumpAndSettle();
      expect(api.calls, isEmpty);
      expect(find.text('Confirmed personnel · 1'), findsOneWidget);
      expect(find.textContaining('Pedro is already planned'), findsOneWidget);
    },
  );
}
