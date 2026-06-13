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
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => BackToHomeScope(child: AppShell(child: child)),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/learning', builder: (context, state) => const MyCoursesScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/course/:id', builder: (context, state) => BackToHomeScope(child: CourseDetailScreen(courseId: state.pathParameters['id']!))),
      GoRoute(path: '/complete-profile', builder: (context, state) => const CompleteProfileScreen()),
      GoRoute(path: '/checkout/:id', builder: (context, state) => BackToHomeScope(child: CheckoutScreen(courseId: state.pathParameters['id']!, isBundle: state.uri.queryParameters['bundle'] == 'true'))),
      GoRoute(path: '/video/:id', builder: (context, state) => BackToHomeScope(child: VideoPlayerScreen(videoId: state.pathParameters['id']!, courseId: state.uri.queryParameters['course'] ?? ''))),
    ],
  );
});
