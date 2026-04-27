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
