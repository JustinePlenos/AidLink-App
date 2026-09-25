import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/aidlink_api.dart';
import '../../auth/screens/mfa_challenge_screen.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/widgets/app_ui.dart';

class MfaSettingsScreen extends StatefulWidget {
  const MfaSettingsScreen({super.key});

  @override
  State<MfaSettingsScreen> createState() => _MfaSettingsScreenState();
}

class _MfaSettingsScreenState extends State<MfaSettingsScreen> {
  ApplicantMfaStatus? _status;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await context.read<AppProvider>().getMfaStatus();
      if (mounted) setState(() => _status = status);
    } on AidLinkApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _promptPassword() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm your password'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Current password',
            prefixIcon: Icon(Icons.password_rounded),
          ),
          onSubmitted: (value) =>
              Navigator.pop(dialogContext, value.isEmpty ? null : value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.isEmpty ? null : controller.text,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<String?> _obtainStepUpToken() async {
    final password = await _promptPassword();
    if (password == null || !mounted) return null;
    final start = await context.read<AppProvider>().startStepUp(password);
    if (start.stepUpToken?.isNotEmpty == true) return start.stepUpToken;
    final challenge = start.challenge;
    if (challenge == null || !mounted) return null;
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => MfaChallengeScreen(challenge: challenge, stepUp: true),
      ),
    );
  }

  Future<void> _enable() async {
    final password = await _promptPassword();
    if (password == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final enrollment = await context.read<AppProvider>().startMfaEnrollment(
        password,
      );
      if (!mounted) return;
      final status = await Navigator.push<ApplicantMfaStatus>(
        context,
        MaterialPageRoute(
          builder: (_) => TotpEnrollmentScreen(enrollment: enrollment),
        ),
      );
      if (status != null && mounted) setState(() => _status = status);
    } on AidLinkApiException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _regenerate() async {
    setState(() => _busy = true);
    try {
      final token = await _obtainStepUpToken();
      if (token == null || !mounted) return;
      final result = await context.read<AppProvider>().regenerateRecoveryCodes(
        token,
      );
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => RecoveryCodesScreen(codes: result.recoveryCodes),
        ),
      );
      if (mounted) setState(() => _status = result.status);
    } on AidLinkApiException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    setState(() => _busy = true);
    try {
      final token = await _obtainStepUpToken();
      if (token == null || !mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Turn off MFA?'),
          content: const Text(
            'Your authenticator and current recovery codes will stop working. Password verification will still be required for sensitive changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Turn off MFA'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final status = await context.read<AppProvider>().disableMfa(token);
      if (mounted) setState(() => _status = status);
    } on AidLinkApiException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptNewPassword() async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: password,
                autofocus: true,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmation,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (password.text.length < 8) {
                  setDialogState(() => error = 'Use at least 8 characters.');
                } else if (password.text != confirmation.text) {
                  setDialogState(() => error = 'Passwords do not match.');
                } else {
                  Navigator.pop(dialogContext, password.text);
                }
              },
              child: const Text('Change password'),
            ),
          ],
        ),
      ),
    );
    password.dispose();
    confirmation.dispose();
    return result;
  }

  Future<void> _changePassword() async {
    setState(() => _busy = true);
    try {
      final token = await _obtainStepUpToken();
      if (token == null || !mounted) return;
      final newPassword = await _promptNewPassword();
      if (newPassword == null || !mounted) return;
      await context.read<AppProvider>().changePassword(
        stepUpToken: token,
        newPassword: newPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed securely.')),
      );
    } on AidLinkApiException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<({String email, String phone})?> _promptContact() async {
    final requestor = context.read<AppProvider>().requestor;
    final email = TextEditingController(text: requestor?.email ?? '');
    final phone = TextEditingController(text: requestor?.contactNumber ?? '');
    String? error;
    final result = await showDialog<({String email, String phone})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update contact details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile number',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final emailValue = email.text.trim();
                final phoneValue = phone.text.trim();
                if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(emailValue)) {
                  setDialogState(() => error = 'Enter a valid email address.');
                } else if (phoneValue.isEmpty) {
                  setDialogState(() => error = 'Enter a mobile number.');
                } else {
                  Navigator.pop(dialogContext, (
                    email: emailValue,
                    phone: phoneValue,
                  ));
                }
              },
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
    email.dispose();
    phone.dispose();
    return result;
  }

  Future<void> _changeContact() async {
    setState(() => _busy = true);
    try {
      final token = await _obtainStepUpToken();
      if (token == null || !mounted) return;
      final contact = await _promptContact();
      if (contact == null || !mounted) return;
      await context.read<AppProvider>().updateApplicantContact(
        stepUpToken: token,
        email: contact.email,
        phone: contact.phone,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact details updated securely.')),
      );
      await _load();
    } on AidLinkApiException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy and security')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? StateView(
            icon: Icons.error_outline,
            title: 'Security settings unavailable',
            message: _error!,
            actionLabel: 'Try again',
            onAction: _load,
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const PageHeading(
                title: 'Multi-factor authentication',
                description:
                    'Use an authenticator app as your primary second factor. SMS is available only as a recovery or accessibility fallback.',
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _status!.enabled
                              ? Icons.verified_user_rounded
                              : Icons.security_outlined,
                          color: _status!.enabled
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _status!.enabled
                                ? 'Authenticator MFA is on'
                                : 'Authenticator MFA is off',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _status!.enabled
                          ? 'Primary method: TOTP authenticator app\nSMS fallback: ${_status!.smsFallbackAvailable ? 'Available' : 'Unavailable'}\nUnused recovery codes: ${_status!.recoveryCodesRemaining}'
                          : 'Enable MFA to require a rotating authenticator code after your password.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    if (!_status!.enabled)
                      FilledButton.icon(
                        onPressed: _busy ? null : _enable,
                        icon: const Icon(Icons.add_moderator_outlined),
                        label: const Text('Set up authenticator app'),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _regenerate,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('New recovery codes'),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _disable,
                            child: const Text('Turn off MFA'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sensitive account changes',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Changing your password, email, phone number, or recovery settings requires fresh password and MFA verification. Step-up approval expires after five minutes and can be used once.',
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _changePassword,
                      icon: const Icon(Icons.password_rounded),
                      label: const Text('Change password'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _changeContact,
                      icon: const Icon(Icons.contact_phone_outlined),
                      label: const Text('Change email or phone'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Keep recovery codes offline and private. AidLink personnel will never ask for passwords, OTPs, authenticator codes, or recovery codes.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
  );
}

class TotpEnrollmentScreen extends StatefulWidget {
  const TotpEnrollmentScreen({super.key, required this.enrollment});
  final ApplicantMfaEnrollment enrollment;

  @override
  State<TotpEnrollmentScreen> createState() => _TotpEnrollmentScreenState();
}

class _TotpEnrollmentScreenState extends State<TotpEnrollmentScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_code.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await context.read<AppProvider>().confirmMfaEnrollment(
        _code.text.trim(),
      );
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => RecoveryCodesScreen(codes: result.recoveryCodes),
        ),
      );
      if (mounted) Navigator.pop(context, result.status);
    } on AidLinkApiException catch (error) {
      if (!mounted) return;
      _code.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Set up authenticator')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            '1. Scan this code',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Use Google Authenticator, Microsoft Authenticator, 1Password, or another TOTP-compatible app.',
          ),
          const SizedBox(height: 16),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: widget.enrollment.otpauthUri,
                  size: 220,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Cannot scan? Enter this setup key manually:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          SelectableText(
            widget.enrollment.secret,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            '2. Confirm the current code',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _code,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: const InputDecoration(
              labelText: '6-digit authenticator code',
            ),
            onSubmitted: (_) => _confirm(),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _busy ? null : _confirm,
            child: Text(_busy ? 'Verifying…' : 'Enable MFA'),
          ),
        ],
      ),
    ),
  );
}

class RecoveryCodesScreen extends StatefulWidget {
  const RecoveryCodesScreen({super.key, required this.codes});
  final List<String> codes;

  @override
  State<RecoveryCodesScreen> createState() => _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends State<RecoveryCodesScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _saved,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Save recovery codes'),
        automaticallyImplyLeading: _saved,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Icon(Icons.key_rounded, size: 44, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'These codes are shown only once',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Store them in a password manager or another secure offline location. Each code works once.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          AppCard(
            child: SelectableText(
              widget.codes.join('\n'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                height: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: widget.codes.join('\n')),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recovery codes copied.')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy codes'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _saved,
            onChanged: (value) => setState(() => _saved = value ?? false),
            title: const Text('I saved these codes in a secure place'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          FilledButton(
            onPressed: _saved ? () => Navigator.pop(context) : null,
            child: const Text('Finish'),
          ),
        ],
      ),
    ),
  );
}
