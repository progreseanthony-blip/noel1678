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
import '../features/field_operations/presentation/pages/daily_report_wizard_page.dart';
import '../features/field_operations/presentation/pages/daily_reports_list_page.dart';
import '../features/field_operations/presentation/pages/baseline_projects_page.dart';
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
      builder: (context, state) => ProjectBaselinePage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/daily-reports',
      builder: (context, state) => const BaselineProjectsPage(),
    ),
    GoRoute(
      path: '/projects/:id/daily-reports',
      builder: (context, state) => DailyReportsListPage(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id/daily-report',
      builder: (context, state) => DailyReportWizardPage(
        projectId: state.pathParameters['id']!,
        reportId: state.uri.queryParameters['reportId'],
      ),
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
