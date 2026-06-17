import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../shared/widgets/motion.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService(dioProvider);
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _signup = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parseError(e)), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient(context)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
            children: [
              FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONEY FACTORY',
                      style: TextStyle(
                        color: AppColors.themeGold(context),
                        fontFamily: 'JetBrains Mono',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _signup ? 'Create Account.' : 'Welcome Back.',
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 40,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              FadeSlideIn(
                delay: const Duration(milliseconds: 90),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: _signup ? _signupForm() : _loginForm(),
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _loading ? null : () => _run(() async => _auth.signInWithGoogle()),
                icon: const Icon(Icons.g_mobiledata, size: 30),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 26),
              Center(
                child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(_signup ? 'Already have an account? ' : "Don't have an account? ", style: TextStyle(color: AppColors.mutedText(context), fontWeight: FontWeight.w700)),
                  InkWell(
                    onTap: _loading ? null : () => setState(() => _signup = !_signup),
                    child: Text(_signup ? 'Login' : 'Sign up', style: const TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.w900)),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginForm() => Column(
        key: const ValueKey('login'),
        children: [
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 14),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 22),
          GoldButton(
            label: _loading ? 'Signing in...' : 'Login',
            onPressed: _loading ? null : () => _run(() async => _auth.signInWithEmail(_email.text.trim(), _password.text)),
          ),
        ],
      );

  Widget _signupForm() => Column(
        key: const ValueKey('signup'),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 14),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
          const SizedBox(height: 14),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 14),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 14),
          TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
          const SizedBox(height: 22),
          GoldButton(
            label: _loading ? 'Creating...' : 'Create Account',
            onPressed: _loading
                ? null
                : () => _run(() async {
                    if (_password.text != _confirm.text) throw Exception('Passwords do not match');
                    if (_phone.text.trim().isEmpty) throw Exception('Phone number is required');
                    await _auth.register(_name.text.trim(), _phone.text.trim(), _email.text.trim(), _password.text);
                  }),
          ),
        ],
      );
}
