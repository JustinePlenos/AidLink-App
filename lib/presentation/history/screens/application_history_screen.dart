import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/assistance_types.dart';
import '../../../data/services/aidlink_api.dart';
import '../../application/screens/apply_assistance_screen.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/widgets/app_ui.dart';

enum _RequestSort { newest, oldest, status }

class ApplicationHistoryScreen extends StatefulWidget {
  const ApplicationHistoryScreen({super.key});

  @override
  State<ApplicationHistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends State<ApplicationHistoryScreen> {
  static const _pageSize = 10;
  final _search = TextEditingController();
  final Set<String> _statuses = {};
  _RequestSort _sort = _RequestSort.newest;
  int _visible = _pageSize;
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await context.read<AppProvider>().refreshApplicantRequests();
      if (mounted) setState(() => _error = null);
    } on AidLinkApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  List<ApplicantRequest> _items(AppProvider provider) {
    final localRequests = provider.applications.map(
      (item) => ApplicantRequest(
        id: item.referenceNumber,
        requestId: item.referenceNumber,
        assistanceType: item.assistanceType,
        dateSubmitted: item.submittedAt,
        status: normalizeStatus(item.status),
        remarks: item.remarks,
        guaranteeLetter: item.guaranteeLetterUrl.isEmpty
            ? null
            : GuaranteeLetter(
                name: 'Guarantee Letter',
                url: item.guaranteeLetterUrl,
              ),
        qrCode: item.qrCode.isEmpty
            ? null
            : QrCodeData(
                value: item.qrCode,
                imageDataUrl: item.qrCodeImageDataUrl,
              ),
      ),
    );
    final uniqueRequests = deduplicateApplicantRequests([
      ...provider.applicantRequests,
      ...localRequests,
    ]);
    final query = _search.text.trim().toLowerCase();
    final result = uniqueRequests.where((item) {
      final matchesQuery =
          query.isEmpty ||
          '${item.id} ${item.stableId} ${item.assistanceType} ${item.remarks}'
              .toLowerCase()
              .contains(query);
      return matchesQuery &&
          (_statuses.isEmpty || _statuses.contains(item.status));
    }).toList();
    result.sort(
      (a, b) => switch (_sort) {
        _RequestSort.newest => b.dateSubmitted.compareTo(a.dateSubmitted),
        _RequestSort.oldest => a.dateSubmitted.compareTo(b.dateSubmitted),
        _RequestSort.status => statusLabel(
          a.status,
        ).compareTo(statusLabel(b.status)),
      },
    );
    return result;
  }

  void _reset() => setState(() {
    _search.clear();
    _statuses.clear();
    _sort = _RequestSort.newest;
    _visible = _pageSize;
  });

  Future<void> _showFilters() async {
    final selected = Set<String>.from(_statuses);
    var sort = _sort;
    final result = await showModalBottomSheet<(Set<String>, _RequestSort)>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter requests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Select one or more statuses.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ...[
                  'pending',
                  'under_review',
                  'correction_requested',
                  'approved',
                  'ready_for_claiming',
                  'denied',
                ].map(
                  (status) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: selected.contains(status),
                    title: Text(statusLabel(status)),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) => update(
                      () => value == true
                          ? selected.add(status)
                          : selected.remove(status),
                    ),
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  'Sort by',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<_RequestSort>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _RequestSort.newest,
                      label: Text('Newest'),
                    ),
                    ButtonSegment(
                      value: _RequestSort.oldest,
                      label: Text('Oldest'),
                    ),
                    ButtonSegment(
                      value: _RequestSort.status,
                      label: Text('Status'),
                    ),
                  ],
                  selected: {sort},
                  onSelectionChanged: (value) =>
                      update(() => sort = value.first),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          selected.clear();
                          update(() {});
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext, (selected, sort)),
                        child: const Text('Apply filters'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _statuses
          ..clear()
          ..addAll(result.$1);
        _sort = result.$2;
        _visible = _pageSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final items = _items(provider);
    final hasFilters =
        _search.text.trim().isNotEmpty ||
        _statuses.isNotEmpty ||
        _sort != _RequestSort.newest;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            sliver: SliverList.list(
              children: [
                PageHeading(
                  title: 'Requests',
                  description:
                      'Search, track, and review your LINGAP assistance history.',
                  action: IconButton.filled(
                    tooltip: 'New assistance request',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ApplyAssistanceScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() => _visible = _pageSize),
                        decoration: InputDecoration(
                          hintText: 'Search by ID or assistance type',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() {});
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Badge(
                      isLabelVisible: _statuses.isNotEmpty,
                      label: Text('${_statuses.length}'),
                      child: IconButton.outlined(
                        tooltip: 'Filter and sort',
                        onPressed: _showFilters,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ),
                  ],
                ),
                if (_statuses.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: _statuses
                        .map(
                          (status) => InputChip(
                            label: Text(statusLabel(status)),
                            onDeleted: () =>
                                setState(() => _statuses.remove(status)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (provider.loadingRequests &&
              provider.applicantRequests.isEmpty &&
              provider.applications.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.list(
                children: const [
                  SkeletonCard(),
                  SizedBox(height: 12),
                  SkeletonCard(),
                  SizedBox(height: 12),
                  SkeletonCard(),
                ],
              ),
            )
          else if (_error != null && items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: StateView(
                icon: isOfflineMessage(_error!)
                    ? Icons.cloud_off_outlined
                    : Icons.error_outline_rounded,
                title: isOfflineMessage(_error!)
                    ? 'Unable to connect'
                    : 'Requests could not be loaded',
                message: isOfflineMessage(_error!)
                    ? 'Check your connection and try again. Your saved requests remain available.'
                    : 'AidLink could not retrieve your requests. Please try again.',
                actionLabel: 'Try again',
                onAction: _refresh,
              ),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: StateView(
                icon: hasFilters
                    ? Icons.search_off_rounded
                    : Icons.description_outlined,
                title: hasFilters ? 'No results found' : 'No requests yet',
                message: hasFilters
                    ? 'No assistance requests match the current search and filters.'
                    : 'Your submitted LINGAP requests will appear here.',
                actionLabel: hasFilters ? 'Reset filters' : 'Start a request',
                onAction: hasFilters
                    ? _reset
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ApplyAssistanceScreen(),
                        ),
                      ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList.separated(
                itemCount:
                    (items.length > _visible ? _visible : items.length) +
                    (items.length > _visible ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  if (index >= _visible) {
                    return OutlinedButton(
                      onPressed: () => setState(() => _visible += _pageSize),
                      child: Text(
                        'Load more (${items.length - _visible} remaining)',
                      ),
                    );
                  }
                  return RequestCard(
                    request: items[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ApplicantRequestDetailsScreen(
                          request: items[index],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, required this.onTap});
  final ApplicantRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                request.assistanceType.isEmpty
                    ? 'Assistance request'
                    : request.assistanceType,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 10),
            StatusBadge(status: request.status),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.tag_rounded,
              size: 15,
              color: AppColors.textSubtle,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: MonoText(
                request.stableId,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.textSubtle,
            ),
            const SizedBox(width: 6),
            Text(
              'Submitted ${formatDate(request.dateSubmitted, time: true)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSubtle,
            ),
          ],
        ),
        if (request.remarks.trim().isNotEmpty) ...[
          const Divider(height: 22),
          Text(
            request.remarks,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );
}

class ApplicantRequestDetailsScreen extends StatefulWidget {
  const ApplicantRequestDetailsScreen({super.key, required this.request});
  final ApplicantRequest request;

  @override
  State<ApplicantRequestDetailsScreen> createState() =>
      _ApplicantRequestDetailsScreenState();
}

class _ApplicantRequestDetailsScreenState
    extends State<ApplicantRequestDetailsScreen> {
  late ApplicantRequest _request = widget.request;
  bool _refreshing = false;
  String? _replacingDocumentId;
  bool _submittingCorrections = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final latest = await context.read<AppProvider>().getApplicantRequest(
        _request.id,
      );
      if (mounted) setState(() => _request = latest);
    } on AidLinkApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _replaceCorrectionDocument(
    CorrectionDocumentRequest requested,
  ) async {
    const documentTypes = XTypeGroup(
      label: 'Documents',
      extensions: ['jpg', 'jpeg', 'png', 'pdf'],
      uniformTypeIdentifiers: ['public.jpeg', 'public.png', 'com.adobe.pdf'],
      mimeTypes: ['image/jpeg', 'image/png', 'application/pdf'],
    );
    final file = await openFile(acceptedTypeGroups: const [documentTypes]);
    if (file == null || !mounted) return;
    setState(() => _replacingDocumentId = requested.documentId);
    try {
      final provider = context.read<AppProvider>();
      final analysis = await provider.analyzeDocument(
        file: file,
        documentType: requested.documentType,
      );
      if (!mounted) return;
      if (!analysis.accepted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Choose another document'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...analysis.issues.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '• ${issue.message}\nHow to fix it: ${issue.fix}',
                      ),
                    ),
                  ),
                  if (analysis.warnings.isNotEmpty)
                    ...analysis.warnings.map((warning) => Text('• $warning')),
                  const SizedBox(height: 8),
                  const Text(
                    'This checks technical quality only and does not verify authenticity.',
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Choose replacement'),
              ),
            ],
          ),
        );
        return;
      }
      final updated = await provider.uploadCorrectionDocument(
        requestId: _request.id,
        documentId: requested.documentId,
        documentType: requested.documentType,
        file: file,
      );
      if (!mounted) return;
      setState(() => _request = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            analysis.warnings.isEmpty
                ? '${requested.label} replacement passed the quality check.'
                : '${requested.label} replacement saved with non-blocking guidance.',
          ),
        ),
      );
    } on AidLinkApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _replacingDocumentId = null);
    }
  }

  Future<void> _submitCorrections() async {
    final correction = _request.correctionRequest;
    if (correction == null || !correction.isComplete) return;
    setState(() => _submittingCorrections = true);
    try {
      final updated = await context.read<AppProvider>().submitCorrections(
        _request.id,
      );
      if (!mounted) return;
      setState(() => _request = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrections submitted. The request is under review.'),
        ),
      );
    } on AidLinkApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _submittingCorrections = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request details'),
        actions: [
          IconButton(
            tooltip: 'Refresh request',
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          request.assistanceType.isEmpty
                              ? 'Assistance request'
                              : request.assistanceType,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusBadge(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'REQUEST ID',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: .8,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: MonoText(
                          request.stableId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy request ID',
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: request.stableId),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Request ID copied.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_outlined, size: 18),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  _row(
                    'Submitted',
                    formatDate(request.dateSubmitted, time: true),
                  ),
                  if (request.approvalDate != null)
                    _row(
                      'Updated',
                      formatDate(request.approvalDate!, time: true),
                    ),
                  if (request.remarks.trim().isNotEmpty)
                    _row('Latest note', request.remarks),
                ],
              ),
            ),
            if (request.assistanceType == legacyMedicineAssistanceType) ...[
              const SizedBox(height: 12),
              const AppCard(
                color: AppColors.warningSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        legacyMedicineAssistanceNotice,
                        style: TextStyle(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (request.status == 'correction_requested' &&
                request.correctionRequest != null) ...[
              const SizedBox(height: 12),
              AppCard(
                color: AppColors.warningSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.edit_document,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Document corrections requested',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(request.correctionRequest!.remark),
                    const SizedBox(height: 6),
                    Text(
                      'Requested by ${request.correctionRequest!.requestedBy}'
                      '${request.correctionRequest!.requestedAt == null ? '' : ' on ${formatDate(request.correctionRequest!.requestedAt!, time: true)}'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    ...request.correctionRequest!.documents.map((document) {
                      final replaced = request.correctionRequest!
                          .hasReplacement(document.documentId);
                      final busy = _replacingDocumentId == document.documentId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(
                              replaced
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.description_outlined,
                              color: replaced
                                  ? AppColors.success
                                  : AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    document.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    replaced
                                        ? 'Replacement uploaded'
                                        : 'Replacement required',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  _replacingDocumentId == null &&
                                      !_submittingCorrections
                                  ? () => _replaceCorrectionDocument(document)
                                  : null,
                              child: busy
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      replaced ? 'Replace again' : 'Replace',
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Text(
                      'Each replacement must be clear and readable. Staff will still review the document.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            request.correctionRequest!.isComplete &&
                                _replacingDocumentId == null &&
                                !_submittingCorrections
                            ? _submitCorrections
                            : null,
                        child: Text(
                          _submittingCorrections
                              ? 'Submitting corrections…'
                              : 'Submit corrections',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Progress',
              subtitle: 'Your request status and next step',
            ),
            const SizedBox(height: 10),
            AppCard(child: RequestTimeline(request: request)),
            if (request.supportingDocuments.isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionHeader(title: 'Submitted documents'),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: _Documents(documents: request.supportingDocuments),
              ),
            ],
            if (request.status == 'ready_for_claiming') ...[
              const SizedBox(height: 20),
              const SectionHeader(title: 'Claiming letter'),
              const SizedBox(height: 10),
              ApprovalVerification(request: request),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class RequestTimeline extends StatelessWidget {
  const RequestTimeline({super.key, required this.request});
  final ApplicantRequest request;

  int get _progress {
    if (request.status == 'ready_for_claiming') return 5;
    if (request.status == 'approved' || request.status == 'denied') return 4;
    if (request.status == 'under_review' ||
        request.status == 'correction_requested') {
      return 2;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Submitted', formatDate(request.dateSubmitted, time: true)),
      ('Documents checked', 'Required files are checked'),
      request.status == 'correction_requested'
          ? (
              'Correction requested',
              request.correctionRequest?.remark ??
                  'Replace the documents identified by the Case Worker',
            )
          : ('Under review', 'A Case Worker is reviewing your request'),
      ('Supporting proof checked', 'Receipt and facility details are checked'),
      (
        request.status == 'denied' ? 'Denied' : 'Approved',
        request.status == 'denied'
            ? 'See the latest note above for guidance'
            : 'Your request was approved',
      ),
      (
        'Claiming preparation',
        request.status == 'ready_for_claiming'
            ? 'Your claiming details and letter are available'
            : 'Claiming details and your letter are prepared after approval',
      ),
    ];
    return Column(
      children: List.generate(steps.length, (index) {
        final complete = index <= _progress;
        final denied = index == 4 && request.status == 'denied';
        final color = denied
            ? AppColors.error
            : (complete ? AppColors.primary : AppColors.borderStrong);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: complete ? color : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: complete
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 13,
                            )
                          : null,
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: index < _progress
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[index].$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: complete
                              ? AppColors.text
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        steps[index].$2,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Documents extends StatelessWidget {
  const _Documents({required this.documents});
  final List<SupportingDocument> documents;

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(documents.length, (index) {
      final item = documents[index];
      return Column(
        children: [
          ListTile(
            leading: Icon(
              item.name.toLowerCase().endsWith('.pdf')
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              color: AppColors.primary,
            ),
            title: Text(
              item.name.isEmpty ? 'Supporting document' : item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.type.isEmpty
                  ? 'Submitted document'
                  : item.type.replaceAll('_', ' '),
            ),
            trailing: item.url.isEmpty
                ? null
                : const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: item.url.isEmpty ? null : () => _openUrl(context, item.url),
          ),
          if (index < documents.length - 1) const Divider(),
        ],
      );
    }),
  );
}

class ApprovalVerification extends StatelessWidget {
  const ApprovalVerification({super.key, required this.request});
  final ApplicantRequest request;

  Uint8List? _image(String value) {
    try {
      final comma = value.indexOf(',');
      return base64Decode(comma < 0 ? value : value.substring(comma + 1));
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = request.qrCode;
    final bytes = qr == null || qr.imageDataUrl.isEmpty
        ? null
        : _image(qr.imageDataUrl);
    return AppCard(
      color: AppColors.successSoft,
      child: Column(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            'Approved and ready',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.success),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use this AidLink QR to view your approved letter. It is not an official client QR.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          if (bytes != null || qr?.value.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Semantics(
              label: 'Letter QR for request ${request.stableId}',
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: bytes != null
                    ? Image.memory(
                        bytes,
                        width: 190,
                        height: 190,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      )
                    : QrImageView(data: qr!.value, size: 190),
              ),
            ),
            if (qr?.value.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              if (Uri.tryParse(qr!.value)?.hasScheme == true)
                TextButton.icon(
                  onPressed: () => _openUrl(context, qr.value),
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('View protected letter'),
                ),
            ],
          ] else ...[
            const SizedBox(height: 14),
            const Text(
              'Your letter QR is not available yet.',
              textAlign: TextAlign.center,
            ),
          ],
          if (request.protectedLetterStatus case final status?) ...[
            const SizedBox(height: 10),
            Text(
              'Protected letter: ${status.replaceAll('_', ' ')}${request.protectedLetterVersion == null ? '' : ' (version ${request.protectedLetterVersion})'}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'The viewer has no download or print buttons, but copying cannot be completely prevented.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          if (request.guaranteeLetter case final letter?) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openGuaranteeLetter(context, letter),
                icon: const Icon(Icons.description_outlined),
                label: const Text('View guarantee letter'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

bool _isImageDocument(GuaranteeLetter letter) {
  return [letter.name, letter.url].any((source) {
    final path =
        Uri.tryParse(source)?.path.toLowerCase() ?? source.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png');
  });
}

Future<void> _openGuaranteeLetter(
  BuildContext context,
  GuaranteeLetter letter,
) async {
  if (!_isImageDocument(letter)) {
    await _openUrl(context, letter.url);
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => _GuaranteeLetterImageScreen(letter: letter),
    ),
  );
}

class _GuaranteeLetterImageScreen extends StatefulWidget {
  const _GuaranteeLetterImageScreen({required this.letter});

  final GuaranteeLetter letter;

  @override
  State<_GuaranteeLetterImageScreen> createState() =>
      _GuaranteeLetterImageScreenState();
}

class _GuaranteeLetterImageScreenState
    extends State<_GuaranteeLetterImageScreen> {
  late Future<Uint8List> _download;

  @override
  void initState() {
    super.initState();
    _download = _load();
  }

  Future<Uint8List> _load() =>
      context.read<AppProvider>().downloadFile(widget.letter.url);

  void _retry() => setState(() => _download = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.letter.name.isEmpty ? 'Guarantee letter' : widget.letter.name,
      ),
      actions: [
        IconButton(
          tooltip: 'Open externally',
          onPressed: () => _openUrl(context, widget.letter.url),
          icon: const Icon(Icons.open_in_new_rounded),
        ),
      ],
    ),
    body: FutureBuilder<Uint8List>(
      future: _download,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          final message = snapshot.error is AidLinkApiException
              ? (snapshot.error! as AidLinkApiException).message
              : 'The guarantee letter could not be loaded.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }
        return ColoredBox(
          color: Colors.black,
          child: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'This image could not be displayed.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _openUrl(BuildContext context, String value) async {
  final resolved = context.read<AppProvider>().resolveApiUrl(value);
  final uri = Uri.tryParse(resolved);
  if (uri == null ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This document could not be opened. Please try again.'),
        ),
      );
    }
  }
}
