import 'package:aidlink_app/main.dart';
import 'package:aidlink_app/data/services/aidlink_api.dart';
import 'package:aidlink_app/presentation/auth/screens/login_screen.dart';
import 'package:aidlink_app/presentation/auth/screens/identity_verification_screen.dart';
import 'package:aidlink_app/presentation/auth/screens/register_screen.dart';
import 'package:aidlink_app/presentation/dashboard/screens/main_screen.dart';
import 'package:aidlink_app/presentation/shared/providers/app_provider.dart';
import 'package:aidlink_app/presentation/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Exercise the real dashboard refresh flow against a server requiring login.
class UnauthorizedApi extends AidLinkApi {
  int calls = 0;

  ApplicantSession _session(String email) => ApplicantSession(
    token: 'test-token',
    applicantId: 'applicant-juan',
    user: {
      'id': 'applicant-juan',
      'fullName': 'JUAN CRUZ',
      'email': email,
      'phone': '09170000000',
      'address': 'MAIN STREET, POBLACION, DISTRICT 1',
      'dateOfBirth': '1990-01-15',
      'verificationStatus': 'approved',
      'accountStatus': 'verified',
    },
  );

  ApplicantSession _unverifiedSession(String email) => ApplicantSession(
    token: 'test-token',
    applicantId: 'applicant-juan',
    user: {
      'id': 'applicant-juan',
      'fullName': 'JUAN CRUZ',
      'email': email,
      'phone': '09170000000',
      'address': 'MAIN STREET, POBLACION, DISTRICT 1',
      'dateOfBirth': '1990-01-15',
      'verificationStatus': 'unverified',
      'accountStatus': 'basic',
    },
  );

  @override
  Future<ApplicantSession> registerApplicant({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String dateOfBirth,
    required String password,
  }) async => _unverifiedSession(email);

  @override
  Future<IdentityVerification> getIdentityVerification() async =>
      const IdentityVerification(status: 'unverified', accountStatus: 'basic');

  @override
  Future<ApplicantSession> loginApplicant({
    required String email,
    required String password,
  }) async {
    if (email != 'juan@example.com' || password != 'strong-pass') {
      throw const AidLinkApiException('Invalid email or password.');
    }
    return _session(email);
  }

  @override
  Future<List<ApplicantRequest>> getApplicantRequests() async {
    calls++;
    throw const AidLinkAuthenticationException();
  }

  @override
  Future<List<ApplicantNotification>> getNotifications() async {
    calls++;
    throw const AidLinkAuthenticationException();
  }
}

class NavigationTestProvider extends AppProvider {
  NavigationTestProvider() : this._(UnauthorizedApi());
  NavigationTestProvider._(this.testApi) : super(api: testApi);
  final UnauthorizedApi testApi;
}

Future<NavigationTestProvider> openLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final provider = NavigationTestProvider();
  await provider.initialize();
  await tester.pumpWidget(
    ChangeNotifierProvider<AppProvider>(
      create: (_) => provider,
      child: const MyApp(),
    ),
  );
  await tester.tap(find.text('Continue securely'));
  await tester.pumpAndSettle();
  return provider;
}

Future<void> enterField(WidgetTester tester, String label, String value) async {
  final field = find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is LabeledField && widget.label == label,
    ),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

void expectDashboard(WidgetTester tester) {
  expect(find.byType(MainScreen), findsOneWidget);
  expect(find.byType(RegisterScreen, skipOffstage: false), findsNothing);
  expect(find.byType(LoginScreen, skipOffstage: false), findsNothing);
  expect(
    Navigator.of(tester.element(find.byType(MainScreen))).canPop(),
    isFalse,
  );
  expect(tester.takeException(), isNull);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('registration opens identity verification only after consent', (
    tester,
  ) async {
    final provider = await openLogin(tester);
    final registrationButton = find.widgetWithText(
      OutlinedButton,
      'Register a new applicant account',
    );
    await tester.ensureVisible(registrationButton);
    await tester.tap(registrationButton);
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    final createAccountButton = find.widgetWithText(
      ElevatedButton,
      'Create applicant account',
    );
    final registrationScroll = find.descendant(
      of: find.byType(RegisterScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      createAccountButton,
      500,
      scrollable: registrationScroll.first,
    );
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();
    expect(find.text('Confirm registration'), findsNothing);
    expect(provider.isSignedIn, isFalse);

    for (final entry in {
      'Last name': 'CRUZ',
      'First name': 'JUAN',
      'House no. / Street': 'MAIN STREET',
      'Barangay': 'POBLACION',
      'District': 'DISTRICT 1',
      'Mobile number': '09170000000',
      'Email address': 'juan@example.com',
      'Date of birth': '01151990',
      'Password': 'strong-pass',
      'Confirm password': 'strong-pass',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tester.ensureVisible(createAccountButton);
    await tester.drag(registrationScroll.first, const Offset(0, -120));
    await tester.pump();
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review details'));
    await tester.pumpAndSettle();
    expect(provider.isSignedIn, isFalse);
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tester.ensureVisible(createAccountButton);
    await tester.drag(registrationScroll.first, const Offset(0, -120));
    await tester.pump();
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agree and register'));
    await tester.pumpAndSettle();
    expect(provider.requestor?.email, 'juan@example.com');
    expect(find.byType(IdentityVerificationScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    expect(
      find.text(
        'Basic account created. Upload a government ID to unlock assistance requests.',
      ),
      findsOneWidget,
    );
    expect(provider.testApi.calls, 0);
    expect(provider.isSignedIn, isTrue);
    expect(provider.isIdentityVerified, isFalse);
    expect(provider.hasServerSession, isTrue);
    await tester.pump(const Duration(minutes: 3));
    provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(IdentityVerificationScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    expect(provider.isSignedIn, isTrue);
    expect(provider.testApi.calls, 0);
  });

  testWidgets('saved applicant can retry sign-in and reach dashboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'aidlink_requestor':
          '{"lastName":"CRUZ","firstName":"JUAN","middleName":"",'
          '"suffix":"","street":"MAIN STREET","subdivision":"",'
          '"barangay":"POBLACION","district":"DISTRICT 1",'
          '"contactNumber":"09170000000","email":"juan@example.com"}',
      'aidlink_signed_in': false,
    });
    final provider = await openLogin(tester);
    await enterField(tester, 'Registered email address', 'unknown@example.com');
    await enterField(tester, 'Password', 'wrong-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(provider.isSignedIn, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);

    await enterField(tester, 'Registered email address', 'juan@example.com');
    await enterField(tester, 'Password', 'strong-pass');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(provider.isSignedIn, isTrue);
    expectDashboard(tester);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign out of AidLink'));
    await tester.tap(find.text('Sign out of AidLink'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(provider.isSignedIn, isFalse);
    await tester.tap(find.text('Continue securely'));
    await tester.pumpAndSettle();
    await enterField(tester, 'Registered email address', 'juan@example.com');
    await enterField(tester, 'Password', 'strong-pass');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expectDashboard(tester);
  });
}
