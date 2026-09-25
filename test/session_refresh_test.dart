import 'dart:async';
import 'dart:convert';

import 'package:aidlink_app/data/services/aidlink_api.dart';
import 'package:aidlink_app/presentation/shared/providers/app_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const profile = RequestorProfile(
  lastName: 'CRUZ',
  firstName: 'JUAN',
  middleName: '',
  suffix: '',
  street: 'MAIN STREET',
  subdivision: '',
  barangay: 'POBLACION',
  district: 'DISTRICT 1',
  contactNumber: '09170000000',
  email: 'juan@example.com',
  birthDate: '1990-01-15',
);

class SessionApi extends AidLinkApi {
  AidLinkApiException? error;
  int calls = 0;
  int submissionCalls = 0;
  List<ApplicantRequest> requests = const [];
  Completer<List<ApplicantRequest>>? pendingRequests;
  Completer<SubmittedApplication>? pendingSubmission;

  @override
  Future<ApplicantSession> registerApplicant({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String dateOfBirth,
    required String password,
  }) async => ApplicantSession(
    token: 'fresh-token',
    applicantId: 'applicant-juan',
    user: {
      'id': 'applicant-juan',
      'email': email,
      'verificationStatus': 'approved',
      'accountStatus': 'verified',
    },
  );

  @override
  Future<List<ApplicantRequest>> getApplicantRequests() async {
    calls++;
    if (pendingRequests != null) return pendingRequests!.future;
    if (error != null) throw error!;
    return requests;
  }

  @override
  Future<List<ApplicantNotification>> getNotifications() async {
    calls++;
    if (error != null) throw error!;
    return [];
  }

  @override
  Future<SubmittedApplication> submitApplication({
    required String clientSubmissionId,
    required String beneficiaryType,
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String dateOfBirth,
    required String relationshipToPatient,
    required String sex,
    required String assistanceType,
    required String incomeSource,
    required String patientCircumstance,
    String additionalDetails = '',
    required List<Map<String, dynamic>> documents,
    required Map<String, dynamic> facilityEvidence,
  }) {
    submissionCalls++;
    return pendingSubmission?.future ??
        Future.value(
          SubmittedApplication(
            referenceNumber: 'request-$clientSubmissionId',
            status: 'pending',
            submittedAt: DateTime.utc(2026, 9, 20),
          ),
        );
  }
}

class MultiAccountApi extends AidLinkApi {
  @override
  Future<ApplicantSession> loginApplicant({
    required String email,
    required String password,
  }) async {
    final isAlice = password == 'alice-pass';
    final id = isAlice ? 'applicant-alice' : 'applicant-bob';
    return ApplicantSession(
      token: isAlice ? 'token-alice' : 'token-bob',
      applicantId: id,
      // Deliberately return Alice's editable fields for Bob. Cache isolation
      // must use the authenticated stable ID, not either of these values.
      user: {
        'id': isAlice ? id : 'applicant-alice',
        'fullName': isAlice ? 'ALICE APPLICANT' : 'BOB APPLICANT',
        'email': 'alice@example.com',
        'verificationStatus': 'approved',
        'accountStatus': 'verified',
      },
    );
  }

  @override
  Future<SubmittedApplication> submitApplication({
    required String clientSubmissionId,
    required String beneficiaryType,
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String dateOfBirth,
    required String relationshipToPatient,
    required String sex,
    required String assistanceType,
    required String incomeSource,
    required String patientCircumstance,
    String additionalDetails = '',
    required List<Map<String, dynamic>> documents,
    required Map<String, dynamic> facilityEvidence,
  }) async => SubmittedApplication(
    referenceNumber: 'alice-local-request',
    status: 'pending',
    submittedAt: DateTime.utc(2026, 9, 12),
  );

  @override
  Future<List<ApplicantRequest>> getApplicantRequests() async => [
    ApplicantRequest(
      id: applicantToken == 'token-alice'
          ? 'alice-server-request'
          : 'bob-server-request',
      assistanceType: 'Medical',
      dateSubmitted: DateTime.utc(2026, 9, 12),
      status: 'pending',
      remarks: '',
    ),
  ];
}

const patient = PatientDetails(
  lastName: 'PATIENT',
  firstName: 'TEST',
  middleName: '',
  suffix: '',
  street: 'MAIN STREET',
  subdivision: '',
  barangay: 'POBLACION',
  district: 'DISTRICT 1',
  relationshipToPatient: 'Self',
  sex: 'Female',
  birthDate: '1990-01-15',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SessionApi api;
  late AppProvider provider;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    api = SessionApi();
    provider = AppProvider(api: api);
    await provider.initialize();
    await provider.register(profile, password: 'strong-pass');
  });
  tearDown(() => provider.dispose());

  test(
    'registration persists the profile and server session when reopening',
    () async {
      expect(provider.isSignedIn, isTrue);
      expect(provider.hasServerSession, isTrue);
      final restored = AppProvider(api: SessionApi());
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.requestor?.email, profile.email);
      expect(restored.isSignedIn, isTrue);
      expect(restored.hasServerSession, isTrue);
    },
  );

  test(
    '401 clears server credentials but preserves the saved profile',
    () async {
      await provider.setApplicantToken('expired-token');
      api.error = const AidLinkAuthenticationException();
      await provider.refreshAll();
      expect(provider.isSignedIn, isTrue);
      expect(provider.hasServerSession, isFalse);
      expect(provider.serverSessionMessage, contains('expired'));
      expect(
        await const FlutterSecureStorage().read(key: 'aidlink_applicant_token'),
        isNull,
      );
      final calls = api.calls;
      await provider.refreshAll();
      expect(api.calls, calls);
    },
  );

  test(
    'offline resume refresh is handled without signing the applicant out',
    () async {
      await provider.setApplicantToken('valid-token');
      api.error = const AidLinkApiException('Cannot reach the AidLink server.');
      provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(provider.isSignedIn, isTrue);
      expect(provider.hasServerSession, isTrue);
      expect(provider.isOnline, isFalse);
    },
  );

  test('a delayed response cannot restore requests after sign-out', () async {
    await provider.setApplicantToken('old-token');
    api.pendingRequests = Completer<List<ApplicantRequest>>();
    final refresh = provider.refreshApplicantRequests();
    await provider.logout();
    api.pendingRequests!.complete([
      ApplicantRequest(
        id: 'old-request',
        assistanceType: 'Medical',
        dateSubmitted: DateTime(2026),
        status: 'pending',
        remarks: '',
      ),
    ]);
    await refresh;
    expect(provider.isSignedIn, isFalse);
    expect(provider.applicantRequests, isEmpty);
  });

  test('a delayed 401 does not clear a newer server token', () async {
    await provider.setApplicantToken('old-token');
    api.pendingRequests = Completer<List<ApplicantRequest>>();
    final refresh = provider.refreshApplicantRequests();
    final result = expectLater(
      refresh,
      throwsA(isA<AidLinkAuthenticationException>()),
    );
    await provider.setApplicantToken('new-token');
    api.pendingRequests!.completeError(const AidLinkAuthenticationException());
    await result;
    expect(provider.isSignedIn, isTrue);
    expect(provider.hasServerSession, isTrue);
    expect(api.applicantToken, 'new-token');
  });

  test(
    'two accounts on one device cannot share cached or server requests',
    () async {
      provider.dispose();
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final multiAccountApi = MultiAccountApi();
      provider = AppProvider(api: multiAccountApi);
      await provider.initialize();

      await provider.login('alice@example.com', 'alice-pass');
      await provider.submitApplication(
        clientSubmissionId: 'alice-submission-0001',
        patient: patient,
        assistanceType: 'Medical',
        incomeSource: 'Salary or wages',
        patientCircumstance: 'Disease',
        additionalDetails: 'Alice request',
        documents: const [],
        facilityEvidence: const {
          'facilityName': 'Test Hospital',
          'facilityType': 'hospital',
          'receiptDate': '2026-09-12',
          'referenceNumber': 'TEST-1',
          'receiptDocumentId': 'receipt-1',
        },
      );
      expect(provider.applicantId, 'applicant-alice');
      expect(
        provider.applications.single.referenceNumber,
        'alice-local-request',
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey('aidlink_applications'), isFalse);
      final aliceCacheKey =
          'aidlink_applications.${base64Url.encode(utf8.encode('applicant-alice'))}';
      expect(preferences.containsKey(aliceCacheKey), isTrue);
      expect(
        preferences.containsKey('aidlink_applications.alice@example.com'),
        isFalse,
      );
      expect(
        preferences.getKeys().where(
          (key) => key.startsWith('aidlink_applications.'),
        ),
        hasLength(1),
      );

      // Even with Alice's email and a forged user-map ID, Bob's authenticated
      // session ID replaces Alice's device state.
      await provider.login('alice@example.com', 'bob-pass');
      expect(provider.applicantId, 'applicant-bob');
      expect(provider.requestor?.email, 'alice@example.com');
      expect(provider.applications, isEmpty);
      await provider.refreshApplicantRequests();
      expect(provider.applicantRequests.map((request) => request.id), [
        'bob-server-request',
      ]);
      expect(
        provider.applicantRequests.map((request) => request.id),
        isNot(contains('alice-server-request')),
      );

      await provider.logout();
      expect(provider.requestor, isNull);
      expect(provider.applicantId, isNull);
      expect(provider.applications, isEmpty);
      expect(provider.applicantRequests, isEmpty);
      expect(
        preferences.getKeys().where(
          (key) =>
              key == 'aidlink_requestor' ||
              key == 'aidlink_applicant_id' ||
              key.startsWith('aidlink_applications'),
        ),
        isEmpty,
      );
      expect(
        await const FlutterSecureStorage().read(key: 'aidlink_applicant_token'),
        isNull,
      );
    },
  );

  test(
    'refresh deduplicates records and keeps the newest valid data',
    () async {
      api.requests = [
        ApplicantRequest(
          id: 'internal-1',
          requestId: 'LINGAP-2026-00001',
          assistanceType: 'Hospital Assistance',
          dateSubmitted: DateTime.utc(2026, 9, 20),
          lastUpdatedAt: DateTime.utc(2026, 9, 20, 8),
          status: 'pending',
          remarks: '',
        ),
        ApplicantRequest(
          id: 'internal-1',
          requestId: 'LINGAP-2026-00001',
          assistanceType: 'Hospital Assistance',
          dateSubmitted: DateTime.utc(2026, 9, 20),
          lastUpdatedAt: DateTime.utc(2026, 9, 20, 9),
          status: 'under_review',
          remarks: '',
        ),
        ApplicantRequest(
          id: 'internal-2',
          requestId: 'LINGAP-2026-00002',
          assistanceType: 'Hospital Assistance',
          dateSubmitted: DateTime.utc(2026, 9, 20),
          status: 'pending',
          remarks: '',
        ),
      ];

      await provider.refreshApplicantRequests();

      expect(provider.loadingRequests, isFalse);
      expect(provider.applicantRequests, hasLength(2));
      expect(
        provider.applicantRequests
            .singleWhere((item) => item.stableId == 'LINGAP-2026-00001')
            .status,
        'under_review',
      );

      api.requests = const [];
      await provider.refreshApplicantRequests();
      expect(provider.loadingRequests, isFalse);
      expect(provider.applicantRequests, isEmpty);
    },
  );

  test('offline cache restoration deduplicates by request reference', () async {
    provider.dispose();
    final older = AssistanceApplication(
      referenceNumber: 'LINGAP-2026-00001',
      patient: patient,
      assistanceType: 'Hospital Assistance',
      submittedAt: DateTime.utc(2026, 9, 20, 8),
      documentNames: const [],
      status: 'pending',
    );
    final newer = AssistanceApplication(
      referenceNumber: 'LINGAP-2026-00001',
      patient: patient,
      assistanceType: 'Hospital Assistance',
      submittedAt: DateTime.utc(2026, 9, 20, 9),
      documentNames: const [],
      status: 'under_review',
    );
    final separate = AssistanceApplication(
      referenceNumber: 'LINGAP-2026-00002',
      patient: patient,
      assistanceType: 'Hospital Assistance',
      submittedAt: DateTime.utc(2026, 9, 20, 8),
      documentNames: const [],
      status: 'pending',
    );
    final cacheKey =
        'aidlink_applications.${base64Url.encode(utf8.encode('applicant-cache'))}';
    SharedPreferences.setMockInitialValues({
      'aidlink_requestor': jsonEncode(profile.toJson()),
      'aidlink_applicant_id': 'applicant-cache',
      'aidlink_signed_in': true,
      cacheKey: jsonEncode([older.toJson(), newer.toJson(), separate.toJson()]),
    });
    FlutterSecureStorage.setMockInitialValues({
      'aidlink_applicant_token': 'cache-token',
    });
    provider = AppProvider(api: SessionApi());

    await provider.initialize();

    expect(provider.applications, hasLength(2));
    expect(
      provider.applications
          .singleWhere((item) => item.referenceNumber == 'LINGAP-2026-00001')
          .status,
      'under_review',
    );
  });

  test('repeated submission taps share one in-flight request', () async {
    api.pendingSubmission = Completer<SubmittedApplication>();
    const submissionId = 'mobile-repeated-tap-0001';
    final first = provider.submitApplication(
      clientSubmissionId: submissionId,
      patient: patient,
      assistanceType: 'Hospital Assistance',
      incomeSource: 'Salary or wages',
      patientCircumstance: 'Disease',
      documents: const [],
      facilityEvidence: const {},
    );
    final second = provider.submitApplication(
      clientSubmissionId: submissionId,
      patient: patient,
      assistanceType: 'Hospital Assistance',
      incomeSource: 'Salary or wages',
      patientCircumstance: 'Disease',
      documents: const [],
      facilityEvidence: const {},
    );

    expect(api.submissionCalls, 1);
    api.pendingSubmission!.complete(
      SubmittedApplication(
        referenceNumber: 'LINGAP-2026-00003',
        status: 'pending',
        submittedAt: DateTime.utc(2026, 9, 20),
      ),
    );
    expect((await first).referenceNumber, 'LINGAP-2026-00003');
    expect((await second).referenceNumber, 'LINGAP-2026-00003');
    expect(provider.applications, hasLength(1));
  });
}
