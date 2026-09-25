import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/input/app_input_formatters.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/widgets/app_ui.dart';
import 'assistance_type_screen.dart';

class ApplyAssistanceScreen extends StatefulWidget {
  const ApplyAssistanceScreen({super.key, this.requestorProfile});

  final RequestorProfile? requestorProfile;

  @override
  State<ApplyAssistanceScreen> createState() => _ApplyAssistanceScreenState();
}

class _ApplyAssistanceScreenState extends State<ApplyAssistanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _suffix = TextEditingController();
  final _street = TextEditingController();
  final _subdivision = TextEditingController();
  final _barangay = TextEditingController();
  final _district = TextEditingController();
  final _relationship = TextEditingController();
  final _birthDate = TextEditingController();
  final Map<String, _BeneficiaryDraft> _drafts = {};
  String? _beneficiaryType;
  String _sex = 'Male';
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
    _relationship,
    _birthDate,
  ];

  @override
  void initState() {
    super.initState();
    for (final item in _controllers) {
      item.addListener(_markDirty);
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

  void _continue() {
    if (_beneficiaryType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose who the assistance is for.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    _dirty = false;
    final patient = PatientDetails(
      beneficiaryType: _beneficiaryType!,
      lastName: _lastName.text.trim(),
      firstName: _firstName.text.trim(),
      middleName: _middleName.text.trim(),
      suffix: _suffix.text.trim(),
      street: _street.text.trim(),
      subdivision: _subdivision.text.trim(),
      barangay: _barangay.text.trim(),
      district: _district.text.trim(),
      relationshipToPatient:
          _beneficiaryType == PatientDetails.beneficiaryTypeSelf
          ? 'Self'
          : _relationship.text.trim(),
      sex: _sex,
      birthDate: _toIsoDate(_birthDate.text.trim()),
    );
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AssistanceTypeScreen(patient: patient),
      ),
    );
  }

  RequestorProfile? get _requestorProfile =>
      widget.requestorProfile ?? context.read<AppProvider>().requestor;

  bool get _hasEnteredDetails =>
      _controllers.any((controller) => controller.text.trim().isNotEmpty);

  _BeneficiaryDraft _captureDraft() => _BeneficiaryDraft(
    lastName: _lastName.text,
    firstName: _firstName.text,
    middleName: _middleName.text,
    suffix: _suffix.text,
    street: _street.text,
    subdivision: _subdivision.text,
    barangay: _barangay.text,
    district: _district.text,
    relationship: _relationship.text,
    birthDate: _birthDate.text,
    sex: _sex,
  );

  _BeneficiaryDraft _draftFromProfile(RequestorProfile profile) =>
      _BeneficiaryDraft(
        lastName: profile.lastName,
        firstName: profile.firstName,
        middleName: profile.middleName,
        suffix: profile.suffix,
        street: profile.street,
        subdivision: profile.subdivision,
        barangay: profile.barangay,
        district: profile.district,
        relationship: 'Self',
        birthDate: _toDisplayDate(profile.birthDate),
        sex: 'Male',
      );

  String _toDisplayDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  void _restoreDraft(_BeneficiaryDraft draft) {
    _lastName.text = draft.lastName;
    _firstName.text = draft.firstName;
    _middleName.text = draft.middleName;
    _suffix.text = draft.suffix;
    _street.text = draft.street;
    _subdivision.text = draft.subdivision;
    _barangay.text = draft.barangay;
    _district.text = draft.district;
    _relationship.text = draft.relationship;
    _birthDate.text = draft.birthDate;
    _sex = draft.sex;
  }

  Future<void> _selectBeneficiaryType(String nextType) async {
    if (nextType == _beneficiaryType) return;
    if (_beneficiaryType != null && _hasEnteredDetails) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Switch who needs assistance?'),
          content: const Text(
            'The details you entered will be kept and restored if you switch back. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep editing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Switch'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    if (_beneficiaryType != null) {
      _drafts[_beneficiaryType!] = _captureDraft();
    }
    var nextDraft = _drafts[nextType];
    if (nextDraft == null && nextType == PatientDetails.beneficiaryTypeSelf) {
      final profile = _requestorProfile;
      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your applicant profile could not be loaded. Sign in again and retry.',
            ),
          ),
        );
        return;
      }
      nextDraft = _draftFromProfile(profile);
    }
    nextDraft ??= const _BeneficiaryDraft();
    setState(() {
      _beneficiaryType = nextType;
      _restoreDraft(nextDraft!);
      _dirty = true;
    });
  }

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

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this request?'),
        content: const Text(
          'The patient details you entered have not been saved.',
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
    );
    if (result == true) _dirty = false;
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty,
    onPopInvokedWithResult: (didPop, _) async {
      if (!didPop && await _confirmDiscard() && context.mounted) {
        Navigator.pop(context);
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('New request')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const PageHeading(
                title: 'Who needs assistance?',
                description:
                    'Choose who the request is for before entering beneficiary details.',
              ),
              const SizedBox(height: 18),
              const _StepIndicator(current: 1),
              const SizedBox(height: 26),
              const SectionHeader(
                title: 'Who is the assistance for?',
                subtitle:
                    'The signed-in applicant remains the requester for either choice.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _modeButton(
                      PatientDetails.beneficiaryTypeSelf,
                      'For myself',
                      Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _modeButton(
                      PatientDetails.beneficiaryTypeOther,
                      'For someone else',
                      Icons.people_outline,
                    ),
                  ),
                ],
              ),
              if (_beneficiaryType == null) ...[
                const SizedBox(height: 18),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Select an option to continue to beneficiary details.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
              if (_beneficiaryType != null) ...[
                const SizedBox(height: 26),
                const SectionHeader(
                  title: 'Beneficiary identity',
                  subtitle: 'Enter the name shown on the patient’s ID.',
                ),
                const SizedBox(height: 14),
                _field(_lastName, 'Beneficiary last name'),
                _field(_firstName, 'Beneficiary first name'),
                _field(_middleName, 'Beneficiary middle name', required: false),
                _field(
                  _suffix,
                  'Beneficiary suffix',
                  required: false,
                  hint: 'JR., SR., III',
                ),
                const SizedBox(height: 8),
                const SectionHeader(title: 'Beneficiary residential address'),
                const SizedBox(height: 14),
                _field(_street, 'House no. / Street'),
                _field(_subdivision, 'Subdivision / Village', required: false),
                _field(_barangay, 'Barangay'),
                _field(_district, 'District'),
                const SizedBox(height: 8),
                const SectionHeader(title: 'Beneficiary personal information'),
                const SizedBox(height: 14),
                _field(
                  _relationship,
                  'Requester’s relationship to beneficiary',
                  description:
                      _beneficiaryType == PatientDetails.beneficiaryTypeSelf
                      ? 'This request is for the signed-in applicant.'
                      : 'For example: Parent, spouse, child, or guardian.',
                  readOnly:
                      _beneficiaryType == PatientDetails.beneficiaryTypeSelf,
                ),
                LabeledField(
                  label: 'Beneficiary sex',
                  required: true,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('beneficiary-sex-$_beneficiaryType'),
                    initialValue: _sex,
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (value) => setState(() {
                      _sex = value!;
                      _dirty = true;
                    }),
                  ),
                ),
                LabeledField(
                  label: 'Beneficiary date of birth',
                  description: 'Use month/day/year format.',
                  required: true,
                  child: TextFormField(
                    key: const ValueKey('Beneficiary date of birth'),
                    controller: _birthDate,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: const [BirthDateTextFormatter()],
                    decoration: const InputDecoration(
                      hintText: 'MM/DD/YYYY',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: _validateBirthDate,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continue to assistance type'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    String? hint,
    String? description,
    TextCapitalization capitalization = TextCapitalization.characters,
    bool format = true,
    bool readOnly = false,
  }) => LabeledField(
    label: label,
    description: description,
    required: required,
    child: TextFormField(
      key: ValueKey(label),
      controller: controller,
      readOnly: readOnly,
      textCapitalization: capitalization,
      inputFormatters: format ? const [UpperCaseTextFormatter()] : null,
      decoration: InputDecoration(hintText: hint),
      validator: (value) => required && (value == null || value.trim().isEmpty)
          ? '$label is required.'
          : null,
    ),
  );

  Widget _modeButton(String value, String label, IconData icon) {
    final selected = _beneficiaryType == value;
    return OutlinedButton.icon(
      onPressed: () => _selectBeneficiaryType(value),
      icon: Icon(selected ? Icons.check_circle : icon),
      label: Text(label, textAlign: TextAlign.center),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        backgroundColor: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : null,
        foregroundColor: selected ? AppColors.primary : AppColors.text,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.borderStrong,
          width: selected ? 2 : 1,
        ),
      ),
    );
  }
}

class _BeneficiaryDraft {
  const _BeneficiaryDraft({
    this.lastName = '',
    this.firstName = '',
    this.middleName = '',
    this.suffix = '',
    this.street = '',
    this.subdivision = '',
    this.barangay = '',
    this.district = '',
    this.relationship = '',
    this.birthDate = '',
    this.sex = 'Male',
  });

  final String lastName;
  final String firstName;
  final String middleName;
  final String suffix;
  final String street;
  final String subdivision;
  final String barangay;
  final String district;
  final String relationship;
  final String birthDate;
  final String sex;
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(3, (index) {
      final step = index + 1;
      final active = step <= current;
      return Expanded(
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.borderStrong,
                ),
              ),
              child: Text(
                '$step',
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (index < 2)
              Expanded(
                child: Container(
                  height: 1,
                  color: active && step < current
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
          ],
        ),
      );
    }),
  );
}
