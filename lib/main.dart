  import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'presentation/auth/screens/get_started_screen.dart';
import 'presentation/auth/screens/identity_verification_screen.dart';
import 'presentation/dashboard/screens/main_screen.dart';
import 'presentation/shared/providers/app_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = AppProvider();
  await provider.initialize();
  runApp(ChangeNotifierProvider.value(value: provider, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AidLink',
      debugShowCheckedModeBanner: false,
      theme: buildAidLinkTheme(),
      themeAnimationDuration: const Duration(milliseconds: 180),
      home: !context.watch<AppProvider>().isSignedIn
          ? const GetStartedScreen()
          : context.watch<AppProvider>().isIdentityVerified
          ? const MainScreen()
          : const IdentityVerificationScreen(),
    );
  }
}
