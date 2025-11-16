import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_page.dart';
import '../features/study/presentation/quiz_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: HomePage.routeName,
        pageBuilder: (context, state) => const MaterialPage(
          child: HomePage(),
        ),
      ),
      GoRoute(
        path: '/quiz',
        name: QuizPage.routeName,
        pageBuilder: (context, state) => const MaterialPage(
          child: QuizPage(),
        ),
      ),
    ],
  );
});


