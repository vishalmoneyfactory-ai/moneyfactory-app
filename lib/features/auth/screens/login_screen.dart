import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gold_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _auth = AuthService(dioProvider);
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              const Text('MONEY FACTORY', textAlign: TextAlign.center, style: TextStyle(color: AppColors.gold, fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Premium trading education', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                child: TabBar(controller: _tabs, indicatorColor: AppColors.gold, labelColor: AppColors.gold, tabs: const [Tab(text: 'Login'), Tab(text: 'Register')]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 470,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _form(children: [
                      TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                      const SizedBox(height: 12),
                      TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                      const SizedBox(height: 18),
                      GoldButton(label: _loading ? 'Signing in...' : 'Sign In', onPressed: _loading ? null : () => _run(() async => _auth.signInWithEmail(_email.text.trim(), _password.text))),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(onPressed: _loading ? null : () => _run(() async => _auth.signInWithGoogle()), icon: const Icon(Icons.g_mobiledata), label: const Text('Continue with Google')),
                    ]),
                    _form(children: [
                      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
                      const SizedBox(height: 12),
                      TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
                      const SizedBox(height: 12),
                      TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                      const SizedBox(height: 12),
                      TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                      const SizedBox(height: 12),
                      TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
                      const SizedBox(height: 18),
                      GoldButton(label: _loading ? 'Creating...' : 'Create Account', onPressed: _loading ? null : () => _run(() async {
                        if (_password.text != _confirm.text) throw Exception('Passwords do not match');
                        if (_phone.text.trim().isEmpty) throw Exception('Phone number is required');
                        await _auth.register(_name.text.trim(), _phone.text.trim(), _email.text.trim(), _password.text);
                      })),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form({required List<Widget> children}) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Column(children: children));
}
