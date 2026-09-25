import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard/screens/main_screen.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/widgets/app_ui.dart';
import '../../../data/services/aidlink_api.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/application_intake_options.dart';

enum _DocumentSource { camera, gallery, files }

class UploadRequirementsScreen extends StatefulWidget {
  const UploadRequirementsScreen({
    super.key,
    required this.patient,
    required this.assistanceTitle,
  });

  final PatientDetails patient;
  final String assistanceTitle;

  @override
  State<UploadRequirementsScreen> createState() =>
      _UploadRequirementsScreenState();
}

class _UploadRequirementsScreenState extends State<UploadRequirementsScreen> {
  final Map<String, XFile> _documents = {};
  final Map<String, List<String>> _warnings = {};
  final _additionalDetails = TextEditingController();
  final _facilityName = TextEditingController();
  final _receiptDate = TextEditingController();
  final _receiptReference = TextEditingController();
  List<String> _requirements = const [];
  int _receiptValidityDays = 365;
  bool _loadingRequirements = true;
  String? _requirementsError;
  String _facilityType = 'hospital';
  String? _incomeSource;
  String? _patientCircumstance;
  bool _isPickingFile = false;
  String? _analyzingRequirement;
  bool _isSubmitting = false;
  int _uploadedCount = 0;
  bool _allowPop = false;
  late final String _clientSubmissionId;

  @override
  void initState() {
    super.initState();
    _clientSubmissionId =
        'mobile-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    _loadRequirements();
  }

  Future<void> _loadRequirements() async {
    try {
      final result = await context
          .read<AppProvider>()
          .getApplicationRequirements(widget.assistanceTitle);
      if (!mounted) return;
      setState(() {
        _requirements = result.documents;
        _receiptValidityDays = result.receiptValidityDays;
        _loadingRequirements = false;
        _requirementsError = null;
      });
    } on AidLinkApiException catch (error) {
      if (mounted) {
        setState(() {
          _loadingRequirements = false;
          _requirementsError = error.message;
        });
      }
    }
  }

  @override
  void dispose() {
    _additionalDetails.dispose();
    _facilityName.dispose();
    _receiptDate.dispose();
    _receiptReference.dispose();
    super.dispose();
  }

  String? get _receiptRequirement => _requirements.cast<String?>().firstWhere(
    (item) => RegExp(
      r'receipt|bill|statement|invoice|quotation|contract',
      caseSensitive: false,
    ).hasMatch(item ?? ''),
    orElse: () => null,
  );

  bool get _receiptDetailsComplete =>
      _facilityName.text.trim().isNotEmpty &&
      _receiptDate.text.trim().isNotEmpty &&
      _receiptReference.text.trim().isNotEmpty;
  bool get _isComplete =>
      !_loadingRequirements &&
      _requirements.isNotEmpty &&
      _documents.length == _requirements.length &&
      _receiptRequirement != null &&
      _receiptDetailsComplete;

  Future<void> _pickDocument(String requirement) async {
    setState(() => _isPickingFile = true);
    try {
      const documentTypes = XTypeGroup(
        label: 'Documents',
        extensions: ['jpg', 'jpeg', 'png', 'pdf'],
        uniformTypeIdentifiers: ['public.jpeg', 'public.png', 'com.adobe.pdf'],
        mimeTypes: ['image/jpeg', 'image/png', 'application/pdf'],
      );
      final provider = context.read<AppProvider>();
      final source = await showModalBottomSheet<_DocumentSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a document photo'),
                onTap: () => Navigator.pop(context, _DocumentSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, _DocumentSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('Browse device files'),
                onTap: () => Navigator.pop(context, _DocumentSource.files),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      if (source == null) return;
      XFile? file;
      if (source == _DocumentSource.camera ||
          source == _DocumentSource.gallery) {
        if (source == _DocumentSource.camera) {
          final ready = await showDialog<bool>(
            context: context,
            builder: (_) => const _DocumentCameraGuide(),
          );
          if (ready != true) return;
        }
        final image = await ImagePicker().pickImage(
          source: source == _DocumentSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
        );
        if (image != null) {
          // TODO: Restore optional image cropping after the native cropper
          // crash is resolved and verified on Android devices.
          file = image;
        }
      } else {
        file = await openFile(acceptedTypeGroups: const [documentTypes]);
      }
      if (file != null) {
        final analyzedFile = file;
        final length = await analyzedFile.length();
        if (length > 10 * 1024 * 1024) {
          throw const AidLinkApiException(
            'This file is larger than 10 MB. Choose a smaller JPG, PNG, or PDF.',
          );
        }
        setState(() => _analyzingRequirement = requirement);
        final analysis = await provider.analyzeDocument(
          file: analyzedFile,
          documentType: requirement,
        );
        if (!mounted) return;
        if (!analysis.accepted) {
          await showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Replace this document'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The quality check did not accept this file. Retake or replace it before uploading.',
                  ),
                  if (analysis.issues.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...analysis.issues.map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '• ${issue.message}\nHow to fix it: ${issue.fix}',
                        ),
                      ),
                    ),
                  ],
                  if (analysis.warnings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Additional guidance:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...analysis.warnings.map((warning) => Text('• $warning')),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'This check only measures image quality. Staff will still review the document.',
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Choose replacement'),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _documents[requirement] = analyzedFile;
            _warnings[requirement] = analysis.warnings;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  analysis.warnings.isEmpty
                      ? 'Document is clear enough to upload.'
                      : 'Document saved with warnings. Review them before submitting.',
                ),
              ),
            );
          }
          if (analysis.warnings.isNotEmpty && mounted) {
            await showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Review this document'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Please review these warnings:'),
                    const SizedBox(height: 8),
                    ...analysis.warnings.map((warning) => Text('• $warning')),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Keep and review later'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } on AidLinkApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to select the document. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingFile = false;
          _analyzingRequirement = null;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_isComplete ||
        _incomeSource == null ||
        _patientCircumstance == null ||
        _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    setState(() => _uploadedCount = 0);
    try {
      final provider = context.read<AppProvider>();
      final uploaded = <Map<String, dynamic>>[];
      for (final requirement in _requirements) {
        try {
          uploaded.add(
            await provider.uploadApplicantDocument(
              file: _documents[requirement]!,
              documentType: requirement,
            ),
          );
        } on AidLinkApiException catch (error) {
          setState(() {
            _documents.remove(requirement);
            _warnings.remove(requirement);
          });
          throw AidLinkApiException(
            '$requirement must be replaced. ${error.message}',
          );
        }
        if (mounted) setState(() => _uploadedCount++);
      }
      if (!mounted) return;
      final application = await provider.submitApplication(
        clientSubmissionId: _clientSubmissionId,
        patient: widget.patient,
        assistanceType: widget.assistanceTitle,
        incomeSource: _incomeSource!,
        patientCircumstance: _patientCircumstance!,
        additionalDetails: _additionalDetails.text.trim(),
        documents: uploaded,
        facilityEvidence: {
          'facilityName': _facilityName.text.trim(),
          'facilityType': _facilityType,
          'receiptDate': _receiptDate.text.trim(),
          'referenceNumber': _receiptReference.text.trim(),
          'receiptDocumentId':
              uploaded[_requirements.indexOf(_receiptRequirement!)]['id'],
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Submitted successfully: ${application.referenceNumber}',
          ),
        ),
      );
      setState(() => _allowPop = true);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
        (_) => false,
      );
    } on AidLinkApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reviewAndSubmit() async {
    final patient = widget.patient;
    final address = [
      patient.street,
      patient.subdivision,
      patient.barangay,
      patient.district,
    ].where((part) => part.isNotEmpty).join(', ');
    var consentAccepted = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            title: const Text('Review Request'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _reviewItem('Assistance for', patient.assistanceForLabel),
                    _reviewItem('Beneficiary name', patient.fullName),
                    _reviewItem('Beneficiary address', address),
                    _reviewItem(
                      'Requester’s relationship to beneficiary',
                      patient.relationshipToPatient,
                    ),
                    _reviewItem('Beneficiary sex', patient.sex),
                    _reviewItem('Beneficiary birthdate', patient.birthDate),
                    _reviewItem('Assistance', widget.assistanceTitle),
                    _reviewItem('Source of income', _incomeSource!),
                    _reviewItem(
                      'What happened to the patient',
                      _patientCircumstance!,
                    ),
                    if (_additionalDetails.text.trim().isNotEmpty)
                      _reviewItem(
                        'Additional details',
                        _additionalDetails.text.trim(),
                      ),
                    const Text(
                      'Supporting documents',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._requirements.map(
                      (requirement) => Text(
                        '• $requirement: ${_documents[requirement]!.name}',
                      ),
                    ),
                    const Divider(height: 24),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: consentAccepted,
                      onChanged: (value) => setDialogState(
                        () => consentAccepted = value ?? false,
                      ),
                      title: const Text(
                        'I confirm that the details and documents are accurate, and '
                        'I consent to their use for processing this request.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Edit'),
              ),
              FilledButton(
                onPressed: consentAccepted
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('Confirm and submit'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) await _submit();
  }

  Future<bool> _confirmDiscard() async {
    if (_documents.isEmpty &&
        _incomeSource == null &&
        _patientCircumstance == null &&
        _additionalDetails.text.trim().isEmpty) {
      return true;
    }
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Discard uploaded requirements?'),
            content: const Text(
              'Selected documents and application details will not be saved.',
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

  Widget _reviewItem(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          _allowPop ||
          (_documents.isEmpty &&
              _incomeSource == null &&
              _patientCircumstance == null &&
              _additionalDetails.text.trim().isEmpty),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !await _confirmDiscard() || !mounted) return;
        setState(() => _allowPop = true);
        await Future<void>.delayed(Duration.zero);
        if (mounted) Navigator.pop(this.context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Supporting documents')),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const PageHeading(
              title: 'Upload requirements',
              description:
                  'Upload a clear, complete copy of each required document.',
            ),
            const SizedBox(height: 16),
            AppCard(
              color: AppColors.primarySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.assistanceTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.patient.assistanceForLabel} · Beneficiary: ${widget.patient.fullName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_loadingRequirements)
              const AppCard(
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Loading the required document checklist...'),
                    ),
                  ],
                ),
              ),
            if (_requirementsError case final error?)
              AppCard(
                color: const Color(0xFFFEF2F2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(error),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _loadingRequirements = true;
                          _requirementsError = null;
                        });
                        _loadRequirements();
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            SectionHeader(
              title: 'Required documents',
              subtitle: '${_documents.length} of ${_requirements.length} ready',
            ),
            const SizedBox(height: 10),
            const AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Include every corner, use even lighting, avoid glare or shadows, and check that all text is readable.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ..._requirements.map(_documentTile),
            const SizedBox(height: 8),
            const SectionHeader(
              title: 'Facility receipt details',
              subtitle:
                  'Identify the hospital, pharmacy, or other facility from the uploaded proof.',
            ),
            const SizedBox(height: 10),
            LabeledField(
              label: 'Facility name shown on receipt',
              required: true,
              child: TextField(
                controller: _facilityName,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
              ),
            ),
            LabeledField(
              label: 'Facility type',
              required: true,
              child: DropdownButtonFormField<String>(
                initialValue: _facilityType,
                items: const [
                  DropdownMenuItem(value: 'hospital', child: Text('Hospital')),
                  DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy')),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Other facility'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _facilityType = value ?? 'other'),
              ),
            ),
            LabeledField(
              label: 'Receipt date',
              required: true,
              description:
                  'Use YYYY-MM-DD. Receipts older than $_receiptValidityDays days are rejected.',
              child: TextField(
                controller: _receiptDate,
                keyboardType: TextInputType.datetime,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'YYYY-MM-DD'),
              ),
            ),
            LabeledField(
              label: 'Receipt or transaction reference',
              required: true,
              child: TextField(
                controller: _receiptReference,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            LabeledField(
              label:
                  'What is the source of income of the patient or household?',
              required: true,
              child: DropdownButtonFormField<String>(
                initialValue: _incomeSource,
                isExpanded: true,
                hint: const Text('Select source of income'),
                items: incomeSourceOptions
                    .map(
                      (option) =>
                          DropdownMenuItem(value: option, child: Text(option)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _incomeSource = value),
              ),
            ),
            LabeledField(
              label: 'What happened to the patient?',
              required: true,
              child: DropdownButtonFormField<String>(
                initialValue: _patientCircumstance,
                isExpanded: true,
                hint: const Text('Select what happened'),
                items: patientCircumstanceOptions
                    .map(
                      (option) =>
                          DropdownMenuItem(value: option, child: Text(option)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _patientCircumstance = value),
              ),
            ),
            LabeledField(
              label: 'Additional details',
              description: 'Optional. Add a short explanation if needed.',
              child: TextField(
                controller: _additionalDetails,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Add relevant details (optional)',
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isSubmitting) ...[
              LinearProgressIndicator(
                value: _requirements.isEmpty
                    ? null
                    : _uploadedCount / _requirements.length,
              ),
              const SizedBox(height: 8),
              Text(
                'Uploading ${(_uploadedCount + 1).clamp(1, _requirements.length)} of ${_requirements.length} documents…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed:
                  _isComplete &&
                      _incomeSource != null &&
                      _patientCircumstance != null &&
                      !_isPickingFile &&
                      !_isSubmitting
                  ? _reviewAndSubmit
                  : null,
              child: Text(
                _isSubmitting ? 'Uploading and submitting…' : 'Review request',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentTile(String requirement) {
    final document = _documents[requirement];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            document == null ? Icons.upload_file_outlined : Icons.check_circle,
            color: document == null ? AppColors.primary : AppColors.success,
          ),
          title: Text(requirement),
          subtitle: Text(
            _analyzingRequirement == requirement
                ? 'Analyzing document…'
                : document == null
                ? 'JPG, PNG, or PDF · Maximum 10 MB'
                : (_warnings[requirement]?.isNotEmpty == true
                      ? '${document.name} · review warnings'
                      : document.name),
          ),
          trailing: TextButton(
            onPressed: _isPickingFile ? null : () => _pickDocument(requirement),
            child: Text(document == null ? 'Upload' : 'Replace'),
          ),
        ),
      ),
    );
  }
}

class _DocumentCameraGuide extends StatelessWidget {
  const _DocumentCameraGuide();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Prepare your document'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1.35,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.document_scanner_outlined, size: 54),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Fit all corners inside the frame. Avoid blur, glare, shadows, and cropped edges. Use even light and check that every word is readable.',
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Open camera'),
      ),
    ],
  );
}
