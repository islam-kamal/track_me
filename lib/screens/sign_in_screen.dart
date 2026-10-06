import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../theme/track_me_theme.dart';
import 'register_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthCancelled {
      // The Google sheet was dismissed.
    } on AuthFailure catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: trackTeal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.near_me, color: trackInk, size: 32),
            ),
            const SizedBox(height: 20),
            Text('Track Me', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            const Text(
              'Sign in to record your route, or open the admin map.',
              style: TextStyle(color: Color(0xFF94A3B8), height: 1.4),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFFDA4AF))),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      await _auth.signInWithEmail(
                        email: _email.text,
                        password: _password.text,
                      );
                    }),
              child: Text(_busy ? 'Please wait…' : 'Sign in'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(() => _auth.signInWithGoogle()),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
