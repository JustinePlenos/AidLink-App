import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset('assets/images/logo_aidlink.png'),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AidLink',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'LINGAP APPLICANT PORTAL',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: .8,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    border: Border.all(color: const Color(0xFFD1E0FF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Assistance, from request to resolution.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Submit LINGAP requirements, follow each review stage, and securely access your approval documents in one place.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _Feature(
                  icon: Icons.fact_check_outlined,
                  text: 'Track every request with a clear status timeline',
                ),
                const _Feature(
                  icon: Icons.verified_user_outlined,
                  text: 'Keep documents and verification details protected',
                ),
                const _Feature(
                  icon: Icons.apartment_outlined,
                  text: 'Submit recent facility receipts with each request',
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue securely'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Official applicant access · City Government of Davao',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
