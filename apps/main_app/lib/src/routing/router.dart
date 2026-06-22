import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/signin_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/users/presentation/pages/user_list_page.dart';
import '../features/quotes/presentation/pages/quotes_list_page.dart';
import '../features/quotes/presentation/pages/quote_detail_page.dart';
import '../features/catalogs/presentation/pages/catalogs_page.dart';
import '../features/workers/presentation/pages/workers_page.dart';
import '../features/customers/presentation/pages/customers_list_page.dart';
import '../features/projects/presentation/pages/projects_list_page.dart';
import '../features/projects/presentation/pages/project_detail_page.dart';
import '../features/projects/presentation/pages/project_baseline_page.dart';
import '../features/projects/presentation/pages/reception_page.dart';
import '../features/field_operations/presentation/pages/daily_report_wizard_page.dart';
import '../features/field_operations/presentation/pages/daily_reports_list_page.dart';
import '../features/field_operations/presentation/pages/baseline_projects_page.dart';
import '../features/field_operations/presentation/pages/pending_approvals_page.dart';
import '../features/field_operations/presentation/pages/report_review_page.dart';
import '../features/payroll/presentation/pages/payroll_list_page.dart';
import '../features/payroll/presentation/pages/payroll_period_page.dart';
import '../features/payroll/presentation/pages/labor_cost_projects_page.dart';
import '../features/production_measurement/presentation/pages/production_measurement_page.dart';
import '../features/production_measurement/presentation/pages/production_measurement_projects_page.dart';
import '../features/incidents/presentation/pages/incidents_list_page.dart';
import '../features/incidents/presentation/pages/incident_detail_page.dart';
import '../features/incidents/presentation/pages/incident_form_page.dart';
import '../features/incidents/presentation/pages/incident_dashboard_page.dart';
import '../features/monitoring/presentation/pages/monitoring_projects_page.dart';
import '../features/monitoring/presentation/pages/project_monitoring_page.dart';
import '../features/billing/presentation/pages/billing_list_page.dart';
import '../features/billing/presentation/pages/billing_matrix_page.dart';
import '../features/billing/presentation/pages/billing_projects_page.dart';
import '../features/change_orders/presentation/pages/change_orders_list_page.dart';
import '../features/change_orders/presentation/pages/change_order_form_page.dart';
import '../features/change_orders/presentation/pages/change_order_detail_page.dart';
import '../features/change_orders/presentation/pages/change_orders_projects_page.dart';
final goRouter = GoRouter(
  initialLocation: '/signin',
  routes: [
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const UserListPage(),
    ),
    GoRoute(
      path: '/users',
      builder: (context, state) => const UserListPage(),
    ),
    GoRoute(
      path: '/quotes',
      builder: (context, state) => const QuotesListPage(),
    ),
    GoRoute(
      path: '/quotes/:id',
      builder: (context, state) => QuoteDetailPage(quoteId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects',
      builder: (context, state) => const ProjectsListPage(),
    ),
    GoRoute(
      path: '/projects/:id',
      builder: (context, state) => ProjectDetailPage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id/baseline',
      builder: (context, state) => ProjectBaselinePage(projectId: state.pathParameters['id']!, initialDate: state.uri.queryParameters['reportDate']),
    ),
    GoRoute(
      path: '/projects/:id/reception',
      builder: (context, state) => ReceptionPage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/production-measurement',
      builder: (context, state) => const ProductionMeasurementProjectsPage(),
    ),
    GoRoute(
      path: '/projects/:id/production-measurement',
      builder: (context, state) => ProductionMeasurementPage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/monitoring',
      builder: (context, state) => const MonitoringProjectsPage(),
    ),
    GoRoute(
      path: '/projects/:id/monitoring',
      builder: (context, state) => ProjectMonitoringPage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/daily-reports',
      builder: (context, state) => const BaselineProjectsPage(),
    ),
    GoRoute(
      path: '/daily-reports/pending',
      builder: (context, state) => const PendingApprovalsPage(),
    ),
    GoRoute(
      path: '/labor-cost',
      builder: (context, state) => const LaborCostProjectsPage(),
    ),
    GoRoute(
      path: '/projects/:id/daily-reports',
      builder: (context, state) => DailyReportsListPage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id/daily-report/:reportId/review',
      builder: (context, state) => ReportReviewPage(
        projectId: state.pathParameters['id']!,
        reportId: state.pathParameters['reportId']!,
      ),
    ),
    GoRoute(
      path: '/projects/:id/daily-report',
      builder: (context, state) => DailyReportWizardPage(
        projectId: state.pathParameters['id']!,
        reportId: state.uri.queryParameters['reportId'],
      ),
    ),
    GoRoute(
      path: '/projects/:id/payroll',
      builder: (context, state) => PayrollListPage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id/payroll/:periodId',
      builder: (context, state) => PayrollPeriodPage(
        projectId: state.pathParameters['id']!,
        periodId: state.pathParameters['periodId']!,
      ),
    ),
    GoRoute(
      path: '/incidents',
      builder: (context, state) => const IncidentsDashboardPage(),
    ),
    GoRoute(
      path: '/projects/:id/incidents',
      builder: (context, state) => IncidentsListPage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id/incidents/new',
      builder: (context, state) => IncidentFormPage(
        projectId: state.pathParameters['id']!,
        dailyReportId: state.uri.queryParameters['dailyReportId'],
      ),
    ),
    GoRoute(
      path: '/projects/:id/incidents/:incidentId',
      builder: (context, state) => IncidentDetailPage(
        projectId: state.pathParameters['id']!,
        incidentId: state.pathParameters['incidentId']!,
      ),
    ),
    GoRoute(
      path: '/projects/:id/billing',
      builder: (context, state) => BillingListPage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id/billing/new',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        return BillingMatrixPage(
          projectId: state.pathParameters['id']!,
          periodStart: extra?['periodStart'],
          periodEnd: extra?['periodEnd'],
        );
      },
    ),
    GoRoute(
      path: '/projects/:id/billing/:invoiceId',
      builder: (context, state) => BillingMatrixPage(
        projectId: state.pathParameters['id']!,
        invoiceId: state.pathParameters['invoiceId'],
      ),
    ),
    GoRoute(
      path: '/projects/:id/change-orders',
      builder: (context, state) => ChangeOrdersListPage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id/change-orders/new',
      builder: (context, state) => ChangeOrderFormPage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id/change-orders/:coId',
      builder: (context, state) => ChangeOrderDetailPage(
        projectId: state.pathParameters['id']!,
        coId: state.pathParameters['coId']!,
      ),
    ),
    GoRoute(
      path: '/billing',
      builder: (context, state) => const BillingProjectsPage(),
    ),
    GoRoute(
      path: '/change-orders',
      builder: (context, state) => const ChangeOrdersProjectsPage(),
    ),
    GoRoute(
      path: '/catalogs',
      builder: (context, state) => const CatalogsPage(),
    ),
    GoRoute(
      path: '/workers',
      builder: (context, state) => const WorkersPage(),
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomersListPage(),
    ),
  ],
);
