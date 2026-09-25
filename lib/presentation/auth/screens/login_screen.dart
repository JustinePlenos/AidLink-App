import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/aidlink_api.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/widgets/app_ui.dart';
import '../../settings/screens/server_settings_screen.dart';
import 'register_screen.dart';
import 'mfa_challenge_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      final signedIn = await context.read<AppProvider>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      if (signedIn) {
        ScaffoldMessenger.of(context).clearSnackBars();
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not find that applicant account. Check the email or register first.',
            ),
          ),
        );
      }
    } on ApplicantMfaChallengeException catch (error) {
      if (!mounted) return;
      final signedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MfaChallengeScreen(challenge: error.challenge),
        ),
      );
      if (!mounted) return;
      if (signedIn == true) {
        ScaffoldMessenger.of(context).clearSnackBars();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AidLinkApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not complete sign-in. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Secure sign in'),
        actions: [
          IconButton(
            tooltip: 'Connection settings',
            icon: const Icon(Icons.dns_outlined),
            onPressed: _submitting
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ServerSettingsScreen(),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Use your applicant email and password to continue.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    LabeledField(
                      label: 'Registered email address',
                      description: 'Enter the email used for registration.',
                      required: true,
                      child: TextFormField(
                        controller: _emailController,
                        enabled: !_submitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        decoration: const InputDecoration(
                          hintText: 'name@example.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) =>
                            value == null ||
                                !RegExp(
                                  r'^\S+@\S+\.\S+$',
                                ).hasMatch(value.trim())
                            ? 'Enter a valid email address.'
                            : null,
                        onFieldSubmitted: (_) => _login(),
                      ),
                    ),
                    LabeledField(
                      label: 'Password',
                      required: true,
                      child: TextFormField(
                        controller: _passwordController,
                        enabled: !_submitting,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.password_rounded),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your password.'
                            : null,
                        onFieldSubmitted: (_) => _login(),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _submitting ? null : _login,
                      icon: _submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login_rounded, size: 19),
                      label: Text(_submitting ? 'Signing in…' : 'Sign in'),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                      child: const Text('Register a new applicant account'),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 15,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Session details are stored securely on this device',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
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
