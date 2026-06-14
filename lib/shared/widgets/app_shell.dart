import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int index = 0;
    if (location.startsWith('/learning')) index = 1;
    if (location.startsWith('/profile')) index = 2;

    return PopScope(
      // Intercept the Android back button at the shell level
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (location == '/home') {
          // On Home tab — exit the app
          SystemNavigator.pop();
        } else {
          // On Learning or Profile tab — go back to Home
          context.go('/home');
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) {
            if (value == 0) context.go('/home');
            if (value == 1) context.go('/learning');
            if (value == 2) context.go('/profile');
          },
          backgroundColor: AppColors.card(context),
          indicatorColor: AppColors.goldGlow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Courses',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
