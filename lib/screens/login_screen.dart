import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../state/app_state.dart';
import '../theme/orchard_theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthState>();
    try {
      await auth.login(_phone.text, _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on ApiException catch (e) {
      if (mounted) {
        showSnack(context, e.friendlyMessage, isError: true);
      }
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Login failed. Check connection.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final effectiveLogo = (auth.config.mobile.appLogoUrl != null &&
            auth.config.mobile.appLogoUrl!.isNotEmpty)
        ? auth.config.mobile.appLogoUrl
        : auth.config.theme.logoUrl;

    return Scaffold(
      body: OrchardGradient(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppBrandLogo(
                      logoUrl: effectiveLogo,
                      fontSize: 32,
                      maxHeight: 64,
                    ),
                    const SizedBox(height: 12),
                    const YieldPill(),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome back',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in with your registered phone number',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: OrchardColors.muted),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone number',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().length < 7)
                                        ? 'Enter a valid phone number'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () => setState(
                                        () => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.isEmpty)
                                        ? 'Enter your password'
                                        : null,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen()),
                                  ),
                                  child:
                                      const Text('Forgot password?'),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FilledButton(
                                onPressed: auth.loading ? null : _submit,
                                child: auth.loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Text('Sign in',
                                        style: TextStyle(fontSize: 16)),
                              ),
                              if (auth.error != null) ...[
                                const SizedBox(height: 12),
                                Text(auth.error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: OrchardColors.danger)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
