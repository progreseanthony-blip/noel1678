import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noel_data/noel_data.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:noel_app/src/features/payroll/presentation/pages/labor_hours_page.dart';
import 'package:noel_app/src/features/payroll/presentation/utils/worker_individual_report_pdf_generator.dart';
import 'package:noel_app/src/features/payroll/presentation/utils/worker_signoff_pdf_generator.dart';

Map<String, dynamic> hoursData() => {
  'project': 'Future project',
  'crews': [
    {'id': 'crew', 'name': 'Crew A'},
  ],
  'periods': [
    {
      'id': 'closed',
      'name': 'Closed period',
      'status': 'closed',
      'start_date': '2026-11-02',
      'end_date': '2026-11-08',
    },
  ],
  'rows': [
    for (final sample in [
      ('a', 8.0, 8.0, 0.0, true),
      ('b', 2.5, 0.0, 2.5, true),
      ('draft', 5.0, 0.0, 0.0, false),
    ])
      {
        'id': sample.$1,
        'worker_id': 'w',
        'worker': 'Worker A',
        'id_number': '123',
        'role': 'Operator',
        'service': 'Clearing',
        'crew': 'Crew A',
        'date': '2026-11-06',
        'check_in': '07:00:00',
        'check_out': '15:30:00',
        'break_minutes': 30,
        'net_hours': sample.$2,
        'regular_hours': sample.$5 ? sample.$3 : null,
        'overtime_hours': sample.$5 ? sample.$4 : null,
        'validated': sample.$5,
        'status': sample.$5 ? 'approved' : 'draft',
      },
  ],
};

class FakeHours extends LaborHoursService {
  FakeHours() : super(SupabaseClient('http://localhost', 'test-key', authOptions: const AuthClientOptions(autoRefreshToken: false)));
  final calls = <List<String?>>[];
  bool fail = false;
  Map<String, dynamic>? response;
  @override
  Future<Map<String, dynamic>> query(
    String project,
    String start,
    String end, {
    String? crew,
  }) async {
    calls.add([project, start, end, crew]);
    if (fail) throw const PostgrestException(message: 'Access denied');
    return response ?? hoursData();
  }
}

class FakeTimeReportPrinting extends PrintingPlatform {
  final names = <String>[];
  final documents = <Uint8List>[];
  @override
  Future<bool> layoutPdf(
    Printer? printer,
    LayoutCallback onLayout,
    String name,
    PdfPageFormat format,
    bool dynamicLayout,
    bool usePrinterSettings,
    OutputType outputType,
    bool forceCustomPrintPaper,
  ) async {
    names.add(name);
    documents.add(await onLayout(format));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  for (final width in [1400.0, 400.0]) {
    testWidgets(
      'worker row opens the original PDF print flow at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final previous = PrintingPlatform.instance;
        final printing = FakeTimeReportPrinting();
        PrintingPlatform.instance = printing;
        addTearDown(() => PrintingPlatform.instance = previous);
        final service = FakeHours();
        final data = hoursData();
        data['rows'] = [
          ...data['rows'] as List,
          {
            ...(data['rows'] as List).first as Map,
            'id': 'other',
            'worker_id': 'other-worker',
            'worker': 'Worker B',
          },
        ];
        service.response = data;
        await tester.pumpWidget(
          MaterialApp(
            home: LaborHoursPage(
              projectId: 'p',
              service: service,
              initialRange: DateTimeRange(
                start: DateTime(2026, 11, 2),
                end: DateTime(2026, 11, 8),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final name = find.text('Worker B');
        await tester.ensureVisible(name);
        await tester.tap(name);
        await tester.pumpAndSettle();
        expect(printing.names, ['worked_hours_other-worker_2026-11-02.pdf']);
        expect(
          ascii.decode(printing.documents.single.take(4).toList()),
          '%PDF',
        );
        expect(service.calls, hasLength(1));
        expect(find.byType(ListTile), findsNothing);
        expect(
          tester.widget<DataTable>(find.byType(DataTable)).showCheckboxColumn,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a worker with only pending hours cannot print a validated report',
    (tester) async {
      final previous = PrintingPlatform.instance;
      final printing = FakeTimeReportPrinting();
      PrintingPlatform.instance = printing;
      addTearDown(() => PrintingPlatform.instance = previous);
      final data = hoursData();
      data['rows'] = [(data['rows'] as List).last];
      final service = FakeHours()..response = data;
      await tester.pumpWidget(
        MaterialApp(
          home: LaborHoursPage(projectId: 'p', service: service),
        ),
      );
      await tester.pumpAndSettle();
      final name = find.text('Worker A');
      await tester.ensureVisible(name);
      await tester.tap(name);
      await tester.pumpAndSettle();
      expect(printing.names, isEmpty);
      expect(
        find.text(
          'No validated hours for this worker in the selected date range.',
        ),
        findsOneWidget,
      );
    },
  );

  test(
    'summary excludes draft work and preserves the server weekly classification',
    () {
      final workers = LaborHoursService.workers(
        LaborHoursService.rows(hoursData()['rows']),
      );
      expect(workers.single['regular_hours'], 8);
      expect(workers.single['overtime_hours'], 2.5);
      expect(workers.single['total_hours'], 10.5);
      expect(workers.single.containsKey('hourly_rate'), isFalse);
    },
  );

  for (final width in [1400.0, 400.0]) {
    testWidgets('hours view and closed period stay read-only at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeHours();
      await tester.pumpWidget(
        MaterialApp(
          home: LaborHoursPage(
            projectId: 'p',
            service: service,
            initialRange: DateTimeRange(
              start: DateTime(2026, 11, 2),
              end: DateTime(2026, 11, 8),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Validated: 10.50 h · Unvalidated: 5.00 h'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Regular 8.00 h · Overtime 2.50 h'),
        findsNothing,
      );
      expect(find.byType(ListTile), findsNothing);
      expect(find.byTooltip('Individual time report PDF'), findsNothing);
      expect(find.text('draft'), findsOneWidget);
      expect(find.text('Recalculate'), findsNothing);
      final period = find.byType(DropdownButtonFormField<String>).last;
      await tester.ensureVisible(period);
      await tester.tap(period);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Closed period (closed)').last);
      await tester.pumpAndSettle();
      expect(service.calls, hasLength(2));
      expect(service.calls.last.sublist(1, 3), ['2026-11-02', '2026-11-08']);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('denied query shows no previous hours or exportable totals', (
    tester,
  ) async {
    final service = FakeHours()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: LaborHoursPage(projectId: 'p', service: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Access denied'), findsOneWidget);
    expect(find.text('Worker A'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  test(
    'existing individual and sign-off PDFs accept identical validated totals',
    () async {
      final rows = LaborHoursService.rows(
        hoursData()['rows'],
      ).where((r) => r['validated'] == true).toList();
      final worker = LaborHoursService.workers(rows).single;
      final individual = await WorkerIndividualReportPdfGenerator.generate(
        projectTitle: 'Project',
        periodName: 'Validated hours',
        startDate: '2026-11-02',
        endDate: '2026-11-08',
        worker: worker,
        dailyLogs: rows,
        totalReg: worker['regular_hours'],
        totalOT: worker['overtime_hours'],
        totalHours: worker['total_hours'],
      );
      final signoff = await WorkerSignoffPdfGenerator.generate(
        projectTitle: 'Project',
        periodName: 'Validated hours',
        startDate: '2026-11-02',
        endDate: '2026-11-08',
        workers: [worker],
        totalWorkers: 1,
        totalReg: worker['regular_hours'],
        totalOT: worker['overtime_hours'],
        totalHours: worker['total_hours'],
      );
      for (final bytes in [individual, signoff]) {
        expect(ascii.decode(bytes.take(4).toList()), '%PDF');
        expect(bytes.length, greaterThan(1000));
      }
    },
  );
}
