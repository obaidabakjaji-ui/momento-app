import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../legal_urls.dart';
import '../../theme.dart';

class _LegalTapRecognizer extends TapGestureRecognizer {
  _LegalTapRecognizer(VoidCallback onTapHandler) {
    onTap = onTapHandler;
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _loading = false;

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_isSignUp) {
        await _auth.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      } else {
        await _auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _promptPasswordReset() async {
    final l = AppLocalizations.of(context);
    final controller =
        TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.authResetPasswordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.authResetPasswordDescription),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: l.authEmailPlaceholder,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l.authSend),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty || !email.contains('@')) return;
    try {
      await _auth.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.authResetLinkSent(email))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.commonFailedWithError(e.toString()))),
        );
      }
    }
  }

  Widget _buildLegalFooter(BuildContext context) {
    final l = AppLocalizations.of(context);
    final base = TextStyle(
      fontSize: 11,
      color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
    );
    final link = base.copyWith(
      color: MomentoTheme.coral,
      decoration: TextDecoration.underline,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: base,
          children: [
            TextSpan(
              text: _isSignUp
                  ? l.authByCreatingYouAgree
                  : l.authBySigningInYouAgree,
            ),
            TextSpan(
              text: l.authTerms,
              style: link,
              recognizer: _tap(kTermsOfServiceUrl),
            ),
            const TextSpan(text: ' · '),
            TextSpan(
              text: l.authPrivacyPolicy,
              style: link,
              recognizer: _tap(kPrivacyPolicyUrl),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  // Wraps url_launcher tap handling as a TapGestureRecognizer.
  _LegalTapRecognizer _tap(String url) =>
      _LegalTapRecognizer(() => launchUrl(Uri.parse(url)));

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [MomentoTheme.coral, MomentoTheme.warmOrange],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: MomentoTheme.deepPlum,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.appTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 48),

                  // Name field (sign up only)
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: l.authYourName,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          _isSignUp && (v == null || v.trim().isEmpty)
                              ? l.authYourNameHint
                              : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: l.authEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (v) => v == null || !v.contains('@')
                        ? l.authEmailHint
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: l.authPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: (v) => v == null || v.length < 6
                        ? l.authPasswordHint
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _loading ? null : _handleEmailAuth,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isSignUp ? l.authCreateAccount : l.authSignIn),
                  ),
                  if (!_isSignUp) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _promptPasswordReset,
                        child: Text(l.authForgotPassword),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Google sign in
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: Text(l.authContinueWithGoogle),
                  ),
                  const SizedBox(height: 24),

                  // Toggle sign up / sign in
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? l.authAlreadyHaveAccount : l.authNoAccount,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLegalFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
