import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noel_data/noel_data.dart';

void main() {
  test(
    'service uses only read-model RPCs, never financial tables or writes',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final paths = <String>[];
      server.listen((request) async {
        paths.add(request.uri.path);
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(
            request.uri.path.endsWith('get_labor_hours_projects')
                ? []
                : <String, dynamic>{'rows': []},
          ),
        );
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'test-key',
      );
      try {
        final service = LaborHoursService(client);
        await service.projects();
        await service.query('p', '2026-11-02', '2026-11-08', crew: 'crew');
        expect(paths, [
          '/rest/v1/rpc/get_labor_hours_projects',
          '/rest/v1/rpc/get_labor_hours',
        ]);
      } finally {
        await client.dispose();
        await server.close(force: true);
      }
    },
  );
}
