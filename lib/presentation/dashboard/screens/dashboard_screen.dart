import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/aidlink_api.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/widgets/app_ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onNewRequest,
    required this.onViewRequests,
  });
  final VoidCallback onNewRequest;
  final VoidCallback onViewRequests;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final requestor = provider.requestor;
    final requests = provider.applicantRequests;
    final active = requests
        .where(
          (item) => item.status == 'pending' || item.status == 'under_review',
        )
        .length;
    final flagged = requests
        .where(
          (item) => item.remarks.trim().isNotEmpty && item.status != 'approved',
        )
        .length;
    final approved = requests.where((item) => item.status == 'approved').length;
    final recent = requests.isEmpty ? null : requests.first;
    final important = provider.notifications
        .where((item) => !item.read)
        .firstOrNull;
    return RefreshIndicator(
      onRefresh: provider.refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good day, ${requestor?.firstName ?? 'Applicant'}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is the latest on your LINGAP assistance.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFA6F4C5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            color: AppColors.primary,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Need assistance?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Request hospital, funeral, procedure, laboratory, dialysis, or apparatus assistance.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .84),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: onNewRequest,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('New assistance request'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'Your requests',
            subtitle: 'Current request totals',
          ),
          const SizedBox(height: 12),
          if (provider.loadingRequests && requests.isEmpty)
            const SkeletonCard(lines: 4)
          else
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Active',
                    value: '$active',
                    icon: Icons.pending_actions_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    label: 'Requirements',
                    value: '$flagged',
                    icon: Icons.rule_folder_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    label: 'Approved',
                    value: '$approved',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Recent request activity',
            action: TextButton(
              onPressed: onViewRequests,
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 10),
          if (provider.loadingRequests && requests.isEmpty)
            const SkeletonCard()
          else if (recent == null)
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.inbox_outlined, color: AppColors.textMuted),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No assistance requests have been submitted yet.',
                    ),
                  ),
                  TextButton(
                    onPressed: onNewRequest,
                    child: const Text('Start'),
                  ),
                ],
              ),
            )
          else
            _RecentRequest(request: recent, onTap: onViewRequests),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Important notifications'),
          const SizedBox(height: 10),
          AppCard(
            child: important == null
                ? const Row(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You are all caught up. There are no unread notifications.',
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.primary,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              important.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              important.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sync_rounded,
                size: 14,
                color: AppColors.textSubtle,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  provider.lastSyncedAt == null
                      ? 'Not synchronized yet'
                      : 'Last synchronized ${formatDate(provider.lastSyncedAt!, time: true)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(height: 10),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: 23),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _RecentRequest extends StatelessWidget {
  const _RecentRequest({required this.request, required this.onTap});
  final ApplicantRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                request.assistanceType,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            StatusBadge(status: request.status),
          ],
        ),
        const SizedBox(height: 10),
        MonoText(
          request.id,
          maxLines: 1,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 5),
        Text(
          'Submitted ${formatDate(request.dateSubmitted, time: true)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
