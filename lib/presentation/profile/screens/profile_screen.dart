import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/aidlink_api.dart';
import '../../history/screens/application_history_screen.dart';
import '../../settings/screens/server_settings_screen.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/widgets/app_ui.dart';
import 'mfa_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final requestor = provider.requestor;
    if (requestor == null) return const SizedBox.shrink();
    final address = [
      requestor.street,
      requestor.subdivision,
      requestor.barangay,
      requestor.district,
    ].where((item) => item.trim().isNotEmpty).join(', ');
    final initial = requestor.firstName.trim().isEmpty
        ? 'A'
        : requestor.firstName.trim()[0].toUpperCase();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const PageHeading(
          title: 'Account',
          description: 'Manage your profile, documents, and account security.',
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requestor.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      requestor.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    const StatusBadge(status: 'approved'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Applicant information'),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.home_outlined,
                label: 'Residential address',
                value: address,
              ),
              const Divider(),
              _InfoTile(
                icon: Icons.phone_outlined,
                label: 'Mobile number',
                value: requestor.contactNumber,
              ),
              const Divider(),
              _InfoTile(
                icon: Icons.mail_outline_rounded,
                label: 'Email address',
                value: requestor.email,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Services and settings'),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.qr_code_2_rounded,
                title: 'Verification center',
                subtitle: 'Approved QR codes and guarantee letters',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const VerificationCenterScreen(),
                  ),
                ),
              ),
              const Divider(),
              _ActionTile(
                icon: Icons.dns_outlined,
                title: 'App connection',
                subtitle: 'Change only when instructed by support',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ServerSettingsScreen(),
                  ),
                ),
              ),
              const Divider(),
              _ActionTile(
                icon: Icons.shield_outlined,
                title: 'Privacy and security',
                subtitle: 'Authenticator MFA, recovery, and password',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const MfaSettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: Color(0xFFFECACA)),
          ),
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out of AidLink'),
        ),
        const SizedBox(height: 14),
        const Text(
          'AidLink Applicant',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need your registered email address to access this account again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    await context.read<AppProvider>().logout();
    if (navigator.mounted) navigator.popUntil((route) => route.isFirst);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.textMuted, size: 21),
    title: Text(
      label,
      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
    ),
    subtitle: Text(
      value.isEmpty ? 'Not provided' : value,
      style: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 64,
    leading: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.primary, size: 19),
    ),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: onTap == null
        ? null
        : const Icon(Icons.chevron_right_rounded, color: AppColors.textSubtle),
    onTap: onTap,
  );
}

class VerificationCenterScreen extends StatelessWidget {
  const VerificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context
        .watch<AppProvider>()
        .applicantRequests
        .where((item) => item.status == 'approved')
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Verification center')),
      body: requests.isEmpty
          ? const StateView(
              icon: Icons.qr_code_2_rounded,
              title: 'No approved requests yet',
              message:
                  'QR verification and guarantee letters appear here after a request is approved.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) =>
                  _VerificationRequest(request: requests[index]),
            ),
    );
  }
}

class _VerificationRequest extends StatelessWidget {
  const _VerificationRequest({required this.request});
  final ApplicantRequest request;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ApplicantRequestDetailsScreen(request: request),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.verified_outlined, color: AppColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.assistanceType,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              MonoText(
                request.id,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textSubtle),
      ],
    ),
  );
}
