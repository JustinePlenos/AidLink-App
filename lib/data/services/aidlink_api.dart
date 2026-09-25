import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

class AidLinkApiException implements Exception {
  const AidLinkApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AidLinkAuthenticationException extends AidLinkApiException {
  const AidLinkAuthenticationException()
    : super('Your session has expired. Please sign in again.');
}

class ApplicantMfaChallenge {
  const ApplicantMfaChallenge({
    required this.challengeToken,
    required this.methods,
    required this.maskedPhone,
  });
  final String challengeToken;
  final List<String> methods;
  final String maskedPhone;

  factory ApplicantMfaChallenge.fromJson(Map<String, dynamic> json) =>
      ApplicantMfaChallenge(
        challengeToken: json['challengeToken']?.toString() ?? '',
        methods: (json['methods'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
        maskedPhone: json['maskedPhone']?.toString() ?? '',
      );
}

class ApplicantMfaChallengeException extends AidLinkApiException {
  const ApplicantMfaChallengeException(this.challenge)
    : super('A second verification step is required.');
  final ApplicantMfaChallenge challenge;
}

class ApplicantMfaStatus {
  const ApplicantMfaStatus({
    required this.enabled,
    required this.smsFallbackAvailable,
    required this.recoveryCodesRemaining,
    this.enrolledAt,
  });
  final bool enabled;
  final bool smsFallbackAvailable;
  final int recoveryCodesRemaining;
  final DateTime? enrolledAt;

  factory ApplicantMfaStatus.fromJson(Map<String, dynamic> json) =>
      ApplicantMfaStatus(
        enabled: json['enabled'] == true,
        smsFallbackAvailable: json['smsFallbackAvailable'] == true,
        recoveryCodesRemaining:
            int.tryParse(json['recoveryCodesRemaining']?.toString() ?? '') ?? 0,
        enrolledAt: DateTime.tryParse(json['enrolledAt']?.toString() ?? ''),
      );
}

class ApplicantMfaEnrollment {
  const ApplicantMfaEnrollment({
    required this.secret,
    required this.otpauthUri,
    required this.expiresAt,
  });
  final String secret;
  final String otpauthUri;
  final DateTime expiresAt;

  factory ApplicantMfaEnrollment.fromJson(Map<String, dynamic> json) =>
      ApplicantMfaEnrollment(
        secret: json['secret']?.toString() ?? '',
        otpauthUri: json['otpauthUri']?.toString() ?? '',
        expiresAt:
            DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class ApplicantMfaRecoveryResult {
  const ApplicantMfaRecoveryResult({
    required this.status,
    required this.recoveryCodes,
    required this.token,
  });
  final ApplicantMfaStatus status;
  final List<String> recoveryCodes;
  final String token;

  factory ApplicantMfaRecoveryResult.fromJson(Map<String, dynamic> json) =>
      ApplicantMfaRecoveryResult(
        status: ApplicantMfaStatus.fromJson(
          Map<String, dynamic>.from(json['status'] as Map? ?? const {}),
        ),
        recoveryCodes: (json['recoveryCodes'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
        token: json['token']?.toString() ?? '',
      );
}

class ApplicantStepUpStart {
  const ApplicantStepUpStart({this.stepUpToken, this.challenge});
  final String? stepUpToken;
  final ApplicantMfaChallenge? challenge;
}

class ApplicantSession {
  const ApplicantSession({
    required this.token,
    required this.applicantId,
    required this.user,
  });

  final String token;
  final String applicantId;
  final Map<String, dynamic> user;

  factory ApplicantSession.fromJson(Map<String, dynamic> json) {
    final token = json['token']?.toString().trim() ?? '';
    final user = json['user'];
    if (token.isEmpty || user is! Map) {
      throw const AidLinkApiException(
        'Sign-in could not be completed. Please try again.',
      );
    }
    final userMap = Map<String, dynamic>.from(user);
    final applicantIds =
        [
              json['applicantId'],
              userMap['id'],
              userMap['_id'],
              userMap['applicantId'],
              userMap['userId'],
            ]
            .map((value) => value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty);
    final distinctApplicantIds = applicantIds.toSet();
    if (distinctApplicantIds.length != 1) {
      throw const AidLinkApiException(
        'We could not confirm your account. Please sign in again.',
      );
    }
    final applicantId = distinctApplicantIds.single;
    return ApplicantSession(
      token: token,
      applicantId: applicantId,
      user: userMap,
    );
  }
}

class IdentityVerification {
  const IdentityVerification({
    required this.status,
    required this.accountStatus,
    this.documentName = '',
    this.uploadedAt,
    this.decisionNotes = '',
  });
  final String status;
  final String accountStatus;
  final String documentName;
  final DateTime? uploadedAt;
  final String decisionNotes;
  bool get isApproved => status == 'approved';

  factory IdentityVerification.fromJson(Map<String, dynamic> json) {
    final raw = json['identityVerification'];
    final verification = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final document = verification['document'];
    final decision = verification['decision'];
    return IdentityVerification(
      status:
          (json['verificationStatus'] ?? verification['status'] ?? 'unverified')
              .toString(),
      accountStatus: (json['accountStatus'] ?? 'basic').toString(),
      documentName: document is Map ? document['name']?.toString() ?? '' : '',
      uploadedAt: document is Map
          ? DateTime.tryParse(document['uploadedAt']?.toString() ?? '')
          : null,
      decisionNotes: decision is Map ? decision['notes']?.toString() ?? '' : '',
    );
  }
}

class ApplicationRequirements {
  const ApplicationRequirements({
    required this.documents,
    required this.receiptValidityDays,
  });
  final List<String> documents;
  final int receiptValidityDays;
}

const applicantStatuses = {
  'pending',
  'under_review',
  'correction_requested',
  'approved',
  'ready_for_claiming',
  'denied',
};

String normalizeStatus(Object? value) {
  final status = value?.toString().toLowerCase().trim().replaceAll(
    RegExp(r'[\s-]+'),
    '_',
  );
  return applicantStatuses.contains(status) ? status! : 'pending';
}

Map<String, dynamic>? _objectMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String && value.trimLeft().startsWith('{')) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Older app versions saved Dart's Map.toString() representation.
    }
  }
  return null;
}

String qrCodeValueFrom(Object? value) {
  final map = _objectMap(value);
  if (map != null) return map['value']?.toString().trim() ?? '';
  final text = value?.toString().trim() ?? '';
  final legacy = RegExp(r'^\{\s*value:\s*([^,}]*)').firstMatch(text);
  return legacy?.group(1)?.trim() ?? text;
}

String qrCodeImageFrom(Object? value) {
  final map = _objectMap(value);
  if (map != null) return map['imageDataUrl']?.toString().trim() ?? '';
  final text = value?.toString().trim() ?? '';
  final legacy = RegExp(
    r'(?:^|,\s*)imageDataUrl:\s*(.*?)\s*\}$',
  ).firstMatch(text);
  return legacy?.group(1)?.trim() ?? '';
}

String documentUrlFrom(Object? value) {
  final map = _objectMap(value);
  if (map != null) return map['url']?.toString().trim() ?? '';
  final text = value?.toString().trim() ?? '';
  final legacy = RegExp(r'(?:^|,\s*)url:\s*(.*?)\s*\}$').firstMatch(text);
  return legacy?.group(1)?.trim() ?? text;
}

List<ApplicantRequest> sortApplicantRequests(
  Iterable<ApplicantRequest> requests,
) {
  final sorted = requests.toList()
    ..sort((a, b) => b.dateSubmitted.compareTo(a.dateSubmitted));
  return sorted;
}

List<ApplicantRequest> deduplicateApplicantRequests(
  Iterable<ApplicantRequest> requests,
) {
  final unique = <String, ApplicantRequest>{};
  for (final request in requests) {
    final key = request.stableId.trim();
    if (key.isEmpty) continue;
    final existing = unique[key];
    if (existing == null || request.freshness.isAfter(existing.freshness)) {
      unique[key] = request;
    }
  }
  return sortApplicantRequests(unique.values);
}

List<ApplicantRequest> filterApplicantRequests(
  Iterable<ApplicantRequest> requests,
  String? status,
) => requests
    .where((request) => status == null || request.status == status)
    .toList();

bool shouldShowApprovedQr(ApplicantRequest request) =>
    request.status == 'ready_for_claiming' &&
    request.qrCode?.imageDataUrl.trim().isNotEmpty == true;

bool isSupportedInAppDocument(String nameOrUrl) {
  final path =
      Uri.tryParse(nameOrUrl)?.path.toLowerCase() ?? nameOrUrl.toLowerCase();
  return path.endsWith('.pdf') ||
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png');
}

bool isOfflineMessage(String message) =>
    message.toLowerCase().contains('cannot reach') ||
    message.toLowerCase().contains('unavailable') ||
    message.toLowerCase().contains('network') ||
    message.toLowerCase().contains('socket');

Uri facilityMapsUri(AssignedFacility facility) {
  final query = facility.latitude != null && facility.longitude != null
      ? '${facility.latitude},${facility.longitude}'
      : facility.address;
  return Uri.parse('geo:0,0?q=${Uri.encodeComponent(query)}');
}

Uri facilityCallUri(String phone) => Uri(scheme: 'tel', path: phone);

List<ApplicantNotification> markNotificationReadLocally(
  Iterable<ApplicantNotification> notifications,
  String id,
) => notifications
    .map(
      (item) => item.id == id
          ? ApplicantNotification(
              id: item.id,
              title: item.title,
              message: item.message,
              createdAt: item.createdAt,
              read: true,
              requestId: item.requestId,
            )
          : item,
    )
    .toList();

class GuaranteeLetter {
  const GuaranteeLetter({required this.name, required this.url});
  final String name;
  final String url;

  factory GuaranteeLetter.fromJson(Map<String, dynamic> json) =>
      GuaranteeLetter(
        name: json['name']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
      );
}

class QrCodeData {
  const QrCodeData({required this.value, required this.imageDataUrl});
  final String value;
  final String imageDataUrl;

  factory QrCodeData.fromJson(Map<String, dynamic> json) => QrCodeData(
    value: json['value']?.toString() ?? '',
    imageDataUrl: json['imageDataUrl']?.toString() ?? '',
  );
}

class AssignedFacility {
  const AssignedFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.active,
    this.phone = '',
    this.email = '',
    this.operatingHours = '',
    this.latitude,
    this.longitude,
  });
  final String id;
  final String name;
  final String type;
  final String address;
  final bool active;
  final String phone;
  final String email;
  final String operatingHours;
  final double? latitude;
  final double? longitude;

  String get contactDetails =>
      [phone, email].where((value) => value.trim().isNotEmpty).join(' • ');

  double? distanceFrom(double? latitude, double? longitude) {
    if (latitude == null ||
        longitude == null ||
        this.latitude == null ||
        this.longitude == null) {
      return null;
    }
    final latitudeDelta = _radians(this.latitude! - latitude);
    final longitudeDelta = _radians(this.longitude! - longitude);
    final a =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(_radians(latitude)) *
            math.cos(_radians(this.latitude!)) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    return (6371 * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))).toDouble();
  }

  static double _radians(double value) => value * math.pi / 180;

  factory AssignedFacility.fromJson(Map<String, dynamic> json) =>
      AssignedFacility(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        active: json['active'] != false,
        phone: (json['phone'] ?? json['contactNumber'] ?? '')?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        operatingHours:
            (json['operatingHours'] ?? json['hours'] ?? '')?.toString() ?? '',
        latitude: _coordinate(json['latitude'] ?? json['lat']),
        longitude: _coordinate(json['longitude'] ?? json['lng'] ?? json['lon']),
      );

  static double? _coordinate(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
}

class SupportingDocument {
  const SupportingDocument({
    this.id = '',
    required this.name,
    required this.url,
    this.type = '',
  });
  final String id;
  final String name;
  final String url;
  final String type;

  factory SupportingDocument.fromJson(Map<String, dynamic> json) =>
      SupportingDocument(
        id: json['id']?.toString() ?? '',
        name: (json['name'] ?? json['fileName'] ?? '')?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        type: (json['documentType'] ?? json['type'] ?? '')?.toString() ?? '',
      );
}

class CorrectionDocumentRequest {
  const CorrectionDocumentRequest({
    required this.documentId,
    required this.name,
    required this.label,
    required this.documentType,
  });

  final String documentId;
  final String name;
  final String label;
  final String documentType;

  factory CorrectionDocumentRequest.fromJson(Map<String, dynamic> json) =>
      CorrectionDocumentRequest(
        documentId: json['documentId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        label:
            (json['label'] ?? json['documentType'] ?? json['name'])
                ?.toString() ??
            'Document',
        documentType: json['documentType']?.toString() ?? '',
      );
}

class CorrectionRequest {
  const CorrectionRequest({
    required this.id,
    required this.remark,
    required this.requestedAt,
    required this.requestedBy,
    required this.documents,
    required this.replacedDocumentIds,
  });

  final String id;
  final String remark;
  final DateTime? requestedAt;
  final String requestedBy;
  final List<CorrectionDocumentRequest> documents;
  final Set<String> replacedDocumentIds;

  bool hasReplacement(String documentId) =>
      replacedDocumentIds.contains(documentId);

  bool get isComplete =>
      documents.isNotEmpty &&
      documents.every((document) => hasReplacement(document.documentId));

  factory CorrectionRequest.fromJson(Map<String, dynamic> json) {
    final documents = json['documents'];
    final replacements = json['replacements'];
    return CorrectionRequest(
      id: json['id']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      requestedAt: DateTime.tryParse(json['requestedAt']?.toString() ?? ''),
      requestedBy: json['requestedBy']?.toString() ?? 'Case Worker',
      documents: documents is List
          ? documents
                .whereType<Map>()
                .map(
                  (item) => CorrectionDocumentRequest.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      replacedDocumentIds: replacements is List
          ? replacements
                .whereType<Map>()
                .map((item) => item['replacesDocumentId']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet()
          : const {},
    );
  }
}

class ApplicantRequest {
  const ApplicantRequest({
    required this.id,
    this.requestId = '',
    required this.assistanceType,
    required this.dateSubmitted,
    this.lastUpdatedAt,
    required this.status,
    required this.remarks,
    this.guaranteeLetter,
    this.protectedLetterStatus,
    this.protectedLetterVersion,
    this.qrCode,
    this.assignedFacility,
    this.approvalDate,
    this.supportingDocuments = const [],
    this.applicantLatitude,
    this.applicantLongitude,
    this.correctionRequest,
  });
  final String id;
  final String requestId;
  final String assistanceType;
  final DateTime dateSubmitted;
  final DateTime? lastUpdatedAt;
  final String status;
  final String remarks;
  final GuaranteeLetter? guaranteeLetter;
  final String? protectedLetterStatus;
  final int? protectedLetterVersion;
  final QrCodeData? qrCode;
  final AssignedFacility? assignedFacility;
  final DateTime? approvalDate;
  final List<SupportingDocument> supportingDocuments;
  final double? applicantLatitude;
  final double? applicantLongitude;
  final CorrectionRequest? correctionRequest;

  String get stableId => requestId.trim().isNotEmpty ? requestId : id;
  DateTime get freshness => lastUpdatedAt ?? approvalDate ?? dateSubmitted;

  factory ApplicantRequest.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) =>
        value == null ? null : DateTime.tryParse(value.toString());
    final letter = json['guaranteeLetter'];
    final protectedLetter = json['protectedLetter'];
    final qr = json['qrCode'];
    final facility = json['assignedFacility'];
    final documents = json['supportingDocuments'] ?? json['documents'];
    final correction = json['correctionRequest'];
    return ApplicantRequest(
      id:
          (json['id'] ?? json['requestId'] ?? json['referenceNumber'])
              ?.toString() ??
          '',
      requestId:
          (json['requestId'] ?? json['referenceNumber'] ?? json['id'])
              ?.toString() ??
          '',
      assistanceType:
          (json['assistanceType'] ?? json['type'])?.toString() ?? '',
      dateSubmitted:
          parseDate(json['dateSubmitted'] ?? json['submittedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastUpdatedAt: parseDate(
        json['lastUpdatedAt'] ?? json['processedAt'] ?? json['updatedAt'],
      ),
      status: normalizeStatus(json['status']),
      remarks: json['remarks']?.toString() ?? '',
      guaranteeLetter: letter is Map
          ? GuaranteeLetter.fromJson(Map<String, dynamic>.from(letter))
          : (json['guaranteeLetterUrl'] ?? letter)?.toString().isNotEmpty ==
                true
          ? GuaranteeLetter(
              name: (json['guaranteeLetterName'] ?? 'Guarantee Letter')
                  .toString(),
              url: (json['guaranteeLetterUrl'] ?? letter).toString(),
            )
          : null,
      protectedLetterStatus: protectedLetter is Map
          ? protectedLetter['status']?.toString()
          : null,
      protectedLetterVersion: protectedLetter is Map
          ? int.tryParse(protectedLetter['version']?.toString() ?? '')
          : null,
      qrCode: qr is Map
          ? QrCodeData.fromJson(Map<String, dynamic>.from(qr))
          : json['qrCodeImageDataUrl']?.toString().isNotEmpty == true
          ? QrCodeData(
              value: json['qrCodeValue']?.toString() ?? '',
              imageDataUrl: json['qrCodeImageDataUrl'].toString(),
            )
          : null,
      assignedFacility: facility is Map
          ? AssignedFacility.fromJson(Map<String, dynamic>.from(facility))
          : null,
      approvalDate: parseDate(json['approvalDate']),
      supportingDocuments: documents is List
          ? documents
                .whereType<Map>()
                .map(
                  (item) => SupportingDocument.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      applicantLatitude: _coordinate(
        json['applicantLatitude'] ?? json['latitude'],
      ),
      applicantLongitude: _coordinate(
        json['applicantLongitude'] ?? json['longitude'],
      ),
      correctionRequest: correction is Map
          ? CorrectionRequest.fromJson(Map<String, dynamic>.from(correction))
          : null,
    );
  }

  static double? _coordinate(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
}

class ApplicantNotification {
  const ApplicantNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    this.requestId,
  });
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String? requestId;

  factory ApplicantNotification.fromJson(Map<String, dynamic> json) =>
      ApplicantNotification(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'AidLink update',
        message: (json['message'] ?? json['body'])?.toString() ?? '',
        createdAt:
            DateTime.tryParse(
              (json['createdAt'] ?? json['dateCreated'])?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        read: json['read'] == true || json['isRead'] == true,
        requestId: json['requestId']?.toString(),
      );
}

class DocumentQualityIssue {
  const DocumentQualityIssue({
    required this.code,
    required this.message,
    required this.fix,
  });

  final String code;
  final String message;
  final String fix;

  factory DocumentQualityIssue.fromJson(Map<String, dynamic> json) =>
      DocumentQualityIssue(
        code: json['code']?.toString() ?? 'quality_issue',
        message:
            json['message']?.toString() ?? 'The document was not accepted.',
        fix: json['fix']?.toString() ?? 'Replace the document and try again.',
      );
}

class DocumentAnalysis {
  const DocumentAnalysis({
    required this.accepted,
    required this.documentType,
    required this.fileName,
    required this.warnings,
    this.issues = const [],
    this.orientation = 'not_applicable',
    this.analyzerVersion = '',
    this.analyzedAt = '',
    this.authenticityVerified = false,
    this.eligibilityDetermined = false,
    this.decision = '',
    this.confidence,
    this.requiresHumanReview = false,
    this.humanReviewReasons = const [],
    this.explanations = const [],
  });
  final bool accepted;
  final String documentType;
  final String fileName;
  final List<String> warnings;
  final List<DocumentQualityIssue> issues;
  final String orientation;
  final String analyzerVersion;
  final String analyzedAt;
  final bool authenticityVerified;
  final bool eligibilityDetermined;
  final String decision;
  final double? confidence;
  final bool requiresHumanReview;
  final List<String> humanReviewReasons;
  final List<String> explanations;

  factory DocumentAnalysis.fromJson(
    Map<String, dynamic> json, {
    String fallbackDocumentType = '',
    String fallbackFileName = '',
  }) {
    final warnings = json['warnings'];
    final issues = json['issues'];
    return DocumentAnalysis(
      accepted: json['accepted'] == true,
      documentType: json['documentType']?.toString() ?? fallbackDocumentType,
      fileName: json['fileName']?.toString() ?? fallbackFileName,
      warnings: warnings is List
          ? warnings.map((item) => item.toString()).toList()
          : const [],
      issues: issues is List
          ? issues
                .whereType<Map>()
                .map(
                  (item) => DocumentQualityIssue.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      orientation: json['orientation']?.toString() ?? 'not_applicable',
      analyzerVersion: json['analyzerVersion']?.toString() ?? '',
      analyzedAt: json['analyzedAt']?.toString() ?? '',
      // Automated analysis is advisory and can never establish either result.
      authenticityVerified: false,
      eligibilityDetermined: false,
      decision: json['decision']?.toString() ?? '',
      confidence: json['confidence'] is num
          ? (json['confidence'] as num).toDouble()
          : null,
      requiresHumanReview: json['requiresHumanReview'] == true,
      humanReviewReasons: (json['humanReviewReasons'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      explanations: (json['explanations'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class SubmittedApplication {
  const SubmittedApplication({
    required this.referenceNumber,
    required this.status,
    required this.submittedAt,
  });

  final String referenceNumber;
  final String status;
  final DateTime submittedAt;
}

class ApplicationStatus {
  const ApplicationStatus({
    required this.status,
    required this.remarks,
    required this.qrCode,
    required this.qrCodeImageDataUrl,
    required this.qrUsed,
    required this.guaranteeLetterUrl,
  });
  final String status;
  final String remarks;
  final String qrCode;
  final String qrCodeImageDataUrl;
  final bool qrUsed;
  final String guaranteeLetterUrl;

  factory ApplicationStatus.fromJson(Map<String, dynamic> json) {
    final qr = json['qrCode'];
    final nestedQrValue = qrCodeValueFrom(qr);
    final nestedQrImage = qrCodeImageFrom(qr);
    return ApplicationStatus(
      status: normalizeStatus(json['status']),
      remarks: json['remarks']?.toString() ?? '',
      qrCode: nestedQrValue.isNotEmpty
          ? nestedQrValue
          : qrCodeValueFrom(json['qrToken'] ?? json['verificationCode']),
      qrCodeImageDataUrl: nestedQrImage.isNotEmpty
          ? nestedQrImage
          : json['qrCodeImageDataUrl']?.toString().trim() ?? '',
      qrUsed: json['qrUsed'] == true || json['qrStatus'] == 'used',
      guaranteeLetterUrl: documentUrlFrom(
        json['guaranteeLetterUrl'] ?? json['guaranteeLetter'],
      ),
    );
  }
}

class AidLinkApi {
  AidLinkApi({HttpClient? client, String? baseUrl})
    : _client = client ?? HttpClient(),
      baseUrl = baseUrl ?? defaultBaseUrl {
    _client.connectionTimeout = const Duration(seconds: 15);
  }

  static const defaultBaseUrl = String.fromEnvironment(
    'AIDLINK_API_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  final HttpClient _client;
  String baseUrl;
  String? applicantToken;

  Future<ApplicantSession> registerApplicant({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String dateOfBirth,
    required String password,
  }) async {
    final result = await _post('/api/applicant/auth/register', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'password': password,
    });
    return ApplicantSession.fromJson(result);
  }

  Future<ApplicantSession> loginApplicant({
    required String email,
    required String password,
  }) async {
    final result = await _post('/api/applicant/auth/login', {
      'email': email,
      'password': password,
    });
    if (result['mfaRequired'] == true) {
      throw ApplicantMfaChallengeException(
        ApplicantMfaChallenge.fromJson(result),
      );
    }
    return ApplicantSession.fromJson(result);
  }

  Future<ApplicantSession> verifyApplicantMfa({
    required ApplicantMfaChallenge challenge,
    required String method,
    required String code,
  }) async {
    final result = await _post('/api/applicant/auth/mfa/verify', {
      'challengeToken': challenge.challengeToken,
      'method': method,
      'code': code,
    });
    return ApplicantSession.fromJson(result);
  }

  Future<void> requestApplicantMfaSms(
    ApplicantMfaChallenge challenge, {
    bool stepUp = false,
  }) async {
    final body = {'challengeToken': challenge.challengeToken};
    if (stepUp) {
      await _authenticatedJson(
        'POST',
        '/api/applicant/mfa/step-up/sms/request',
        body: body,
      );
    } else {
      await _post('/api/applicant/auth/mfa/sms/request', body);
    }
  }

  Future<ApplicantMfaStatus> getApplicantMfaStatus() async {
    final result = await _authenticatedJson('GET', '/api/applicant/mfa');
    return ApplicantMfaStatus.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<ApplicantMfaEnrollment> startApplicantMfaEnrollment(
    String currentPassword,
  ) async {
    final result = await _authenticatedJson(
      'POST',
      '/api/applicant/mfa/totp/enroll/start',
      body: {'currentPassword': currentPassword},
    );
    return ApplicantMfaEnrollment.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<ApplicantMfaRecoveryResult> confirmApplicantMfaEnrollment(
    String code,
  ) async {
    final result = await _authenticatedJson(
      'POST',
      '/api/applicant/mfa/totp/enroll/confirm',
      body: {'code': code},
    );
    return ApplicantMfaRecoveryResult.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<ApplicantStepUpStart> startApplicantStepUp(
    String currentPassword,
  ) async {
    final result = Map<String, dynamic>.from(
      await _authenticatedJson(
            'POST',
            '/api/applicant/mfa/step-up/start',
            body: {'currentPassword': currentPassword},
          )
          as Map,
    );
    if (result['mfaRequired'] == true) {
      return ApplicantStepUpStart(
        challenge: ApplicantMfaChallenge.fromJson(result),
      );
    }
    return ApplicantStepUpStart(stepUpToken: result['stepUpToken']?.toString());
  }

  Future<String> verifyApplicantStepUp({
    required ApplicantMfaChallenge challenge,
    required String method,
    required String code,
  }) async {
    final result =
        await _authenticatedJson(
              'POST',
              '/api/applicant/mfa/step-up/verify',
              body: {
                'challengeToken': challenge.challengeToken,
                'method': method,
                'code': code,
              },
            )
            as Map;
    return result['stepUpToken']?.toString() ?? '';
  }

  Future<ApplicantMfaRecoveryResult> regenerateApplicantRecoveryCodes(
    String stepUpToken,
  ) async {
    final result = await _authenticatedJson(
      'POST',
      '/api/applicant/mfa/recovery-codes',
      body: {'stepUpToken': stepUpToken},
    );
    return ApplicantMfaRecoveryResult.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<ApplicantMfaStatus> disableApplicantMfa(String stepUpToken) async {
    final result = Map<String, dynamic>.from(
      await _authenticatedJson(
            'DELETE',
            '/api/applicant/mfa',
            body: {'stepUpToken': stepUpToken},
          )
          as Map,
    );
    final token = result['token']?.toString() ?? '';
    if (token.isNotEmpty) applicantToken = token;
    return ApplicantMfaStatus.fromJson(
      Map<String, dynamic>.from(result['status'] as Map? ?? const {}),
    );
  }

  Future<ApplicantSession> updateApplicantContact({
    required String stepUpToken,
    required String email,
    required String phone,
  }) async {
    final result = await _authenticatedJson(
      'PATCH',
      '/api/applicant/account/contact',
      body: {'stepUpToken': stepUpToken, 'email': email, 'phone': phone},
    );
    return ApplicantSession.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<String> changeApplicantPassword({
    required String stepUpToken,
    required String newPassword,
  }) async {
    final result =
        await _authenticatedJson(
              'POST',
              '/api/applicant/account/password',
              body: {'stepUpToken': stepUpToken, 'newPassword': newPassword},
            )
            as Map;
    return result['token']?.toString() ?? '';
  }

  Future<IdentityVerification> getIdentityVerification() async {
    final result = await _authenticatedJson(
      'GET',
      '/api/applicant/identity-verification',
    );
    return IdentityVerification.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<IdentityVerification> uploadIdentityDocument(XFile file) async {
    final result = await _multipartPost(
      '/api/applicant/identity-verification/document',
      file,
      const {},
    );
    return IdentityVerification.fromJson(result);
  }

  Future<dynamic> _authenticatedJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = await _client.openUrl(method, Uri.parse('$baseUrl$path'));
      request.headers.add('Authorization', 'Bearer ${applicantToken ?? ''}');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      final text = await utf8.decoder.bind(response).join();
      if (response.statusCode == 401) {
        throw const AidLinkAuthenticationException();
      }
      dynamic decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AidLinkApiException(
          decoded is Map
              ? decoded['message']?.toString() ??
                    'This action could not be completed. Please try again.'
              : 'This action could not be completed. Please try again.',
        );
      }
      return decoded;
    } on AidLinkApiException {
      rethrow;
    } on SocketException {
      throw const AidLinkApiException(
        'AidLink is unavailable. Check your connection and try again.',
      );
    } on Exception {
      throw const AidLinkApiException(
        'This action could not be completed. Please try again.',
      );
    }
  }

  List<dynamic> _responseList(dynamic value, String key) => value is List
      ? value
      : value is Map && value[key] is List
      ? value[key] as List
      : const [];

  Future<List<ApplicantRequest>> getApplicantRequests() async {
    final result = await _authenticatedJson('GET', '/api/applicant/requests');
    final requests = _responseList(result, 'requests')
        .map(
          (item) =>
              ApplicantRequest.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    return deduplicateApplicantRequests(requests);
  }

  Future<ApplicationRequirements> getApplicationRequirements(
    String assistanceType,
  ) async {
    final result = await _authenticatedJson(
      'GET',
      '/api/applicant/assistance-types/${Uri.encodeComponent(assistanceType)}/required-documents',
    );
    final map = Map<String, dynamic>.from(result as Map);
    final documents = map['requiredDocuments'];
    return ApplicationRequirements(
      documents: documents is List
          ? documents.map((item) => item.toString()).toList()
          : const [],
      receiptValidityDays:
          int.tryParse(map['receiptValidityDays']?.toString() ?? '') ?? 365,
    );
  }

  Future<ApplicantRequest> getApplicantRequest(String id) async {
    final result = await _authenticatedJson(
      'GET',
      '/api/applicant/requests/${Uri.encodeComponent(id)}',
    );
    return ApplicantRequest.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<List<ApplicantNotification>> getNotifications() async {
    final result = await _authenticatedJson('GET', '/api/notifications');
    final notifications = _responseList(result, 'notifications')
        .map(
          (item) => ApplicantNotification.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }

  Future<void> markNotificationRead(String id) async {
    await _authenticatedJson(
      'PUT',
      '/api/notifications/${Uri.encodeComponent(id)}/read',
    );
  }

  Future<DocumentAnalysis> analyzeDocument({
    required XFile file,
    required String documentType,
  }) async {
    final result = await _multipartPost(
      '/api/applicant/documents/analyze',
      file,
      {'documentType': documentType},
    );
    return DocumentAnalysis.fromJson(
      result,
      fallbackDocumentType: documentType,
      fallbackFileName: file.name,
    );
  }

  Future<Map<String, dynamic>> uploadApplicantDocument({
    required XFile file,
    required String documentType,
  }) async {
    final result = await _multipartPost('/api/applicant/documents', file, {
      'documentType': documentType,
    }, fileField: 'documents');
    final documents = result['documents'];
    final uploaded = documents is List && documents.isNotEmpty
        ? documents.first
        : null;
    final url = uploaded is Map ? uploaded['url']?.toString() ?? '' : '';
    if (url.isEmpty) {
      throw const AidLinkApiException(
        'The document upload could not be completed. Please try again.',
      );
    }
    return Map<String, dynamic>.from(uploaded);
  }

  Future<ApplicantRequest> uploadCorrectionDocument({
    required String requestId,
    required String documentId,
    required String documentType,
    required XFile file,
  }) async {
    final result = await _multipartPost(
      '/api/applicant/requests/${Uri.encodeComponent(requestId)}/corrections/documents/${Uri.encodeComponent(documentId)}',
      file,
      {'documentType': documentType},
    );
    final request = result['request'];
    if (request is! Map) {
      throw const AidLinkApiException(
        'The replacement could not be saved. Please try again.',
      );
    }
    return ApplicantRequest.fromJson(Map<String, dynamic>.from(request));
  }

  Future<ApplicantRequest> submitCorrections(String requestId) async {
    final result = await _authenticatedJson(
      'POST',
      '/api/applicant/requests/${Uri.encodeComponent(requestId)}/corrections/submit',
    );
    return ApplicantRequest.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<Map<String, dynamic>> _multipartPost(
    String path,
    XFile file,
    Map<String, String> fields, {
    String fileField = 'document',
  }) async {
    try {
      final request = await _client.postUrl(Uri.parse('$baseUrl$path'));
      request.headers.add('Authorization', 'Bearer ${applicantToken ?? ''}');
      final boundary =
          'AidLinkBoundary${DateTime.now().microsecondsSinceEpoch}';
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: {'boundary': boundary},
      );
      for (final entry in fields.entries) {
        request.write(
          '--$boundary\r\nContent-Disposition: form-data; name="${entry.key}"\r\n\r\n${entry.value}\r\n',
        );
      }
      request.write(
        '--$boundary\r\nContent-Disposition: form-data; name="$fileField"; filename="${file.name}"\r\nContent-Type: ${_documentMimeType(file)}\r\n\r\n',
      );
      request.add(await file.readAsBytes());
      request.write('\r\n--$boundary--\r\n');
      final response = await request.close();
      final text = await utf8.decoder.bind(response).join();
      if (response.statusCode == 401) {
        throw const AidLinkAuthenticationException();
      }
      final result = text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AidLinkApiException(
          result['message']?.toString() ?? 'Document request failed.',
        );
      }
      return result;
    } on AidLinkApiException {
      rethrow;
    } on Exception catch (error) {
      throw AidLinkApiException('Document request failed: $error');
    }
  }

  String _documentMimeType(XFile file) {
    if (file.mimeType?.trim().isNotEmpty == true) return file.mimeType!;
    final name = file.name.toLowerCase();
    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final request = await _client.postUrl(Uri.parse('$baseUrl$path'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close();
      final responseText = await utf8.decoder.bind(response).join();
      Map<String, dynamic> decoded = {};
      if (responseText.isNotEmpty) {
        try {
          decoded = jsonDecode(responseText) as Map<String, dynamic>;
        } on FormatException {
          if (response.statusCode >= 200 && response.statusCode < 300) {
            rethrow;
          }
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AidLinkApiException(
          decoded['message']?.toString() ??
              'This action could not be completed. Please try again.',
        );
      }
      return decoded;
    } on AidLinkApiException {
      rethrow;
    } on SocketException {
      throw const AidLinkApiException(
        'AidLink is unavailable. Check your connection and try again.',
      );
    } on FormatException {
      throw const AidLinkApiException(
        'AidLink returned an unexpected response. Please try again.',
      );
    } on Exception {
      throw const AidLinkApiException(
        'This action could not be completed. Please try again.',
      );
    }
  }

  Future<void> testConnection() async {
    try {
      final request = await _client.getUrl(Uri.parse(baseUrl));
      final response = await request.close();
      await response.drain<void>();
    } on SocketException {
      throw const AidLinkApiException(
        'Connection failed. Check the address and network, then try again.',
      );
    } on Exception {
      throw const AidLinkApiException(
        'Connection test could not be completed. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String requirement,
    required XFile file,
  }) async {
    final length = await file.length();
    if (length > 10 * 1024 * 1024) {
      throw const AidLinkApiException(
        'Each document must be 10 MB or smaller.',
      );
    }
    final bytes = await file.readAsBytes();
    final result = await _post('/api/uploads', {
      'name': file.name,
      'documentType': requirement,
      'contentBase64': base64Encode(bytes),
    });
    return {...result, 'name': requirement};
  }

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
  }) async {
    final result =
        await _authenticatedJson(
              'POST',
              '/api/applications',
              body: {
                'clientSubmissionId': clientSubmissionId,
                'beneficiaryType': beneficiaryType,
                'beneficiary': {
                  'fullName': fullName,
                  'address': address,
                  'dateOfBirth': dateOfBirth,
                  'relationshipToApplicant': relationshipToPatient,
                  'sex': sex,
                },
                'fullName': fullName,
                'email': email,
                'phone': phone,
                'address': address,
                'dateOfBirth': dateOfBirth,
                'relationshipToPatient': relationshipToPatient,
                'sex': sex,
                'assistanceType': assistanceType,
                'incomeSource': incomeSource,
                'patientCircumstance': patientCircumstance,
                'additionalDetails': additionalDetails,
                'documents': documents,
                'facilityEvidence': facilityEvidence,
              },
            )
            as Map<String, dynamic>;
    return SubmittedApplication(
      referenceNumber: result['requestId'] as String,
      status: normalizeStatus(result['status']),
      submittedAt: DateTime.parse(result['dateSubmitted'] as String),
    );
  }

  Future<ApplicationStatus> getApplicationStatus({
    required String referenceNumber,
  }) async {
    final requestId = Uri.encodeComponent(referenceNumber);
    final result = await _authenticatedJson(
      'GET',
      '/api/applications/$requestId/status',
    );
    return ApplicationStatus.fromJson(Map<String, dynamic>.from(result as Map));
  }

  String resolveUrl(String value) {
    final trimmed = documentUrlFrom(value);
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      final isLoopback =
          uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '::1';
      final configured = Uri.tryParse(baseUrl);
      if (isLoopback && configured != null && configured.hasScheme) {
        return configured
            .replace(
              path: uri.path,
              query: uri.hasQuery ? uri.query : null,
              fragment: uri.hasFragment ? uri.fragment : null,
            )
            .toString();
      }
      return trimmed;
    }
    return '$baseUrl${trimmed.startsWith('/') ? '' : '/'}$trimmed';
  }

  Future<Uint8List> downloadFile(String value) async {
    final url = resolveUrl(value);
    try {
      final request = await _client.getUrl(Uri.parse(url));
      if (applicantToken != null) {
        request.headers.add('Authorization', 'Bearer $applicantToken');
      }
      final response = await request.close();
      if (response.statusCode == 401) {
        throw const AidLinkAuthenticationException();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        throw AidLinkApiException(
          'Could not download the document (HTTP ${response.statusCode}).',
        );
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return Uint8List.fromList(bytes);
    } on AidLinkApiException {
      rethrow;
    } on Exception catch (error) {
      throw AidLinkApiException('Could not download the document: $error');
    }
  }
}
