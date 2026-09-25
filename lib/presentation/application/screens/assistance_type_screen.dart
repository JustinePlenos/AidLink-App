import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/assistance_types.dart';
import '../../shared/providers/app_provider.dart';
import '../../shared/widgets/app_ui.dart';
import 'upload_requirements_screen.dart';

class AssistanceTypeScreen extends StatelessWidget {
  const AssistanceTypeScreen({super.key, required this.patient});
  final PatientDetails patient;

  static const _typeDetails = <String, (String, IconData)>{
    'Hospital Assistance': (
      'Support for hospital bills or confinement',
      Icons.local_hospital_outlined,
    ),
    'Funeral Assistance': (
      'Eligible funeral and burial expenses',
      Icons.volunteer_activism_outlined,
    ),
    'Procedure': (
      'Eligible medical procedures or treatment',
      Icons.medical_services_outlined,
    ),
    'Laboratory': (
      'Diagnostic and laboratory services',
      Icons.science_outlined,
    ),
    'Dialysis': ('Dialysis treatment assistance', Icons.water_drop_outlined),
    'Apparatus': (
      'Eligible medical equipment or apparatus',
      Icons.accessible_forward_outlined,
    ),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New request')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const PageHeading(
          title: 'Assistance type',
          description:
              'Choose the service that best matches the patient’s need.',
        ),
        const SizedBox(height: 16),
        AppCard(
          color: AppColors.primarySoft,
          child: Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PATIENT',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: .8,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      patient.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...assistanceTypes.map((type) {
          final details = _typeDetails[type]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => UploadRequirementsScreen(
                    patient: patient,
                    assistanceTitle: type,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(details.$2, color: AppColors.primary, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          details.$1,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSubtle,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}
