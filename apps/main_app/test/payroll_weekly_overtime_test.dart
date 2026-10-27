import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noel_data/noel_data.dart';

Map<String, dynamic> laborDay(
  String date,
  double hours, [
  String worker = 'worker',
]) => {
  'worker_id': worker,
  'total_net_hours': hours,
  // Daily display values must not determine payable weekly overtime.
  'regular_hours': hours > 8 ? 8 : hours,
  'overtime_hours': hours > 8 ? hours - 8 : 0,
  'daily_reports': {'report_date': date},
  'workers': {
    'full_name': worker,
    'labor_roles': {'id': 'role', 'description': 'Operator', 'hourly_rate': 20},
  },
};

List<Map<String, dynamic>> classifiedFixture(List<Map<String, dynamic>> logs) {
  final totals = <String, double>{};
  return logs.map((log) {
    final date = DateTime.parse(log['daily_reports']['report_date']);
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final week =
        thursday.difference(DateTime(thursday.year, 1, 1)).inDays ~/ 7 + 1;
    final key = '${log['worker_id']}:${thursday.year}:$week';
    final previous = totals[key] ?? 0;
    final net = (log['total_net_hours'] as num).toDouble();
    final regular = net.clamp(0.0, (40 - previous).clamp(0.0, 40.0));
    totals[key] = previous + net;
    return <String, dynamic>{
      'worker_id': log['worker_id'],
      'worker': log['workers']['full_name'],
      'date': log['daily_reports']['report_date'],
      'role': 'Operator',
      'hourly_rate': 20.0,
      'validated': true,
      'net_hours': net,
      'regular_hours': regular,
      'overtime_hours': net - regular,
    };
  }).toList();
}

Future<Map<String, dynamic>> calculate(
  List<Map<String, dynamic>> logs, {
  List<Map<String, dynamic>> machinery = const [],
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final requests = <Uri>[];
  server.listen((request) async {
    requests.add(request.uri);
    final Object response;
    switch (request.uri.path.split('/').last) {
      case 'get_labor_payroll_data':
        response = {'rows': classifiedFixture(logs), 'machinery': machinery};
      default:
        request.response.statusCode = 404;
        await request.response.close();
        return;
    }
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(response));
    await request.response.close();
  });
  final client = SupabaseClient('http://127.0.0.1:${server.port}', 'test-key');
  try {
    final result = await PayrollService(
      client,
    ).calculateVirtualPeriod('project', '2026-11-02', '2026-11-15');
    expect(requests.map((uri) => uri.path), [
      '/rest/v1/rpc/get_labor_payroll_data',
    ]);
    return result;
  } finally {
    await client.dispose();
    await server.close(force: true);
  }
}

void main() {
  test('machinery uplift agrees in the worker entry and grand total', () async {
    final result = await calculate(
      [laborDay('2026-11-02', 6)],
      machinery: [
        {'operator_id': 'worker', 'total_hours': 2, 'rate_override': 30},
      ],
    );
    final worker = (result['entries'] as List).single;
    expect(worker['rate_uplift'], 20);
    expect(worker['total_pay'], 140);
    expect(result['total_cost'], 140);
  });

  test(
    'financial summary and both time reports use identical server-classified hours',
    () async {
      final row = {
        'worker_id': 'worker',
        'worker': 'Worker',
        'date': '2026-11-06',
        'validated': true,
        'net_hours': 2.5,
        'regular_hours': 1.0,
        'overtime_hours': 1.5,
        'break_minutes': 30,
        'check_in': '17:00',
        'check_out': '20:00',
        'role': 'Operator',
      };
      final requests = <String>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        requests.add('${request.method}:${request.uri.path}');
        final Object data;
        switch (request.uri.path.split('/').last) {
          case 'get_labor_payroll_data':
            data = {
              'rows': [
                {...row, 'hourly_rate': 20},
              ],
              'machinery': [],
            };
          case 'get_labor_hours':
            data = {
              'rows': [row],
            };
          case 'payroll_periods':
            data = {
              'project_id': 'project',
              'start_date': '2026-11-06',
              'end_date': '2026-11-06',
              'status': 'closed',
            };
          default:
            data = {};
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(data));
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'test-key',
      );
      try {
        final service = PayrollService(client);
        final finance = await service.calculateVirtualPeriod(
          'project',
          '2026-11-06',
          '2026-11-06',
        );
        final signoff = await service.getWorkerDetailedLogs('period');
        final individual = await service.getDailyLogsForWorker(
          'period',
          'worker',
        );
        for (final report in [finance, signoff, individual]) {
          expect(report['total_regular_hours'], 1);
          expect(report['total_overtime_hours'], 1.5);
        }
        expect(finance['total_cost'], 65);
        expect(individual['daily_logs'].single['net_hours'], 2.5);
        expect(
          requests.any((r) => r.startsWith('PATCH') || r.startsWith('DELETE')),
          isFalse,
        );
      } finally {
        await client.dispose();
        await server.close(force: true);
      }
    },
  );

  test(
    'opening a closed period never writes, and explicit recalculation is denied',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final methods = <String>[];
      final period = {
        'project_id': 'project',
        'start_date': '2026-11-02',
        'end_date': '2026-11-08',
        'status': 'closed',
        'total_cost': 12345,
      };
      server.listen((request) async {
        methods.add('${request.method}:${request.uri.path}');
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(
            request.uri.path.endsWith('payroll_periods')
                ? period
                : {'rows': [], 'machinery': []},
          ),
        );
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'test-key',
      );
      try {
        final service = PayrollService(client);
        expect(await service.previewPeriod('closed'), isEmpty);
        await expectLater(service.calculatePeriod('closed'), throwsStateError);
        expect(methods, ['GET:/rest/v1/payroll_periods', 'POST:/rest/v1/rpc/get_labor_payroll_data', 'GET:/rest/v1/payroll_periods']);
        expect(period['status'], 'closed');
        expect(period['total_cost'], 12345);
      } finally {
        await client.dispose();
        await server.close(force: true);
      }
    },
  );

  for (final sample in [
    (9.0, 36.0, 0.0),
    (10.0, 40.0, 0.0),
    (11.0, 40.0, 4.0),
  ]) {
    test('four ${sample.$1}h shifts: weekly overtime ${sample.$3}h', () async {
      final result = await calculate([
        for (var day = 2; day <= 5; day++) laborDay('2026-11-0$day', sample.$1),
      ]);
      expect(result['total_regular_hours'], sample.$2);
      expect(result['total_overtime_hours'], sample.$3);
      expect(result['total_cost'], sample.$2 * 20 + sample.$3 * 30);
    });
  }

  test('five 8.5h net shifts generate only 2.5h weekly overtime', () async {
    final result = await calculate([
      for (var day = 2; day <= 6; day++) laborDay('2026-11-0$day', 8.5),
    ]);
    expect(result['total_regular_hours'], 40);
    expect(result['total_overtime_hours'], 2.5);
    expect(result['total_cost'], 875);
  });

  test('weeks remain separate: 45h then 35h retain 5h overtime', () async {
    final result = await calculate([
      for (var day = 2; day <= 6; day++) laborDay('2026-11-0$day', 9),
      for (var day = 9; day <= 13; day++)
        laborDay('2026-11-${day.toString().padLeft(2, '0')}', 7),
    ]);
    expect(result['total_regular_hours'], 75);
    expect(result['total_overtime_hours'], 5);
  });

  test(
    'same week number in different ISO years has independent thresholds',
    () async {
      final result = await calculate([
        laborDay('2025-01-02', 30),
        laborDay('2026-01-01', 30),
      ]);
      expect(result['total_regular_hours'], 60);
      expect(result['total_overtime_hours'], 0);
    },
  );

  test('weekly limits apply independently to each worker', () async {
    final result = await calculate([
      for (var day = 2; day <= 6; day++) laborDay('2026-11-0$day', 9, 'first'),
      for (var day = 2; day <= 5; day++) laborDay('2026-11-0$day', 9, 'second'),
    ]);
    final entries = result['entries'] as List<Map<String, dynamic>>;
    expect(
      entries.singleWhere(
        (row) => row['worker_id'] == 'first',
      )['overtime_hours'],
      5,
    );
    expect(
      entries.singleWhere(
        (row) => row['worker_id'] == 'second',
      )['overtime_hours'],
      0,
    );
  });
}
