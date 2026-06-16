import 'dart:ui';
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
    if (location.startsWith('/earn')) index = 2;
    if (location.startsWith('/profile')) index = 3;

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
        extendBody: true,
        body: child,
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.line(context),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(
                  color: AppColors.isDark(context) 
                      ? Colors.transparent 
                      : Colors.white.withValues(alpha: 0.8),
                  child: NavigationBar(
                    height: 66,
                    elevation: 0,
                    selectedIndex: index,
                    onDestinationSelected: (value) {
                      if (value == 0) context.go('/home');
                      if (value == 1) context.go('/learning');
                      if (value == 2) context.go('/earn');
                      if (value == 3) context.go('/profile');
                    },
                    backgroundColor: Colors.transparent,
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
                        icon: Icon(Icons.account_balance_wallet_outlined),
                        selectedIcon: Icon(Icons.account_balance_wallet),
                        label: 'Earn',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
