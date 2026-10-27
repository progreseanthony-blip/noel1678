import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_app/src/features/field_operations/presentation/pages/daily_report_wizard_page.dart';
import 'package:noel_app/src/features/field_operations/presentation/widgets/step_general_info.dart';
import 'package:noel_app/src/features/field_operations/presentation/widgets/step_labor.dart';
import 'package:noel_app/src/features/field_operations/presentation/widgets/step_review_sign.dart';

class FakeExecution extends DailyExecutionService {
  FakeExecution() : super(SupabaseClient('http://localhost', 'test-key'));
  final saved = <Map<String, dynamic>>[];
  final requests = <String>[];
  bool failSave = false;
  bool failEntry = false;
  bool sectionExists = true;
  int opens = 0;
  String sectionStatus = 'draft';
  final notes = <String, String>{'a': 'Notas A', 'b': 'Notas B'};
  List<Map<String, dynamic>> signature = [];
  List<String> photos = [];

  @override
  String? get currentUserId => 'foreman';
  @override
  Future<Map<String, dynamic>> breakContext(String project, String day, String crew) async => {};
  @override
  Future<Map<String, dynamic>> transferContext(String project, String day, String? crew) async =>
      {'crews': [{'id': 'a', 'name': 'Cuadrilla A'}, {'id': 'b', 'name': 'Cuadrilla B'}],
       'labor': [], 'transfers': []};

  @override
  Future<Map<String, dynamic>> entry(
    String projectId,
    String day, {
    String? reportId,
  }) async {
    requests.add('entry:$day');
    if (failEntry) throw StateError('Sin autorización para esta fecha');
    return {
      'project': {
        'id': projectId,
        'title': 'Obra de prueba',
        'status': 'active',
      },
      'date': day,
      'legacy_resources': false,
      'has_sections': true,
      'crews': [
        {'id': 'a', 'name': 'Cuadrilla A'},
        {'id': 'b', 'name': 'Cuadrilla B'},
      ],
      'report': {
        'id': 'report',
        'project_id': projectId,
        'report_date': day,
        'status': day == '2090-01-19' ? 'approved' : 'draft',
        'day_type': 'working',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> workspace(
    String projectId,
    String day,
    String crewId,
  ) async {
    requests.add('workspace:$day:$crewId');
    return {
      'section': !sectionExists ? null : {
        'id': 'section-$crewId',
        'daily_report_id': 'report',
        'crew_id': crewId,
        'status': sectionStatus,
        'revision': saved.length,
        'notes': notes[crewId],
        'signature_points': signature,
        'evidence_photos': photos,
      },
      'sections': [],
      'workers': [],
      'planned_labor': [],
      'planned_machinery': [],
      'planned_materials': [],
      'labor': [],
      'machinery': [],
      'materials': [],
      'deviation_reasons': [],
    };
  }

  @override
  Future<Map<String, dynamic>> open(String projectId, String day, String crewId) async {
    opens++;
    sectionExists = true;
    return {'id': 'section-$crewId', 'daily_report_id': 'report', 'crew_id': crewId, 'revision': 0, 'status': 'draft'};
  }

  @override
  Future<Map<String, dynamic>> save({
    required Map<String, dynamic> section,
    required String notes,
    required List<Map<String, dynamic>> labor,
    required List<Map<String, dynamic>> machinery,
    required List<Map<String, dynamic>> materials,
    required List<Map<String, dynamic>> signature,
    required List<String> photos,
    bool submit = false,
  }) async {
    if (failSave) throw StateError('Section changed. Reload before saving');
    final payload = Map<String, dynamic>.from(
      jsonDecode(
            jsonEncode({
              'section': section,
              'notes': notes,
              'labor': labor,
              'machinery': machinery,
              'materials': materials,
              'signature': signature,
              'photos': photos,
              'submit': submit,
            }),
          )
          as Map,
    );
    saved.add(payload);
    this.notes[section['crew_id'] as String] = notes;
    this.signature = signature;
    this.photos = photos;
    sectionStatus = submit ? 'submitted' : 'draft';
    return {...section, 'revision': saved.length, 'status': sectionStatus};
  }
}

Future<void> showWizard(WidgetTester tester, FakeExecution service) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: DailyReportWizardPage(
          projectId: 'project',
          executionService: service,
          accessContext: const AccessContext(
            role: 'Foreman',
            projects: {'project'},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> selectCrew(WidgetTester tester, String name) async {
  await tester.ensureVisible(
    find.byType(DropdownButtonFormField<String>).first,
  );
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'Foreman saves only selected section and preserves signature/evidence',
    (tester) async {
      final service = FakeExecution();
      await showWizard(tester, service);
      expect(find.text('Project consolidated report'), findsNothing);
      expect(
        tester.widget<StepGeneralInfo>(find.byType(StepGeneralInfo)).isReadOnly,
        isTrue,
      );
      final review = tester.widget<StepReviewSign>(find.byType(StepReviewSign));
      review.onEvidenceChanged!([
        {'x': 4.0, 'y': 5.0},
      ], []);
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('section-notes')),
        'Trabajo de A',
      );
      await tester.tap(find.text('Save Draft'));
      await tester.pumpAndSettle();
      expect(service.saved.single['section']['id'], 'section-a');
      expect(service.saved.single['notes'], 'Trabajo de A');
      expect(service.saved.single['signature'], [
        {'x': 4.0, 'y': 5.0},
      ]);
      await selectCrew(tester, 'Cuadrilla B');
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('section-notes')))
            .controller!
            .text,
        'Notas B',
      );
      await tester.enterText(
        find.byKey(const ValueKey('section-notes')),
        'Trabajo de B',
      );
      await tester.tap(find.text('Save Draft'));
      await tester.pumpAndSettle();
      expect(service.saved.last['section']['id'], 'section-b');
      expect(service.notes['a'], 'Trabajo de A');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed save keeps notes and does not claim success', (
    tester,
  ) async {
    final service = FakeExecution()..failSave = true;
    await showWizard(tester, service);
    await tester.enterText(
      find.byKey(const ValueKey('section-notes')),
      'No perder este texto',
    );
    await tester.tap(find.text('Save Draft'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save crew report'), findsOneWidget);
    expect(find.text('Crew report saved'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('section-notes')))
          .controller!
          .text,
      'No perder este texto',
    );
    expect(service.saved, isEmpty);
    expect(service.requests.where((r) => r.startsWith('workspace:')).length, 1);
  });

  testWidgets(
    'cancelling a crew change restores the selected scope and draft',
    (tester) async {
      final service = FakeExecution();
      await showWizard(tester, service);
      await tester.enterText(
        find.byKey(const ValueKey('section-notes')),
        'Pendiente A',
      );
      await selectCrew(tester, 'Cuadrilla B');
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('section-notes')))
            .controller!
            .text,
        'Pendiente A',
      );
      await tester.tap(find.text('Save Draft'));
      await tester.pumpAndSettle();
      expect(service.saved.single['section']['id'], 'section-a');
    },
  );

  testWidgets(
    'changing date loads correct state and locks an approved parent',
    (tester) async {
      final service = FakeExecution();
      await showWizard(tester, service);
      final general = tester.widget<StepGeneralInfo>(
        find.byType(StepGeneralInfo),
      );
      general.onChanged({...general.reportData, 'report_date': '2090-01-19'});
      await tester.pumpAndSettle();
      expect(service.requests.last, 'workspace:2090-01-19:a');
      expect(find.text('Save Draft'), findsNothing);
      expect(
        tester.widget<StepLabor>(find.byType(StepLabor)).isReadOnly,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('section-notes')))
            .readOnly,
        isTrue,
      );
    },
  );

  testWidgets('Foreman crew reports retain automatic labor breaks', (tester) async {
    await showWizard(tester, FakeExecution());
    expect(tester.widget<StepLabor>(find.byType(StepLabor)).explicitBreaks, isFalse);
  });

  testWidgets(
    'submission sends section without submitting the consolidated report',
    (tester) async {
      final service = FakeExecution();
      await showWizard(tester, service);
      await tester
          .widget<StepReviewSign>(find.byType(StepReviewSign))
          .onSubmit();
      await tester.pumpAndSettle();
      expect(service.saved.single['submit'], isTrue);
      expect(find.text('Save Draft'), findsNothing);
      expect(
        tester.widget<StepLabor>(find.byType(StepLabor)).isReadOnly,
        isTrue,
      );
    },
  );

  testWidgets('entry errors fail closed without querying full catalogs', (
    tester,
  ) async {
    await showWizard(tester, FakeExecution()..failEntry = true);
    expect(find.text('Error loading report'), findsOneWidget);
    expect(find.byType(StepLabor), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry after first save failure reuses the created server section', (tester) async {
    final service = FakeExecution()..sectionExists = false..failSave = true;
    await showWizard(tester, service);
    await tester.enterText(find.byKey(const ValueKey('section-notes')), 'Primer borrador');
    await tester.tap(find.text('Save Draft'));
    await tester.pumpAndSettle();
    expect(service.opens, 1);
    service.failSave = false;
    await tester.tap(find.text('Save Draft'));
    await tester.pumpAndSettle();
    expect(service.opens, 1);
    expect(service.saved.single['notes'], 'Primer borrador');
  });

  testWidgets('pending evidence upload blocks saving and scope changes', (tester) async {
    final service = FakeExecution();
    await showWizard(tester, service);
    final review = tester.widget<StepReviewSign>(find.byType(StepReviewSign));
    review.onUploadStateChanged!(true);
    await tester.pump();
    expect(find.text('Save Draft'), findsNothing);
    expect(tester.widget<OutlinedButton>(find.byKey(const ValueKey('report-date'))).onPressed, isNull);
    await review.onSubmit();
    expect(service.saved, isEmpty);
    review.onUploadStateChanged!(false);
    await tester.pumpAndSettle();
    expect(find.text('Save Draft'), findsOneWidget);
  });
}
