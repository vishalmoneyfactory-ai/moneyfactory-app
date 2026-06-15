import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/courses/screens/course_detail_screen.dart';
import '../../features/courses/screens/my_courses_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/payment/screens/checkout_screen.dart';
import '../../features/profile/screens/complete_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/video/screens/video_player_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/back_to_home_scope.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _page(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _page(state, const LoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            BackToHomeScope(child: AppShell(child: child)),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _page(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/learning',
            pageBuilder: (context, state) =>
                _page(state, const MyCoursesScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _page(state, const ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/course/:id',
        pageBuilder: (context, state) => _page(
          state,
          BackToHomeScope(
            child: CourseDetailScreen(courseId: state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/complete-profile',
        pageBuilder: (context, state) =>
            _page(state, const CompleteProfileScreen()),
      ),
      GoRoute(
        path: '/checkout/:id',
        pageBuilder: (context, state) => _page(
          state,
          BackToHomeScope(
            child: CheckoutScreen(
              courseId: state.pathParameters['id']!,
              isBundle: state.uri.queryParameters['bundle'] == 'true',
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/video/:id',
        pageBuilder: (context, state) => _page(
          state,
          BackToHomeScope(
            child: VideoPlayerScreen(
              videoId: state.pathParameters['id']!,
              courseId: state.uri.queryParameters['course'] ?? '',
            ),
          ),
        ),
      ),
    ],
  );
});

CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(.035, .015),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
