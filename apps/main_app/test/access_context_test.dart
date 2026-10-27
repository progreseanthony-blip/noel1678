import 'package:flutter_test/flutter_test.dart';
import 'package:noel_data/noel_data.dart';

void main() {
  test('unknown, legacy and missing roles have no operational access', () {
    for (final role in [null, 'Employee', 'admin', 'Custom']) {
      final access = AccessContext(role: role);
      expect(access.isActive, isFalse);
      expect(access.landing, '/access-pending');
      for (final path in [
        '/users',
        '/projects',
        '/quotes',
        '/crew-reports',
        '/worked-hours',
      ]) {
        expect(access.allowsPath(path), isFalse, reason: '$role $path');
      }
    }
  });
  test('administrator has all modules', () {
    const access = AccessContext(role: 'Admin');
    for (final path in [
      '/users',
      '/project-teams',
      '/billing',
      '/workers',
      '/projects/p/reception',
    ]) {
      expect(access.allowsPath(path), isTrue);
    }
  });
  test('foreman has only operational reports and hours', () {
    const access = AccessContext(role: 'Foreman', projects: {'assigned'});
    expect(access.landing, '/daily-reports');
    expect(access.allowsPath('/daily-reports'), isTrue);
    expect(access.allowsPath('/projects/assigned/daily-report'), isTrue);
    expect(access.allowsPath('/projects/assigned/daily-reports'), isTrue);
    expect(access.allowsPath('/crew-reports'), isTrue);
    expect(access.allowsPath('/worked-hours'), isTrue);
    expect(access.allowsPath('/labor-cost'), isTrue);
    expect(access.allowsPath('/projects/assigned/labor-hours'), isTrue);
    expect(access.allowsPath('/projects/other/labor-hours'), isFalse);
    expect(access.allowsPath('/projects/assigned/payroll'), isFalse);
    for (final path in [
      '/projects',
      '/projects/assigned',
      '/quotes',
      '/project-teams',
      '/users',
      '/crew-reports/other',
      '/daily-reports/pending',
      '/projects/other/daily-report',
      '/projects/other/daily-reports',
      '/projects/assigned/daily-report/r/review',
    ]) {
      expect(access.allowsPath(path), isFalse, reason: path);
    }
  });
  test('supervisor routes require membership and exact permitted modules', () {
    const access = AccessContext(role: 'Supervisor', projects: {'assigned'});
    for (final suffix in [
      '',
      '/baseline',
      '/daily-reports',
      '/daily-report',
      '/daily-report/r/review',
      '/labor-hours',
    ]) {
      expect(access.allowsPath('/projects/assigned$suffix'), isTrue);
      expect(access.allowsPath('/projects/other$suffix'), isFalse);
    }
    for (final path in ['/daily-reports/pending', '/worked-hours']) {
      expect(access.allowsPath(path), isTrue);
    }
    for (final path in [
      '/users',
      '/quotes',
      '/quotes/q',
      '/project-teams',
      '/billing',
      '/catalogs',
      '/projects/assigned/billing',
      '/projects/assigned/dashboard',
      '/projects/assigned/payroll/p',
      '/projects/assigned-extra',
      '/quotes-extra',
      '/quotes/q/secret',
    ]) {
      expect(access.allowsPath(path), isFalse, reason: path);
    }
  });
  test(
    'supervisor without projects can open only non-project allowed pages',
    () {
      const access = AccessContext(role: 'Supervisor');
      expect(access.allowsPath('/projects'), isTrue);
      expect(access.allowsPath('/projects/any'), isFalse);
      expect(access.allowsPath('/quotes'), isFalse);
    },
  );
}
