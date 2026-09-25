import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/aidlink_api.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/widgets/app_ui.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<AppProvider>().refreshIdentityVerification();
    } on AidLinkApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    const types = XTypeGroup(
      label: 'Government-issued ID',
      extensions: ['jpg', 'jpeg', 'png', 'pdf'],
      mimeTypes: ['image/jpeg', 'image/png', 'application/pdf'],
    );
    final file = await openFile(acceptedTypeGroups: const [types]);
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<AppProvider>().uploadIdentityDocument(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID uploaded for review.')),
        );
      }
    } on AidLinkApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final verification = provider.identityVerification;
    final pending = verification.status == 'pending';
    final rejected = verification.status == 'rejected';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your identity'),
        actions: [
          TextButton(
            onPressed: _busy ? null : provider.logout,
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeading(
            title: 'Government ID verification',
            description:
                'Upload a government-issued ID to unlock all applicant features.',
          ),
          const SizedBox(height: 20),
          AppCard(
            color: pending
                ? const Color(0xFFFFFBEB)
                : rejected
                ? const Color(0xFFFEF2F2)
                : AppColors.primarySoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pending
                      ? 'Review pending'
                      : rejected
                      ? 'Verification rejected'
                      : 'ID upload required',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pending
                      ? 'Your ID is waiting for review.'
                      : rejected
                      ? 'Review the note below and upload a clearer or valid replacement ID.'
                      : 'Upload a current government-issued ID that shows your name and photo.',
                ),
                if (verification.documentName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Submitted: ${verification.documentName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                if (verification.decisionNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Review note: ${verification.decisionNotes}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload guidance',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Use a valid government-issued ID. Include all edges, keep the photo and text readable, avoid blur or glare, and upload JPG, PNG, or PDF up to 10 MB. A clear image does not prove that an ID is genuine.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _busy || pending ? null : _upload,
            icon: const Icon(Icons.badge_outlined),
            label: Text(
              rejected ? 'Upload replacement ID' : 'Upload government ID',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh verification status'),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
