import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

/// Hard gate shown right after sign-up (and on app launch if the signed-in
/// account hasn't verified yet). User enters the 6-digit code we emailed.
/// On success, Firebase Auth's `emailVerified` flips to true and AuthGate
/// will route them into the rest of the app on the next stream tick.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _auth = AuthService();
  final _controller = TextEditingController();
  final _focus = FocusNode();

  bool _verifying = false;
  String? _error;
  String? _info;
  int _resendSecondsLeft = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _autoRequestCode();
    });
  }

  /// Fire a code automatically the first time the user lands here. Works for
  /// both fresh sign-ups and existing-but-unverified sign-ins. The server's
  /// own 30s cooldown protects against spam if the user kills the app and
  /// comes back too fast — we just swallow that error and keep the cooldown
  /// timer running locally.
  Future<void> _autoRequestCode() async {
    try {
      await _auth.requestEmailCode();
      if (!mounted) return;
      setState(() => _info = 'Code sent — check your inbox.');
      _startResendCooldown(30);
    } on EmailCodeException catch (e) {
      if (!mounted) return;
      // 'cooldown' / 'already-verified' aren't user-facing errors here —
      // fall through to the normal screen state.
      if (e.code == 'cooldown') {
        final m = RegExp(r'(\d+)s').firstMatch(e.message);
        _startResendCooldown(m != null ? int.parse(m.group(1)!) : 30);
      } else if (e.code != 'already-verified') {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error =
          'Could not send a code. Tap resend to try again.');
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startResendCooldown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSecondsLeft--;
        if (_resendSecondsLeft <= 0) t.cancel();
      });
    });
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      await _auth.requestEmailCode();
      if (!mounted) return;
      setState(() => _info = 'New code sent — check your inbox.');
      _startResendCooldown(30);
    } on EmailCodeException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      // If the server told us a cooldown is in effect, parse it and respect it.
      final m = RegExp(r'(\d+)s').firstMatch(e.message);
      if (m != null) {
        _startResendCooldown(int.parse(m.group(1)!));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not send a new code. Try again.');
    }
  }

  Future<void> _submit(String code) async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
      _info = null;
    });
    try {
      await _auth.verifyEmailCode(code);
      // AuthGate listens to authStateChanges and will rebuild after reload().
    } on EmailCodeException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _verifying = false;
      });
      _controller.clear();
      _focus.requestFocus();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Try again.';
        _verifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.currentUser?.email ?? 'your email';
    return Scaffold(
      backgroundColor: MomentoTheme.seashell,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign out',
                onPressed: () => _auth.signOut(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Check your email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: MomentoTheme.deepPlum,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We sent a 6-digit code to $email. Enter it below to confirm your account.',
                style: TextStyle(
                  fontSize: 15,
                  color: MomentoTheme.deepPlum.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              _CodeField(
                controller: _controller,
                focus: _focus,
                enabled: !_verifying,
                onCompleted: _submit,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: MomentoTheme.coral),
                ),
              ],
              if (_info != null) ...[
                const SizedBox(height: 16),
                Text(
                  _info!,
                  style: TextStyle(
                    color: MomentoTheme.deepPlum.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: _resendSecondsLeft > 0 || _verifying
                      ? null
                      : _resend,
                  child: Text(
                    _resendSecondsLeft > 0
                        ? 'Resend code in ${_resendSecondsLeft}s'
                        : 'Resend code',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_verifying)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 6-cell numeric code field. Shows the digit in each box as the user types
/// and fires `onCompleted` once all 6 are filled.
class _CodeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final bool enabled;
  final ValueChanged<String> onCompleted;

  const _CodeField({
    required this.controller,
    required this.focus,
    required this.enabled,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hidden TextField captures keyboard input.
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 60,
            child: TextField(
              controller: controller,
              focusNode: focus,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (v) {
                if (v.length == 6) onCompleted(v);
              },
            ),
          ),
        ),
        IgnorePointer(
          child: GestureDetector(
            onTap: enabled ? () => focus.requestFocus() : null,
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final value = controller.text;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    final filled = i < value.length;
                    final active = i == value.length && enabled;
                    return _CodeBox(
                      digit: filled ? value[i] : '',
                      active: active,
                    );
                  }),
                );
              },
            ),
          ),
        ),
        // Real tap target on top so taps focus the hidden field.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: enabled ? () => focus.requestFocus() : null,
          ),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  final String digit;
  final bool active;

  const _CodeBox({required this.digit, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? MomentoTheme.coral
              : MomentoTheme.deepPlum.withValues(alpha: 0.12),
          width: active ? 2 : 1,
        ),
      ),
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: MomentoTheme.deepPlum,
        ),
      ),
    );
  }
}
