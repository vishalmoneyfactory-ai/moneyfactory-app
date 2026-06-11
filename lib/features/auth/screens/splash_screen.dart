import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt');
    if (!mounted) return;
    context.go(token == null ? '/login' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 42, backgroundColor: AppColors.gold, child: Text('MF', style: TextStyle(color: AppColors.primaryBg, fontWeight: FontWeight.w900, fontSize: 30))),
            SizedBox(height: 20),
            Text('MONEY FACTORY', style: TextStyle(color: AppColors.gold, fontSize: 28, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
