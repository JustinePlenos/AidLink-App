import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../application/screens/apply_assistance_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../history/screens/application_history_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/screens/notifications_screen.dart';
import '../../shared/widgets/app_ui.dart';
import 'dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex = widget.initialIndex.clamp(0, 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppProvider>().refreshAll(),
    );
  }

  void _select(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final screens = [
      DashboardScreen(
        onNewRequest: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const ApplyAssistanceScreen(),
          ),
        ),
        onViewRequests: () => _select(1),
      ),
      const ApplicationHistoryScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset('assets/images/logo_aidlink.png'),
            ),
            const SizedBox(width: 9),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AidLink',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'APPLICANT · LIVE',
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    letterSpacing: .7,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ConnectionBadge(
              online: provider.isOnline,
              localOnly: !provider.hasServerSession,
              compact: true,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (provider.serverSessionMessage case final message?)
            Material(
              color: AppColors.surfaceMuted,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                      ),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          if (!provider.isOnline) OfflineBanner(onRetry: provider.refreshAll),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _select,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description_rounded),
              label: 'Requests',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: provider.unreadNotificationCount > 0,
                label: Text('${provider.unreadNotificationCount}'),
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: provider.unreadNotificationCount > 0,
                label: Text('${provider.unreadNotificationCount}'),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: 'Alerts',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
