import 'package:supabase_flutter/supabase_flutter.dart';

/// Application roles are independent from workers' labor trades.
class AccessContext {
  final String? role;
  final Set<String> projects;
  const AccessContext({this.role, this.projects = const {}});
  bool get isAdmin => role == 'Admin';
  bool get isSupervisor => role == 'Supervisor';
  bool get isForeman => role == 'Foreman';
  bool get isActive => isAdmin || isSupervisor || isForeman;
  String get landing => isForeman
      ? '/daily-reports'
      : isActive
      ? '/projects'
      : '/access-pending';

  bool allowsPath(String path) {
    if (path == '/access-pending') return true;
    if (!isActive) return false;
    if (isAdmin) return true;
    if (path == '/crew-reports' ||
        path == '/worked-hours' ||
        path == '/labor-cost')
      return true;
    final hours = RegExp(r'^/projects/([^/]+)/labor-hours$').firstMatch(path);
    if (hours != null) return projects.contains(hours.group(1));
    if (isForeman) {
      if (path == '/daily-reports') return true;
      final match = RegExp(
        r'^/projects/([^/]+)(/daily-reports|/daily-report)$',
      ).firstMatch(path);
      return match != null && projects.contains(match.group(1));
    }
    if (const [
      '/projects',
      '/resource-planning',
      '/daily-reports',
      '/daily-reports/pending',
    ].contains(path))
      return true;
    final match = RegExp(r'^/projects/([^/]+)(.*)$').firstMatch(path);
    if (match == null || !projects.contains(match.group(1))) return false;
    final suffix = match.group(2)!;
    return suffix.isEmpty ||
        suffix == '/baseline' ||
        suffix == '/daily-reports' ||
        suffix == '/daily-report' ||
        RegExp(r'^/daily-report/[^/]+/review$').hasMatch(suffix);
  }
}

class AccessService {
  final SupabaseClient client;
  AccessService(this.client);
  Future<AccessContext> load() async {
    if (client.auth.currentUser == null) return const AccessContext();
    final data = Map<String, dynamic>.from(
      await client.rpc('get_access_context') as Map,
    );
    return AccessContext(
      role: data['role'] as String?,
      projects: (data['projects'] as List? ?? [])
          .map((e) => e.toString())
          .toSet(),
    );
  }
}
