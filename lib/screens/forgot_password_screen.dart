import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../services/customer_api.dart';
import '../theme/orchard_theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

/// 3-step flow mirroring the backend:
/// POST /auth/forgot -> POST /auth/verify-otp -> POST /auth/reset-password
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  bool _busy = false;
  final _phone = TextEditingController();
  final _otpBoxes =
      List.generate(6, (_) => TextEditingController());
  final _otpNodes = List.generate(6, (_) => FocusNode());
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  String? _debugOtp;

  String get _otpCode => _otpBoxes.map((c) => c.text).join();

  void _fillOtp(String code) {
    final chars = code.split('');
    for (var i = 0; i < 6; i++) {
      _otpBoxes[i].text = i < chars.length ? chars[i] : '';
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    for (final c in _otpBoxes) {
      c.dispose();
    }
    for (final n in _otpNodes) {
      n.dispose();
    }
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  CustomerApi get _api => context.read<CustomerApi>();

  Future<void> _run(Future<String> Function() fn, {required VoidCallback onOk}) async {
    setState(() => _busy = true);
    try {
      final msg = await fn();
      if (!mounted) return;
      showSnack(context, msg);
      onOk();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.friendlyMessage, isError: true);
    } catch (_) {
      if (mounted) showSnack(context, 'Request failed. Check connection.', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: OrchardGradient(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Stepper(
                  currentStep: _step,
                  physics: const NeverScrollableScrollPhysics(),
                  onStepTapped: (i) {
                    if (i < _step) setState(() => _step = i);
                  },
                  steps: [
                    Step(
                      title: const Text('Phone'),
                      content: TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Registered phone number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      isActive: _step >= 0,
                    ),
                    Step(
                      title: const Text('OTP'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: List.generate(
                                6, (i) => _OtpBox(
                                      controller: _otpBoxes[i],
                                      node: _otpNodes[i],
                                      onNext: i < 5
                                          ? () => _otpNodes[i + 1]
                                              .requestFocus()
                                          : null,
                                      onPrev: i > 0
                                          ? () {
                                              if (_otpBoxes[i]
                                                  .text
                                                  .isEmpty) {
                                                _otpNodes[i - 1]
                                                    .requestFocus();
                                              }
                                            }
                                          : null,
                                    )),
                          ),
                          if (_debugOtp != null &&
                              _debugOtp!.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8),
                              child: Text(
                                'Dev build: OTP prefilled (${_debugOtp!})',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: OrchardColors.muted),
                              ),
                            ),
                        ],
                      ),
                      isActive: _step >= 1,
                    ),
                    Step(
                      title: const Text('New password'),
                      content: Column(
                        children: [
                          TextField(
                            controller: _pass,
                            obscureText: _obscure,
                            decoration: const InputDecoration(
                              labelText: 'New password (min 8, letters + numbers)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirm,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                        ],
                      ),
                      isActive: _step >= 2,
                    ),
                  ],
                  controlsBuilder: (context, details) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                if (_step == 0)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              () async {
                                final r = await _api.requestOtp(
                                    _phone.text.trim());
                                _debugOtp = r.debugOtp;
                                return r.message;
                              },
                              onOk: () => setState(() {
                                _step = 1;
                                if (_debugOtp != null &&
                                    _debugOtp!.length == 6) {
                                  _fillOtp(_debugOtp!);
                                }
                              }),
                            ),
                    child: Text(_busy ? 'Sending…' : 'Send OTP'),
                  ),
                if (_step == 1) ...[
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () {
                            if (_otpCode.length != 6) {
                              showSnack(context,
                                  'Enter the 6-digit OTP.',
                                  isError: true);
                              return;
                            }
                            _run(
                              () => _api.verifyOtp(
                                  _phone.text.trim(), _otpCode),
                              onOk: () =>
                                  setState(() => _step = 2),
                            );
                          },
                    child: Text(_busy ? 'Verifying…' : 'Verify OTP'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              () async {
                                final r = await _api.requestOtp(_phone.text.trim());
                                return r.message;
                              },
                              onOk: () {},
                            ),
                    child: const Text('Resend OTP'),
                  ),
                ],
                if (_step == 2)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () {
                            if (_pass.text.length < 8) {
                              showSnack(context, 'Password must be at least 8 characters.', isError: true);
                              return;
                            }
                            if (_pass.text != _confirm.text) {
                              showSnack(context, 'Passwords do not match.', isError: true);
                              return;
                            }
                            _run(
                              () => _api.resetPassword(
                                _phone.text.trim(),
                                _otpCode,
                                _pass.text,
                                _confirm.text,
                              ),
                              onOk: () => Navigator.of(context).pop(),
                            );
                          },
                    child: Text(_busy ? 'Saving…' : 'Set new password'),
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

/// Single auto-advancing OTP digit box (spec section 3.3).
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.node,
    this.onNext,
    this.onPrev,
  });
  final TextEditingController controller;
  final FocusNode node;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: node,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) {
          if (v.length == 1) {
            onNext?.call();
          } else if (v.isEmpty) {
            onPrev?.call();
          }
        },
      ),
    );
  }
}
