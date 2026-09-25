import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/aidlink_api.dart';
import '../../history/screens/application_history_screen.dart';
import '../providers/app_provider.dart';
import '../widgets/app_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;
  String? _error;

  Future<void> _refresh() async {
    try {
      await context.read<AppProvider>().refreshNotifications();
      if (mounted) setState(() => _error = null);
    } on AidLinkApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _open(ApplicantNotification item) async {
    final provider = context.read<AppProvider>();
    try {
      if (!item.read) await provider.markNotificationRead(item.id);
      if (!mounted || item.requestId == null) return;
      final request = await provider.getApplicantRequest(item.requestId!);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ApplicantRequestDetailsScreen(request: request),
          ),
        );
      }
    } on AidLinkApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final items = provider.notifications
        .where((item) => !_unreadOnly || !item.read)
        .toList();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            sliver: SliverList.list(
              children: [
                const PageHeading(
                  title: 'Notifications',
                  description:
                      'Status changes, missing requirements, and approval updates.',
                ),
                const SizedBox(height: 18),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    const ButtonSegment(value: false, label: Text('All')),
                    ButtonSegment(
                      value: true,
                      label: Text(
                        'Unread (${provider.unreadNotificationCount})',
                      ),
                    ),
                  ],
                  selected: {_unreadOnly},
                  onSelectionChanged: (value) =>
                      setState(() => _unreadOnly = value.first),
                ),
              ],
            ),
          ),
          if (provider.loadingNotifications && provider.notifications.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.list(
                children: const [
                  SkeletonCard(),
                  SizedBox(height: 10),
                  SkeletonCard(),
                  SizedBox(height: 10),
                  SkeletonCard(),
                ],
              ),
            )
          else if (_error != null && provider.notifications.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: StateView(
                icon: isOfflineMessage(_error!)
                    ? Icons.cloud_off_outlined
                    : Icons.error_outline_rounded,
                title: 'Notifications could not be loaded',
                message: isOfflineMessage(_error!)
                    ? 'Reconnect to retrieve the latest AidLink updates.'
                    : 'There was a problem retrieving notifications.',
                actionLabel: 'Try again',
                onAction: _refresh,
              ),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: StateView(
                icon: _unreadOnly
                    ? Icons.done_all_rounded
                    : Icons.notifications_none_rounded,
                title: _unreadOnly
                    ? 'You are all caught up'
                    : 'No notifications yet',
                message: _unreadOnly
                    ? 'There are no unread updates.'
                    : 'Important request updates will appear here.',
                actionLabel: _unreadOnly ? 'Show all' : 'Refresh',
                onAction: _unreadOnly
                    ? () => setState(() => _unreadOnly = false)
                    : _refresh,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return AppCard(
                    color: item.read
                        ? AppColors.surface
                        : AppColors.primarySoft,
                    onTap: () => _open(item),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: item.read
                                ? AppColors.surfaceMuted
                                : Colors.white,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            item.read
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_outlined,
                            size: 19,
                            color: item.read
                                ? AppColors.textMuted
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: item.read
                                            ? FontWeight.w600
                                            : FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (!item.read)
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.message,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 7),
                              Text(
                                formatDate(item.createdAt, time: true),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
