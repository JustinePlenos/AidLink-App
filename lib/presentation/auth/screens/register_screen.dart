import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/input/app_input_formatters.dart';
import '../../../data/services/aidlink_api.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/widgets/app_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _suffix = TextEditingController();
  final _street = TextEditingController();
  final _subdivision = TextEditingController();
  final _barangay = TextEditingController();
  final _district = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _birthDate = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _submitting = false;
  bool _dirty = false;

  Iterable<TextEditingController> get _controllers => [
    _lastName,
    _firstName,
    _middleName,
    _suffix,
    _street,
    _subdivision,
    _barangay,
    _district,
    _contact,
    _email,
    _birthDate,
    _password,
    _confirmPassword,
  ];

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_dirty && _controllers.any((item) => item.text.isNotEmpty)) {
      setState(() => _dirty = true);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_markDirty);
      controller.dispose();
    }
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (_submitting) return false;
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Discard registration?'),
            content: const Text(
              'The information you entered has not been saved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      final accepted = await _showConsent();
      if (!accepted || !mounted) return;
      await context.read<AppProvider>().register(
        RequestorProfile(
          lastName: _lastName.text.trim(),
          firstName: _firstName.text.trim(),
          middleName: _middleName.text.trim(),
          suffix: _suffix.text.trim(),
          street: _street.text.trim(),
          subdivision: _subdivision.text.trim(),
          barangay: _barangay.text.trim(),
          district: _district.text.trim(),
          contactNumber: _contact.text.trim(),
          email: _email.text.trim(),
          birthDate: _toIsoDate(_birthDate.text.trim()),
        ),
        password: _password.text,
      );
      if (!mounted) return;
      _dirty = false;
      final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Basic account created. Upload a government ID to unlock assistance requests.',
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
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not complete registration. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _showConsent() async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm registration'),
          content: const SingleChildScrollView(
            child: Text(
              'I confirm that the information is true and correct. I consent to AidLink collecting and using this personal information to create my account and process LINGAP services.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Review details'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Agree and register'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty,
    onPopInvokedWithResult: (didPop, _) async {
      if (!didPop && await _confirmDiscard() && context.mounted) {
        Navigator.pop(context);
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Applicant registration')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const PageHeading(
                title: 'Create your account',
                description:
                    'Register the person who will submit and track assistance requests. Required fields are marked with an asterisk.',
              ),
              const SizedBox(height: 28),
              _section(
                context,
                'Identity',
                'Use the name shown on your government-issued ID.',
              ),
              _field(_lastName, 'Last name'),
              _field(_firstName, 'First name'),
              _field(_middleName, 'Middle name', required: false),
              _field(_suffix, 'Suffix', required: false, hint: 'JR., SR., III'),
              const SizedBox(height: 8),
              _section(
                context,
                'Residential address',
                'Provide your current Davao City address.',
              ),
              _field(_street, 'House no. / Street'),
              _field(_subdivision, 'Subdivision / Village', required: false),
              _field(_barangay, 'Barangay'),
              _field(_district, 'District'),
              const SizedBox(height: 8),
              _section(
                context,
                'Contact information',
                'AidLink uses these details for request updates.',
              ),
              _field(
                _contact,
                'Mobile number',
                type: TextInputType.phone,
                capitalization: TextCapitalization.none,
                format: false,
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^\+?[0-9 ]{10,15}$').hasMatch(value.trim())
                    ? 'Enter a valid mobile number.'
                    : null,
              ),
              _field(
                _email,
                'Email address',
                type: TextInputType.emailAddress,
                capitalization: TextCapitalization.none,
                format: false,
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^\S+@\S+\.\S+$').hasMatch(value.trim())
                    ? 'Enter a valid email address.'
                    : null,
              ),
              _field(
                _birthDate,
                'Date of birth',
                hint: 'MM/DD/YYYY',
                type: TextInputType.datetime,
                capitalization: TextCapitalization.none,
                birthDate: true,
                validator: _validateBirthDate,
              ),
              const SizedBox(height: 8),
              _section(
                context,
                'Account security',
                'Use at least 8 characters. You will need this password to sign in again.',
              ),
              _field(
                _password,
                'Password',
                capitalization: TextCapitalization.none,
                format: false,
                obscureText: true,
                validator: (value) => value == null || value.length < 8
                    ? 'Use at least 8 characters.'
                    : null,
              ),
              _field(
                _confirmPassword,
                'Confirm password',
                capitalization: TextCapitalization.none,
                format: false,
                obscureText: true,
                validator: (value) =>
                    value != _password.text ? 'Passwords do not match.' : null,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _register,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
                label: Text(
                  _submitting
                      ? 'Creating account…'
                      : 'Create applicant account',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your information is used only to process and communicate about LINGAP assistance.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _section(BuildContext context, String title, String description) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: SectionHeader(title: title, subtitle: description),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    String? hint,
    TextInputType type = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.characters,
    bool format = true,
    bool birthDate = false,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) => LabeledField(
    label: label,
    required: required,
    child: TextFormField(
      controller: controller,
      enabled: !_submitting,
      keyboardType: type,
      textCapitalization: capitalization,
      obscureText: obscureText,
      enableSuggestions: !obscureText,
      autocorrect: !obscureText,
      inputFormatters: birthDate
          ? const [BirthDateTextFormatter()]
          : format
          ? const [UpperCaseTextFormatter()]
          : null,
      decoration: InputDecoration(hintText: hint),
      validator:
          validator ??
          (value) => required && (value == null || value.trim().isEmpty)
              ? '$label is required.'
              : null,
    ),
  );

  String _toIsoDate(String value) {
    final parts = value.split('/');
    return '${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
  }

  String? _validateBirthDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date of birth is required.';
    }
    final match = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
    ).firstMatch(value.trim());
    if (match == null) return 'Use MM/DD/YYYY.';
    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return 'Enter a valid date.';
    }
    if (date.isAfter(DateTime.now())) return 'Date cannot be in the future.';
    return null;
  }
}
