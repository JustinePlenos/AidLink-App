import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aidlink_app/core/input/app_input_formatters.dart';
import 'package:aidlink_app/data/services/aidlink_api.dart';
import 'package:aidlink_app/presentation/application/screens/apply_assistance_screen.dart';
import 'package:aidlink_app/presentation/application/screens/assistance_type_screen.dart';
import 'package:aidlink_app/presentation/application/screens/upload_requirements_screen.dart';
import 'package:aidlink_app/presentation/shared/providers/app_provider.dart';

const requestorProfile = RequestorProfile(
  lastName: 'CRUZ',
  firstName: 'JUAN',
  middleName: 'SANTOS',
  suffix: '',
  street: '123 MAIN STREET',
  subdivision: 'SAMPAGUITA VILLAGE',
  barangay: 'POBLACION',
  district: 'DISTRICT 1',
  contactNumber: '09170000000',
  email: 'juan@example.com',
  birthDate: '1990-01-15',
);

class RegistrationApi extends AidLinkApi {
  @override
  Future<ApplicantSession> registerApplicant({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String dateOfBirth,
    required String password,
  }) async => ApplicantSession(
    token: 'test-token',
    applicantId: 'applicant-juan',
    user: {'id': 'applicant-juan', 'email': email},
  );
}

class RequirementsApi extends AidLinkApi {
  @override
  Future<ApplicantSession> loginApplicant({
    required String email,
    required String password,
  }) async => ApplicantSession(
    token: 'applicant-token',
    applicantId: 'applicant-juan',
    user: {
      'id': 'applicant-juan',
      'fullName': 'JUAN CRUZ',
      'email': email,
      'phone': '09170000000',
      'address': 'DAVAO CITY',
      'dateOfBirth': '1990-01-01',
      'verificationStatus': 'unverified',
      'accountStatus': 'basic',
    },
  );

  @override
  Future<ApplicationRequirements> getApplicationRequirements(
    String assistanceType,
  ) async => const ApplicationRequirements(
    documents: ['Recent facility receipt or billing document'],
    receiptValidityDays: 90,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new patient form does not display PhilHealth controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ApplyAssistanceScreen()));

    expect(find.textContaining('PhilHealth'), findsNothing);
  });

  testWidgets('receipt field omits internal validation implementation text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final provider = AppProvider(api: RequirementsApi());
    await provider.login('juan@example.com', 'strong-pass');
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: UploadRequirementsScreen(
            patient: PatientDetails(
              lastName: 'CRUZ',
              firstName: 'JUAN',
              middleName: '',
              suffix: '',
              street: 'MAIN STREET',
              subdivision: '',
              barangay: 'POBLACION',
              district: 'DISTRICT 1',
              relationshipToPatient: 'Self',
              sex: 'Male',
              birthDate: '1990-01-01',
            ),
            assistanceTitle: 'Hospital Assistance',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Upload a clear, complete copy of each required document.'),
      findsOneWidget,
    );
    expect(find.textContaining('Include every corner'), findsOneWidget);
    expect(find.textContaining('automated quality'), findsNothing);
    expect(find.textContaining('LINGAP personnel will verify'), findsNothing);
    final receiptLabel = find.textContaining(
      'Receipt or transaction reference',
      findRichText: true,
    );
    for (
      var attempt = 0;
      attempt < 6 && receiptLabel.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
    }

    expect(receiptLabel, findsOneWidget);
    expect(find.textContaining('AidLink checks receipt recency'), findsNothing);
    expect(find.textContaining('request context'), findsNothing);
    expect(find.textContaining('technical quality'), findsNothing);
    expect(
      find.textContaining('Receipts older than 90 days are rejected'),
      findsOneWidget,
    );
  });

  testWidgets('requires a beneficiary choice before showing personal fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ApplyAssistanceScreen(requestorProfile: requestorProfile),
      ),
    );
    expect(find.text('For myself'), findsOneWidget);
    expect(find.text('For someone else'), findsOneWidget);
    expect(find.byKey(const ValueKey('Beneficiary first name')), findsNothing);
  });

  testWidgets('For myself autofills the authenticated applicant profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: ApplyAssistanceScreen(requestorProfile: requestorProfile),
      ),
    );
    await tester.tap(find.text('For myself'));
    await tester.pumpAndSettle();
    TextFormField field(String key) => tester.widget(find.byKey(ValueKey(key)));
    expect(field('Beneficiary first name').controller!.text, 'JUAN');
    expect(field('Beneficiary last name').controller!.text, 'CRUZ');
    expect(field('House no. / Street').controller!.text, '123 MAIN STREET');
    expect(field('Beneficiary date of birth').controller!.text, '01/15/1990');
  });

  testWidgets(
    'For someone else starts blank and preserves its draft on switch',
    (tester) async {
      tester.view.physicalSize = const Size(430, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: ApplyAssistanceScreen(requestorProfile: requestorProfile),
        ),
      );
      await tester.tap(find.text('For someone else'));
      await tester.pumpAndSettle();
      final firstName = find.byKey(const ValueKey('Beneficiary first name'));
      expect(tester.widget<TextFormField>(firstName).controller!.text, isEmpty);
      await tester.enterText(firstName, 'MARIA');
      await tester.tap(find.text('For myself'));
      await tester.pumpAndSettle();
      expect(find.text('Switch who needs assistance?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(firstName).controller!.text, 'MARIA');
      await tester.tap(find.text('For myself'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(firstName).controller!.text, 'JUAN');
      await tester.tap(find.text('For someone else'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(firstName).controller!.text, 'MARIA');
    },
  );

  testWidgets('validates and submits someone-else beneficiary separately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: ApplyAssistanceScreen(requestorProfile: requestorProfile),
      ),
    );
    await tester.tap(find.text('For someone else'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to assistance type'));
    await tester.pump();
    expect(find.text('Beneficiary last name is required.'), findsOneWidget);
    Future<void> enter(String key, String value) =>
        tester.enterText(find.byKey(ValueKey(key)), value);
    await enter('Beneficiary last name', 'DELA CRUZ');
    await enter('Beneficiary first name', 'MARIA');
    await enter('House no. / Street', '456 OTHER STREET');
    await enter('Barangay', 'MATINA');
    await enter('District', 'DISTRICT 2');
    await enter('Requester’s relationship to beneficiary', 'PARENT');
    await enter('Beneficiary date of birth', '02/03/2010');
    await tester.tap(find.text('Continue to assistance type'));
    await tester.pumpAndSettle();
    final next = tester.widget<AssistanceTypeScreen>(
      find.byType(AssistanceTypeScreen),
    );
    expect(next.patient.beneficiaryType, PatientDetails.beneficiaryTypeOther);
    expect(next.patient.fullName, 'MARIA DELA CRUZ');
    expect(next.patient.relationshipToPatient, 'PARENT');
    expect(requestorProfile.fullName, 'JUAN SANTOS CRUZ');
  });

  test('reads legacy patient JSON but drops PhilHealth when re-encoding', () {
    final patient = PatientDetails.fromJson({
      'lastName': 'PATIENT',
      'firstName': 'LEGACY',
      'middleName': '',
      'suffix': '',
      'street': 'STREET',
      'subdivision': '',
      'barangay': 'BARANGAY',
      'district': 'DISTRICT',
      'relationshipToPatient': 'Self',
      'sex': 'Female',
      'birthDate': '1990-01-01',
      'hasPhilHealth': true,
      'philHealthNumber': '12-345678901-2',
    });

    expect(patient.fullName, 'LEGACY PATIENT');
    expect(patient.toJson(), isNot(contains('hasPhilHealth')));
    expect(patient.toJson(), isNot(contains('philHealthNumber')));
  });

  test('persists requestor registration', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final provider = AppProvider(api: RegistrationApi());
    await provider.initialize();
    await provider.register(
      const RequestorProfile(
        lastName: 'CRUZ',
        firstName: 'JUAN',
        middleName: '',
        suffix: '',
        street: 'STREET',
        subdivision: '',
        barangay: 'BARANGAY',
        district: 'DISTRICT',
        contactNumber: '09170000000',
        email: 'juan@example.com',
        birthDate: '1990-01-15',
      ),
      password: 'strong-pass',
    );
    await Future<void>.delayed(Duration.zero);
    final restored = AppProvider();
    await restored.initialize();
    expect(restored.requestor?.email, 'juan@example.com');
  });

  test('uppercases request form input', () {
    const formatter = UpperCaseTextFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'Juan dela Cruz'),
    );
    expect(result.text, 'JUAN DELA CRUZ');
  });

  test('persists a runtime API server address', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AppProvider();
    await provider.initialize();
    await provider.saveApiUrl('192.168.1.25:5000/');

    final restored = AppProvider();
    await restored.initialize();
    expect(restored.apiUrl, 'http://192.168.1.25:5000');
  });

  test('inserts birthdate separators', () {
    const formatter = BirthDateTextFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '01151990'),
    );
    expect(result.text, '01/15/1990');
  });
}
