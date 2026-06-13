// Run: dart run bin/test_payroll.dart
import 'package:supabase_flutter/supabase_flutter.dart';

int _isoWeek(DateTime date) {
  final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
  final jan1 = DateTime(thursday.year, 1, 1);
  final dayOfYear = thursday.difference(jan1).inDays;
  return (dayOfYear ~/ 7) + 1;
}

void main() async {
  await Supabase.initialize(
    url: 'http://127.0.0.1:8001',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJpYXQiOjE5NzAwMTkwMDAsImV4cCI6MTk5OTk5OTk5OX0.rZGJ8JwbSTYPOQ0Nb3kQEBPSSSx93h7wFZqGx4MymNY',
  );
  final supabase = Supabase.instance.client;

  // Sign in
  await supabase.auth.signInWithPassword(email: 'admin@admin.com', password: '123456');
  print('Auth OK');

  final periodId = 'd5cedd84-2331-455a-a5da-5b574771a77d';

  // Fetch period info
  final period = await supabase
      .from('payroll_periods')
      .select('project_id, start_date, end_date')
      .eq('id', periodId)
      .single();
  print('Period: $period');

  // Fetch logs
  final reports = await supabase
      .from('daily_reports')
      .select('id')
      .eq('project_id', period['project_id'])
      .gte('report_date', period['start_date'])
      .lte('report_date', period['end_date']);

  final reportIds = (reports as List).map((r) => r['id'] as String).toList();
  print('Reports: ${reportIds.length}');

  final logs = await supabase
      .from('report_labor_logs')
      .select('''
        total_net_hours, worker_id,
        daily_reports!inner(report_date),
        workers(full_name, role_id, labor_roles(id, description, hourly_rate))
      ''')
      .in_('daily_report_id', reportIds);

  if (logs == null || (logs as List).isEmpty) {
    print('No logs found');
    return;
  }

  final list = logs as List<Map<String, dynamic>>;
  print('Logs: ${list.length}');

  // Group by worker + ISO week (same logic as payroll_service)
  final Map<String, Map<int, double>> workerWeeklyHours = {};
  final Map<String, Map<String, dynamic>> workerInfo = {};

  for (final log in list) {
    final wid = log['worker_id'] as String?;
    if (wid == null) continue;

    final dateStr = (log['daily_reports'] as Map?)?['report_date'] as String?;
    if (dateStr == null) continue;
    final date = DateTime.parse(dateStr);
    final week = _isoWeek(date);

    workerWeeklyHours.putIfAbsent(wid, () => {});
    final net = (log['total_net_hours'] as num?)?.toDouble() ?? 0;
    workerWeeklyHours[wid]![week] = (workerWeeklyHours[wid]![week] ?? 0) + net;

    if (!workerInfo.containsKey(wid)) {
      final w = log['workers'] as Map<String, dynamic>? ?? {};
      final role = w['labor_roles'] as Map<String, dynamic>? ?? {};
      workerInfo[wid] = {
        'worker_id': wid,
        'full_name': w['full_name'] ?? '',
        'role_id': role['id'],
        'role_name': role['description'] ?? '',
        'hourly_rate': (role['hourly_rate'] ?? 0).toDouble(),
      };
    }
  }

  print('\n=== RESULTADOS ===\n');
  double totalReg = 0, totalOT = 0, totalCost = 0;

  for (final wid in workerInfo.keys) {
    final info = workerInfo[wid]!;
    final weeklyHours = workerWeeklyHours[wid] ?? {};
    final rate = (info['hourly_rate'] as num).toDouble();

    double workerReg = 0, workerOT = 0;
    for (final weekHours in weeklyHours.values) {
      workerReg += weekHours > 40 ? 40 : weekHours;
      workerOT += weekHours > 40 ? weekHours - 40 : 0;
    }

    final cost = (workerReg * rate) + (workerOT * rate * 1.5);
    print('${info['full_name']} (${info['role_name']} \$${rate.toStringAsFixed(2)}/h)');
    print('  Reg: ${workerReg.toStringAsFixed(2)}h  OT: ${workerOT.toStringAsFixed(2)}h');
    print('  Cost: \$${cost.toStringAsFixed(2)}');
    print('  Weekly breakdown:');
    for (final entry in weeklyHours.entries) {
      final wReg = entry.value > 40 ? 40.0 : entry.value;
      final wOT = entry.value > 40 ? entry.value - 40 : 0.0;
      print('    ISO week ${entry.key}: ${entry.value.toStringAsFixed(2)}h total (reg ${wReg.toStringAsFixed(2)}h + OT ${wOT.toStringAsFixed(2)}h)');
    }
    print();

    totalReg += workerReg;
    totalOT += workerOT;
    totalCost += cost;
  }

  print('=== TOTALS ===');
  print('Regular hours: ${totalReg.toStringAsFixed(2)}h');
  print('Overtime hours: ${totalOT.toStringAsFixed(2)}h');
  print('Total cost: \$${totalCost.toStringAsFixed(2)}');

  await supabase.dispose();
}
