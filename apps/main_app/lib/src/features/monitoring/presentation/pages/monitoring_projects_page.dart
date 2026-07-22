import 'package:flutter/material.dart';
import '../../../../shared/widgets/project_picker_page.dart';

class MonitoringProjectsPage extends StatelessWidget {
  const MonitoringProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProjectPickerPage(
      title: 'Monitoring Dashboard',
      emptyMessage: 'Create a project and submit daily reports to see monitoring data.',
      icon: Icons.dashboard,
      actionLabel: 'View Dashboard',
      currentPath: '/monitoring',
      breadcrumbs: const ['Operations', 'Projects', 'Monitoring Dashboard'],
      routeBuilder: (projectId) => '/projects/$projectId/monitoring',
    );
  }
}
