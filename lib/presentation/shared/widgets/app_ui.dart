import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

enum AidLinkStatus {
  pending,
  underReview,
  correctionRequested,
  approved,
  readyForClaiming,
  denied,
}

AidLinkStatus aidLinkStatus(String value) => switch (value) {
  'under_review' => AidLinkStatus.underReview,
  'correction_requested' => AidLinkStatus.correctionRequested,
  'approved' => AidLinkStatus.approved,
  'ready_for_claiming' => AidLinkStatus.readyForClaiming,
  'denied' => AidLinkStatus.denied,
  _ => AidLinkStatus.pending,
};

String statusLabel(String value) => switch (value) {
  'under_review' => 'Under review',
  'correction_requested' => 'Correction requested',
  'approved' => 'Approved',
  'ready_for_claiming' => 'Ready for claiming',
  'denied' => 'Denied',
  _ => 'Pending',
};

String formatDate(DateTime value, {bool time = false}) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final date = '${months[value.month - 1]} ${value.day}, ${value.year}';
  if (!time) return date;
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  return '$date, $hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (aidLinkStatus(status)) {
      AidLinkStatus.underReview => (
        AppColors.primarySoft,
        AppColors.primaryDark,
        Icons.manage_search_rounded,
      ),
      AidLinkStatus.correctionRequested => (
        AppColors.warningSoft,
        AppColors.warning,
        Icons.edit_document,
      ),
      AidLinkStatus.approved => (
        AppColors.primarySoft,
        AppColors.primaryDark,
        Icons.task_alt_rounded,
      ),
      AidLinkStatus.readyForClaiming => (
        AppColors.successSoft,
        AppColors.success,
        Icons.check_circle_outline_rounded,
      ),
      AidLinkStatus.denied => (
        AppColors.errorSoft,
        AppColors.error,
        Icons.cancel_outlined,
      ),
      AidLinkStatus.pending => (
        AppColors.surfaceMuted,
        AppColors.textMuted,
        Icons.schedule_rounded,
      ),
    };
    return Semantics(
      label: 'Status: ${statusLabel(status)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: foreground.withValues(alpha: .18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: 14),
            const SizedBox(width: 5),
            Text(
              statusLabel(status),
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({
    super.key,
    required this.online,
    this.localOnly = false,
    this.compact = false,
  });
  final bool online;
  final bool localOnly;
  final bool compact;
  bool get connected => online && !localOnly;

  @override
  Widget build(BuildContext context) => Semantics(
    label: localOnly
        ? 'Profile saved on this device'
        : online
        ? 'Connected to AidLink'
        : 'AidLink is offline',
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 6),
      decoration: BoxDecoration(
        color: connected ? AppColors.successSoft : AppColors.surfaceMuted,
        border: Border.all(
          color: connected ? const Color(0xFFA6F4C5) : AppColors.borderStrong,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: connected ? AppColors.success : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            localOnly
                ? 'On device'
                : online
                ? 'Connected'
                : 'Offline',
            style: TextStyle(
              color: connected ? AppColors.success : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceMuted,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Offline. Showing the last available information.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    required this.description,
    this.action,
  });
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
      if (action != null) ...[const SizedBox(width: 12), action!],
    ],
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
      ?action,
    ],
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
          if (onSecondary != null && secondaryLabel != null)
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
        ],
      ),
    ),
  );
}

class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key, this.lines = 3});
  final int lines;

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final shade = Color.lerp(
          AppColors.surfaceMuted,
          AppColors.border,
          reduceMotion ? .4 : _controller.value,
        )!;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              widget.lines,
              (index) => Container(
                height: index == 0 ? 14 : 10,
                width: index == widget.lines - 1 ? 150 : double.infinity,
                margin: EdgeInsets.only(
                  bottom: index == widget.lines - 1 ? 0 : 12,
                ),
                decoration: BoxDecoration(
                  color: shade,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MonoText extends StatelessWidget {
  const MonoText(this.data, {super.key, this.style, this.maxLines});
  final String data;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Text(
    data,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
    style: const TextStyle(
      fontFamily: 'monospace',
      letterSpacing: .2,
    ).merge(style),
  );
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.description,
    this.required = false,
  });
  final String label;
  final String? description;
  final bool required;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ]
                : null,
          ),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        if (description != null) ...[
          const SizedBox(height: 3),
          Text(description!, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 7),
        child,
      ],
    ),
  );
}
