import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class BackToHomeScope extends StatelessWidget {
  const BackToHomeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final location = GoRouterState.of(context).uri.path;
        if (location == '/home') {
          SystemNavigator.pop();
        } else {
          context.go('/home');
        }
      },
      child: child,
    );
  }
}
