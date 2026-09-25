import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/aidlink_api.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/widgets/app_ui.dart';

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({super.key});

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final query = _search.text.trim().toLowerCase();
    final facilities = provider.assignedFacilities.where((item) {
      if (query.isEmpty) return true;
      return '${item.name} ${item.type} ${item.address}'.toLowerCase().contains(
        query,
      );
    }).toList();
    return RefreshIndicator(
      onRefresh: provider.refreshApplicantRequests,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            sliver: SliverList.list(
              children: [
                const PageHeading(
                  title: 'Facilities',
                  description:
                      'Accredited providers assigned to your approved or active requests.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search assigned facilities',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  color: AppColors.primarySoft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Facilities appear here only when assigned by LINGAP personnel. AidLink never selects a provider on your behalf.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (provider.loadingRequests && provider.assignedFacilities.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.list(
                children: const [
                  SkeletonCard(lines: 4),
                  SizedBox(height: 12),
                  SkeletonCard(lines: 4),
                ],
              ),
            )
          else if (facilities.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: StateView(
                icon: query.isEmpty
                    ? Icons.apartment_outlined
                    : Icons.search_off_rounded,
                title: query.isEmpty
                    ? 'No facility assigned yet'
                    : 'No facilities found',
                message: query.isEmpty
                    ? 'An accredited facility will appear after LINGAP assigns one to your request.'
                    : 'Try a different facility name, type, or location.',
                actionLabel: query.isEmpty ? 'Refresh' : 'Clear search',
                onAction: query.isEmpty
                    ? provider.refreshApplicantRequests
                    : () {
                        _search.clear();
                        setState(() {});
                      },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList.separated(
                itemCount: facilities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) =>
                    FacilityDirectoryCard(facility: facilities[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class FacilityDirectoryCard extends StatelessWidget {
  const FacilityDirectoryCard({super.key, required this.facility});
  final AssignedFacility facility;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FacilityDetailsScreen(facility: facility),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.local_hospital_outlined,
            color: AppColors.primary,
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
                      facility.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSubtle,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                facility.type.isEmpty ? 'Accredited facility' : facility.type,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                facility.address.isEmpty
                    ? 'Address unavailable'
                    : facility.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class FacilityDetailsScreen extends StatelessWidget {
  const FacilityDetailsScreen({super.key, required this.facility});
  final AssignedFacility facility;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Facility details')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          facility.type.isEmpty
                              ? 'Accredited provider'
                              : facility.type,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              _detail(
                context,
                Icons.location_on_outlined,
                'Address',
                facility.address,
              ),
              if (facility.operatingHours.isNotEmpty)
                _detail(
                  context,
                  Icons.schedule_outlined,
                  'Operating hours',
                  facility.operatingHours,
                ),
              if (facility.phone.isNotEmpty)
                _detail(
                  context,
                  Icons.phone_outlined,
                  'Contact number',
                  facility.phone,
                ),
              if (facility.email.isNotEmpty)
                _detail(
                  context,
                  Icons.mail_outline_rounded,
                  'Email',
                  facility.email,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: facility.address.isEmpty
              ? null
              : () => launchUrl(facilityMapsUri(facility)),
          icon: const Icon(Icons.directions_outlined),
          label: const Text('Get directions'),
        ),
        if (facility.phone.isNotEmpty) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => launchUrl(facilityCallUri(facility.phone)),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call facility'),
          ),
        ],
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: facility.address.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(
                    ClipboardData(text: facility.address),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Facility address copied.')),
                    );
                  }
                },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copy address'),
        ),
      ],
    ),
  );

  Widget _detail(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(value.isEmpty ? 'Not provided' : value),
            ],
          ),
        ),
      ],
    ),
  );
}
