import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/aidlink_api.dart';
import '../../shared/providers/app_provider.dart';

class MfaChallengeScreen extends StatefulWidget {
  const MfaChallengeScreen({
    super.key,
    required this.challenge,
    this.stepUp = false,
  });

  final ApplicantMfaChallenge challenge;
  final bool stepUp;

  @override
  State<MfaChallengeScreen> createState() => _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends State<MfaChallengeScreen> {
  final _code = TextEditingController();
  late String _method;
  bool _busy = false;
  bool _sendingSms = false;

  @override
  void initState() {
    super.initState();
    _method = widget.challenge.methods.contains('totp')
        ? 'totp'
        : widget.challenge.methods.first;
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _label(String method) => switch (method) {
    'totp' => 'Authenticator app',
    'sms' => 'SMS recovery',
    'recovery_code' => 'Recovery code',
    _ => method,
  };

  String get _instructions => switch (_method) {
    'totp' => 'Enter the current 6-digit code from your authenticator app.',
    'sms' =>
      'Request a code, then enter the 6-digit code sent to ${widget.challenge.maskedPhone}.',
    'recovery_code' =>
      'Enter one unused recovery code. It will be permanently consumed.',
    _ => 'Enter your verification code.',
  };

  Future<void> _requestSms() async {
    if (_sendingSms) return;
    setState(() => _sendingSms = true);
    try {
      await context.read<AppProvider>().requestMfaSms(
        widget.challenge,
        stepUp: widget.stepUp,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification code sent to ${widget.challenge.maskedPhone}.',
          ),
        ),
      );
    } on AidLinkApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingSms = false);
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final provider = context.read<AppProvider>();
      if (widget.stepUp) {
        final token = await provider.completeStepUp(
          challenge: widget.challenge,
          method: _method,
          code: code,
        );
        if (mounted) Navigator.pop(context, token);
      } else {
        await provider.completeMfaLogin(
          challenge: widget.challenge,
          method: _method,
          code: code,
        );
        if (mounted) Navigator.pop(context, true);
      }
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
      appBar: AppBar(
        title: Text(
          widget.stepUp ? 'Verify it is you' : 'Two-step verification',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.phonelink_lock_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.stepUp
                        ? 'Confirm this sensitive change'
                        : 'Complete your sign in',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _instructions,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  if (widget.challenge.methods.length > 1) ...[
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.challenge.methods
                          .map(
                            (method) => ChoiceChip(
                              label: Text(_label(method)),
                              selected: _method == method,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(() {
                                      _method = method;
                                      _code.clear();
                                    }),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_method == 'sms') ...[
                    OutlinedButton.icon(
                      onPressed: _sendingSms || _busy ? null : _requestSms,
                      icon: _sendingSms
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sms_outlined),
                      label: Text(
                        _sendingSms ? 'Sending code…' : 'Send SMS code',
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _code,
                    autofocus: true,
                    enabled: !_busy,
                    textAlign: TextAlign.center,
                    keyboardType: _method == 'recovery_code'
                        ? TextInputType.text
                        : TextInputType.number,
                    textCapitalization: TextCapitalization.characters,
                    autofillHints: _method == 'sms'
                        ? const [AutofillHints.oneTimeCode]
                        : null,
                    decoration: InputDecoration(
                      labelText: _method == 'recovery_code'
                          ? 'Recovery code'
                          : '6-digit verification code',
                      prefixIcon: const Icon(Icons.key_rounded),
                    ),
                    onSubmitted: (_) => _verify(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _verify,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.verified_user_outlined),
                    label: Text(_busy ? 'Verifying…' : 'Verify and continue'),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 17,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AidLink personnel will never ask for your password, authenticator code, SMS OTP, or recovery code.',
                          style: TextStyle(
                            fontSize: 12,
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
  );
}
