import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Wraps tab-level shell screens (Home, Learning, Profile).
/// - On /home: pressing back exits the app (standard behaviour)
/// - On /learning or /profile: pressing back goes back to /home
class ShellBackScope extends StatelessWidget {
  const ShellBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final location = GoRouterState.of(context).uri.path;
        if (location == '/home') {
          // On home tab — exit app
          SystemNavigator.pop();
        } else {
          // On learning/profile tab — go back to home tab
          context.go('/home');
        }
      },
      child: child,
    );
  }
}

/// Wraps detail screens (Course, Checkout, Video).
/// Simply allows natural back navigation through the route stack.
class BackToHomeScope extends StatelessWidget {
  const BackToHomeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // Let the router handle back naturally
      child: child,
    );
  }
}
