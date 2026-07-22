import 'package:flutter/material.dart';
import '../../../../shared/widgets/project_picker_page.dart';

class ProductionMeasurementProjectsPage extends StatelessWidget {
  const ProductionMeasurementProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProjectPickerPage(
      title: 'Production Metrics',
      emptyMessage: 'Create a project and submit daily reports to see production metrics.',
      icon: Icons.speed,
      actionLabel: 'View Metrics',
      currentPath: '/production-measurement',
      breadcrumbs: const ['Operations', 'Projects', 'Production Metrics'],
      routeBuilder: (projectId) => '/projects/$projectId/production-measurement',
    );
  }
}
