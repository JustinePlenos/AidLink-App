import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aidlink_app/core/constants/application_intake_options.dart';
import 'package:aidlink_app/core/constants/assistance_types.dart';
import 'package:aidlink_app/data/services/aidlink_api.dart';
import 'package:aidlink_app/presentation/shared/providers/app_provider.dart';

ApplicantRequest request(String id, String date, String status) =>
    ApplicantRequest(
      id: id,
      assistanceType: 'Hospital Assistance',
      dateSubmitted: DateTime.parse(date),
      status: normalizeStatus(status),
      remarks: '',
    );

void main() {
  test('uses the confirmed canonical assistance types', () {
    expect(assistanceTypes, [
      'Hospital Assistance',
      'Funeral Assistance',
      'Procedure',
      'Laboratory',
      'Dialysis',
      'Apparatus',
    ]);
    expect(isSupportedAssistanceType('Medicine Assistance'), isFalse);
    expect(isSupportedAssistanceType('Other Assistance'), isFalse);
  });

  test('uses the confirmed structured intake choices', () {
    expect(incomeSourceOptions, [
      'Salary or wages',
      'Self-employment or business',
      'Informal or daily-wage work',
      'Pension',
      'Government assistance',
      'Family or remittance support',
      'No income',
      'Other',
    ]);
    expect(patientCircumstanceOptions, [
      'Accident',
      'Disease',
      'Existing health issue',
      'Injury',
      'Other',
    ]);
  });

  test('keeps a legacy cached reason readable', () {
    final application = AssistanceApplication.fromJson({
      'referenceNumber': 'LINGAP-2025-00001',
      'patient': {
        'lastName': 'Applicant',
        'firstName': 'Legacy',
        'middleName': '',
        'suffix': '',
        'street': 'Test Street',
        'subdivision': '',
        'barangay': 'Test Barangay',
        'district': 'Test District',
        'relationshipToPatient': 'Self',
        'sex': 'Female',
        'birthDate': '1980-01-01',
      },
      'assistanceType': 'Hospital Assistance',
      'submittedAt': '2025-01-01T00:00:00.000Z',
      'documentNames': <String>[],
      'reason': 'Legacy free-text reason',
    });

    expect(application.reason, 'Legacy free-text reason');
    expect(application.incomeSource, isEmpty);
    expect(application.patientCircumstance, isEmpty);
  });

  test('requires one stable applicant ID in an authenticated session', () {
    final session = ApplicantSession.fromJson({
      'token': 'token-alice',
      'user': {'id': 'applicant-alice', 'email': 'alice@example.com'},
    });
    expect(session.applicantId, 'applicant-alice');
    expect(
      () => ApplicantSession.fromJson({
        'token': 'token-bob',
        'applicantId': 'applicant-bob',
        'user': {'id': 'applicant-alice', 'email': 'alice@example.com'},
      }),
      throwsA(isA<AidLinkApiException>()),
    );
    expect(
      () => ApplicantSession.fromJson({
        'token': 'token-without-id',
        'user': {'email': 'alice@example.com'},
      }),
      throwsA(isA<AidLinkApiException>()),
    );
  });

  test(
    'request history sends only the authenticated bearer identity',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      try {
        final receivedRequest = server.first;
        final api = AidLinkApi(
          baseUrl: 'http://${server.address.address}:${server.port}',
        )..applicantToken = 'token-bob';
        final history = api.getApplicantRequests();
        final request = await receivedRequest;

        expect(request.method, 'GET');
        expect(request.uri.path, '/api/applicant/requests');
        expect(request.uri.query, isEmpty);
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer token-bob',
        );
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'requests': <Object>[]}));
        await request.response.close();

        expect(await history, isEmpty);
      } finally {
        await server.close(force: true);
      }
    },
  );

  test('new application payload omits legacy PhilHealth data', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    try {
      final receivedRequest = server.first;
      final api = AidLinkApi(
        baseUrl: 'http://${server.address.address}:${server.port}',
      )..applicantToken = 'applicant-token';
      final submitted = api.submitApplication(
        clientSubmissionId: 'mobile-submission-test-0001',
        beneficiaryType: PatientDetails.beneficiaryTypeSelf,
        fullName: 'TEST PATIENT',
        email: 'applicant@example.com',
        phone: '09170000000',
        address: 'DAVAO CITY',
        dateOfBirth: '1990-01-01',
        relationshipToPatient: 'Self',
        sex: 'Female',
        assistanceType: 'Hospital Assistance',
        incomeSource: 'Salary or wages',
        patientCircumstance: 'Disease',
        additionalDetails: 'Needs hospital support',
        documents: const [],
        facilityEvidence: const {
          'facilityName': 'Test Hospital',
          'facilityType': 'hospital',
          'receiptDate': '2026-09-12',
          'referenceNumber': 'TEST-1',
          'receiptDocumentId': 'receipt-1',
        },
      );
      final request = await receivedRequest;
      final payload =
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>;

      expect(payload, isNot(contains('hasPhilHealth')));
      expect(payload, isNot(contains('philHealthNumber')));
      expect(payload, isNot(contains('reason')));
      expect(payload['clientSubmissionId'], 'mobile-submission-test-0001');
      expect(payload['incomeSource'], 'Salary or wages');
      expect(payload['patientCircumstance'], 'Disease');
      expect(payload['additionalDetails'], 'Needs hospital support');
      expect(payload['beneficiaryType'], 'self');
      expect(payload['beneficiary'], {
        'fullName': 'TEST PATIENT',
        'address': 'DAVAO CITY',
        'dateOfBirth': '1990-01-01',
        'relationshipToApplicant': 'Self',
        'sex': 'Female',
      });
      expect(payload['facilityEvidence'], {
        'facilityName': 'Test Hospital',
        'facilityType': 'hospital',
        'receiptDate': '2026-09-12',
        'referenceNumber': 'TEST-1',
        'receiptDocumentId': 'receipt-1',
      });
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'requestId': 'request-1',
          'status': 'pending',
          'dateSubmitted': '2026-09-12T00:00:00Z',
        }),
      );
      await request.response.close();

      expect((await submitted).referenceNumber, 'request-1');
    } finally {
      await server.close(force: true);
    }
  });

  test('normalizes status to the six backend statuses', () {
    expect(normalizeStatus('UNDER_REVIEW'), 'under_review');
    expect(normalizeStatus('Correction Requested'), 'correction_requested');
    expect(normalizeStatus('Ready for Claiming'), 'ready_for_claiming');
    expect(normalizeStatus('unknown'), 'pending');
  });

  test('parses requested replacements and tracks correction completeness', () {
    final awaiting = ApplicantRequest.fromJson({
      'id': 'request-1',
      'assistanceType': 'Hospital Assistance',
      'status': 'correction_requested',
      'dateSubmitted': '2026-09-13T00:00:00Z',
      'documents': [
        {
          'id': 'document-1',
          'name': 'valid-id.jpg',
          'documentType': 'valid_id',
          'url': '/uploads/valid-id.jpg',
        },
      ],
      'correctionRequest': {
        'id': 'correction-1',
        'remark': 'Retake the ID with all four edges visible.',
        'requestedAt': '2026-09-13T01:00:00Z',
        'requestedBy': 'Case Worker One',
        'documents': [
          {
            'documentId': 'document-1',
            'name': 'valid-id.jpg',
            'documentType': 'valid_id',
            'label': 'Valid ID',
          },
        ],
        'replacements': <Object>[],
      },
    });

    expect(awaiting.supportingDocuments.single.id, 'document-1');
    expect(awaiting.correctionRequest?.documents.single.label, 'Valid ID');
    expect(awaiting.correctionRequest?.requestedBy, 'Case Worker One');
    expect(awaiting.correctionRequest?.isComplete, isFalse);

    final complete = CorrectionRequest.fromJson({
      'id': 'correction-1',
      'remark': 'Retake the ID.',
      'documents': [
        {'documentId': 'document-1', 'label': 'Valid ID'},
      ],
      'replacements': [
        {'replacesDocumentId': 'document-1'},
      ],
    });
    expect(complete.hasReplacement('document-1'), isTrue);
    expect(complete.isComplete, isTrue);
  });

  test('sorts requests newest first and filters tabs', () {
    final requests = [
      request('old', '2026-01-01', 'approved'),
      request('new', '2026-03-01', 'pending'),
      request('middle', '2026-02-01', 'pending'),
    ];
    expect(sortApplicantRequests(requests).map((item) => item.id), [
      'new',
      'middle',
      'old',
    ]);
    expect(
      filterApplicantRequests(requests, 'pending').map((item) => item.id),
      ['new', 'middle'],
    );
    expect(filterApplicantRequests(requests, null), hasLength(3));
  });

  test('deduplicates API and paginated records by stable request ID', () {
    final pageOne = [
      ApplicantRequest(
        id: 'internal-1',
        requestId: 'LINGAP-2026-00001',
        assistanceType: 'Hospital Assistance',
        dateSubmitted: DateTime.utc(2026, 9, 20),
        lastUpdatedAt: DateTime.utc(2026, 9, 20, 8),
        status: 'pending',
        remarks: 'Older copy',
      ),
      ApplicantRequest(
        id: 'internal-2',
        requestId: 'LINGAP-2026-00002',
        assistanceType: 'Hospital Assistance',
        dateSubmitted: DateTime.utc(2026, 9, 20),
        status: 'pending',
        remarks: 'Legitimate separate request',
      ),
    ];
    final pageTwo = [
      ApplicantRequest(
        id: 'internal-1',
        requestId: 'LINGAP-2026-00001',
        assistanceType: 'Hospital Assistance',
        dateSubmitted: DateTime.utc(2026, 9, 20),
        lastUpdatedAt: DateTime.utc(2026, 9, 20, 10),
        status: 'under_review',
        remarks: 'Newest copy',
      ),
    ];

    final result = deduplicateApplicantRequests([...pageOne, ...pageTwo]);

    expect(result, hasLength(2));
    expect(
      result.singleWhere((item) => item.stableId == 'LINGAP-2026-00001').status,
      'under_review',
    );
    expect(
      result.map((item) => item.stableId),
      containsAll(['LINGAP-2026-00001', 'LINGAP-2026-00002']),
    );
  });

  test('deduplicates repeated records returned by the history API', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    try {
      final receivedRequest = server.first;
      final api = AidLinkApi(
        baseUrl: 'http://${server.address.address}:${server.port}',
      )..applicantToken = 'applicant-token';
      final history = api.getApplicantRequests();
      final request = await receivedRequest;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'requests': [
            {
              'id': 'internal-1',
              'requestId': 'LINGAP-2026-00001',
              'status': 'pending',
              'assistanceType': 'Hospital Assistance',
              'dateSubmitted': '2026-09-20T08:00:00Z',
              'lastUpdatedAt': '2026-09-20T09:00:00Z',
            },
            {
              'id': 'internal-1',
              'requestId': 'LINGAP-2026-00001',
              'status': 'approved',
              'assistanceType': 'Hospital Assistance',
              'dateSubmitted': '2026-09-20T08:00:00Z',
              'lastUpdatedAt': '2026-09-20T10:00:00Z',
            },
            {
              'id': 'internal-2',
              'requestId': 'LINGAP-2026-00002',
              'status': 'pending',
              'assistanceType': 'Hospital Assistance',
              'dateSubmitted': '2026-09-20T08:00:00Z',
            },
          ],
        }),
      );
      await request.response.close();

      final result = await history;
      expect(result, hasLength(2));
      expect(
        result
            .singleWhere((item) => item.stableId == 'LINGAP-2026-00001')
            .status,
        'approved',
      );
    } finally {
      await server.close(force: true);
    }
  });

  test(
    'only ready-for-claiming requests with imageDataUrl have QR visibility data',
    () {
      final approved = ApplicantRequest.fromJson({
        'id': 'approved',
        'status': 'ready_for_claiming',
        'dateSubmitted': '2026-01-01T00:00:00Z',
        'qrCode': {
          'value': 'opaque',
          'imageDataUrl': 'data:image/png;base64,AA==',
        },
      });
      final missingImage = ApplicantRequest.fromJson({
        'id': 'pending',
        'status': 'pending',
        'dateSubmitted': '2026-01-01T00:00:00Z',
        'qrCode': {'value': 'opaque'},
      });
      expect(shouldShowApprovedQr(approved), isTrue);
      expect(shouldShowApprovedQr(missingImage), isFalse);
    },
  );

  test('parses guarantee letter, facility metadata, and distance', () {
    final item = ApplicantRequest.fromJson({
      'id': 'request',
      'status': 'approved',
      'dateSubmitted': '2026-01-01T00:00:00Z',
      'guaranteeLetter': {'name': 'letter.pdf', 'url': '/uploads/letter.pdf'},
      'protectedLetter': {'status': 'approved', 'version': 3},
      'latitude': 7.07,
      'longitude': 125.61,
      'assignedFacility': {
        'name': 'AidLink Hospital',
        'type': 'Hospital',
        'address': 'Davao City',
        'phone': '09170000000',
        'operatingHours': '24 hours',
        'latitude': 7.08,
        'longitude': 125.62,
      },
    });
    expect(item.guaranteeLetter?.url, '/uploads/letter.pdf');
    expect(item.protectedLetterStatus, 'approved');
    expect(item.protectedLetterVersion, 3);
    expect(item.assignedFacility?.contactDetails, contains('09170000000'));
    expect(
      item.assignedFacility?.distanceFrom(
        item.applicantLatitude,
        item.applicantLongitude,
      ),
      greaterThan(0),
    );
  });

  test('parses notification read state and document analysis warnings', () {
    final notification = ApplicantNotification.fromJson({
      'id': 'notification-1',
      'title': 'Request approved',
      'body': 'Your request is ready.',
      'createdAt': '2026-01-01T00:00:00Z',
      'isRead': false,
      'requestId': 'request-1',
    });
    final analysis = DocumentAnalysis.fromJson({
      'accepted': false,
      'documentType': 'valid_id',
      'fileName': 'id.jpg',
      'issues': [
        {
          'code': 'excessive_glare',
          'message': 'Excessive glare covers part of the image.',
          'fix': 'Disable flash and retake the photo.',
        },
      ],
      'warnings': ['The page is close to the image edge.'],
      'orientation': 'portrait',
      'analyzerVersion': 'aidlink-document-quality-v2',
      'analyzedAt': '2026-09-12T00:00:00.000Z',
      'authenticityVerified': false,
    });
    expect(notification.read, isFalse);
    expect(notification.requestId, 'request-1');
    expect(analysis.accepted, isFalse);
    expect(analysis.warnings, hasLength(1));
    expect(analysis.issues.single.code, 'excessive_glare');
    expect(analysis.issues.single.fix, contains('retake'));
    expect(analysis.orientation, 'portrait');
    expect(analysis.analyzerVersion, 'aidlink-document-quality-v2');
    expect(analysis.analyzedAt, '2026-09-12T00:00:00.000Z');
    expect(analysis.authenticityVerified, isFalse);
    expect(
      markNotificationReadLocally([notification], notification.id).single.read,
      isTrue,
    );
  });

  test('identifies the API as offline without exposing private data', () {
    const exception = AidLinkApiException(
      'AidLink is unavailable. Check your connection and try again.',
    );
    expect(exception.message, contains('unavailable'));
    expect(exception.message, isNot(contains('server')));
    expect(exception.message, isNot(contains('http')));
  });

  test('keeps relative API file URLs on the configured server', () {
    final api = AidLinkApi(baseUrl: 'http://192.168.1.5:5000');
    expect(
      api.resolveUrl('/uploads/letter.pdf'),
      'http://192.168.1.5:5000/uploads/letter.pdf',
    );
    expect(
      api.resolveUrl('https://files.example/letter.pdf'),
      startsWith('https://'),
    );
  });

  test('recognizes only supported in-app Guarantee Letter formats', () {
    expect(
      isSupportedInAppDocument('/letters/guarantee.PDF?download=1'),
      isTrue,
    );
    expect(
      isSupportedInAppDocument('https://files.example/letter.png'),
      isTrue,
    );
    expect(isSupportedInAppDocument('/letters/letter.docx'), isFalse);
  });

  test('distinguishes offline failures from other API errors', () {
    expect(isOfflineMessage('AidLink is unavailable.'), isTrue);
    expect(isOfflineMessage('The request was rejected.'), isFalse);
  });

  test('builds facility map and call actions without changing assignment', () {
    const facility = AssignedFacility(
      id: 'facility-1',
      name: 'City Hospital',
      type: 'hospital',
      address: 'Davao City',
      active: true,
      phone: '+63 917 000 0000',
      latitude: 7.07,
      longitude: 125.61,
    );
    expect(facilityMapsUri(facility).scheme, 'geo');
    expect(
      Uri.decodeComponent(facilityMapsUri(facility).query),
      contains('7.07,125.61'),
    );
    expect(facilityCallUri(facility.phone).scheme, 'tel');
    expect(facility.id, 'facility-1');
  });

  test('uses a dedicated expired-authentication error', () {
    const error = AidLinkAuthenticationException();
    expect(error, isA<AidLinkApiException>());
    expect(error.message, contains('expired'));
  });

  test('parses alternate backend QR and Guarantee Letter fields', () {
    final item = ApplicantRequest.fromJson({
      'id': 'request-2',
      'status': 'ready_for_claiming',
      'dateSubmitted': '2026-08-23T00:00:00Z',
      'guaranteeLetterUrl': '/letters/request-2.pdf',
      'qrCodeImageDataUrl': 'data:image/png;base64,AA==',
    });
    expect(item.guaranteeLetter?.url, '/letters/request-2.pdf');
    expect(shouldShowApprovedQr(item), isTrue);
  });

  test('parses nested status QR and Guarantee Letter objects', () {
    final status = ApplicationStatus.fromJson({
      'status': 'approved',
      'qrCode': {
        'value': 'verification-token',
        'imageDataUrl': 'data:image/png;base64,AA==',
      },
      'guaranteeLetter': {
        'name': 'approval.png',
        'url': 'http://localhost:5000/uploads/approval.png',
      },
    });

    expect(status.qrCode, 'verification-token');
    expect(status.qrCodeImageDataUrl, 'data:image/png;base64,AA==');
    expect(
      status.guaranteeLetterUrl,
      'http://localhost:5000/uploads/approval.png',
    );
  });

  test('repairs legacy stringified status objects and loopback file URLs', () {
    final status = ApplicationStatus.fromJson({
      'status': 'approved',
      'qrCode':
          '{value: verification-token, imageDataUrl: data:image/png;base64,AA==}',
      'guaranteeLetter':
          '{name: approval.png, url: http://localhost:5000/uploads/approval.png}',
    });
    final api = AidLinkApi(baseUrl: 'http://10.0.254.22:5000');

    expect(status.qrCode, 'verification-token');
    expect(status.qrCodeImageDataUrl, 'data:image/png;base64,AA==');
    expect(
      api.resolveUrl(status.guaranteeLetterUrl),
      'http://10.0.254.22:5000/uploads/approval.png',
    );
  });
}
