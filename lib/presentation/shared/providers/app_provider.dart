import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/aidlink_api.dart';

class RequestorProfile {
  const RequestorProfile({
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.suffix,
    required this.street,
    required this.subdivision,
    required this.barangay,
    required this.district,
    required this.contactNumber,
    required this.email,
    this.birthDate = '',
  });

  final String lastName;
  final String firstName;
  final String middleName;
  final String suffix;
  final String street;
  final String subdivision;
  final String barangay;
  final String district;
  final String contactNumber;
  final String email;
  final String birthDate;

  String get fullName => [
    firstName,
    middleName,
    lastName,
    suffix,
  ].where((part) => part.trim().isNotEmpty).join(' ');

  Map<String, dynamic> toJson() => {
    'lastName': lastName,
    'firstName': firstName,
    'middleName': middleName,
    'suffix': suffix,
    'street': street,
    'subdivision': subdivision,
    'barangay': barangay,
    'district': district,
    'contactNumber': contactNumber,
    'email': email,
    'birthDate': birthDate,
  };

  factory RequestorProfile.fromJson(Map<String, dynamic> json) =>
      RequestorProfile(
        lastName: json['lastName'] ?? '',
        firstName: json['firstName'] ?? '',
        middleName: json['middleName'] ?? '',
        suffix: json['suffix'] ?? '',
        street: json['street'] ?? '',
        subdivision: json['subdivision'] ?? '',
        barangay: json['barangay'] ?? '',
        district: json['district'] ?? '',
        contactNumber: json['contactNumber'] ?? '',
        email: json['email'] ?? '',
        birthDate: json['birthDate'] ?? '',
      );

  factory RequestorProfile.fromApplicantAccount(Map<String, dynamic> json) {
    final fullName = json['fullName']?.toString().trim() ?? '';
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    return RequestorProfile(
      lastName: parts.length > 1 ? parts.last : '',
      firstName: parts.length > 1
          ? parts.sublist(0, parts.length - 1).join(' ')
          : fullName,
      middleName: '',
      suffix: '',
      street: json['address']?.toString() ?? '',
      subdivision: '',
      barangay: '',
      district: '',
      contactNumber: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      birthDate: json['dateOfBirth']?.toString() ?? '',
    );
  }
}

class PatientDetails {
  const PatientDetails({
    this.beneficiaryType = beneficiaryTypeSelf,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.suffix,
    required this.street,
    required this.subdivision,
    required this.barangay,
    required this.district,
    required this.relationshipToPatient,
    required this.sex,
    required this.birthDate,
  });

  static const beneficiaryTypeSelf = 'self';
  static const beneficiaryTypeOther = 'other';

  final String beneficiaryType;
  final String lastName;
  final String firstName;
  final String middleName;
  final String suffix;
  final String street;
  final String subdivision;
  final String barangay;
  final String district;
  final String relationshipToPatient;
  final String sex;
  final String birthDate;

  bool get isForApplicant => beneficiaryType == beneficiaryTypeSelf;
  String get assistanceForLabel =>
      isForApplicant ? 'For myself' : 'For someone else';

  String get fullName => [
    firstName,
    middleName,
    lastName,
    suffix,
  ].where((part) => part.trim().isNotEmpty).join(' ');

  Map<String, dynamic> toJson() => {
    'beneficiaryType': beneficiaryType,
    'lastName': lastName,
    'firstName': firstName,
    'middleName': middleName,
    'suffix': suffix,
    'street': street,
    'subdivision': subdivision,
    'barangay': barangay,
    'district': district,
    'relationshipToPatient': relationshipToPatient,
    'sex': sex,
    'birthDate': birthDate,
  };

  factory PatientDetails.fromJson(Map<String, dynamic> json) => PatientDetails(
    beneficiaryType:
        json['beneficiaryType'] == beneficiaryTypeOther ||
            (json['beneficiaryType'] == null &&
                (json['relationshipToPatient'] ?? '')
                        .toString()
                        .trim()
                        .toLowerCase() !=
                    'self')
        ? beneficiaryTypeOther
        : beneficiaryTypeSelf,
    lastName: json['lastName'] ?? '',
    firstName: json['firstName'] ?? '',
    middleName: json['middleName'] ?? '',
    suffix: json['suffix'] ?? '',
    street: json['street'] ?? '',
    subdivision: json['subdivision'] ?? '',
    barangay: json['barangay'] ?? '',
    district: json['district'] ?? '',
    relationshipToPatient: json['relationshipToPatient'] ?? '',
    sex: json['sex'] ?? '',
    birthDate: json['birthDate'] ?? '',
  );
}

class AssistanceApplication {
  AssistanceApplication({
    required this.referenceNumber,
    required this.patient,
    required this.assistanceType,
    required this.submittedAt,
    required this.documentNames,
    this.incomeSource = '',
    this.patientCircumstance = '',
    this.additionalDetails = '',
    this.reason = '',
    this.status = 'Pending CMO review',
    this.remarks = '',
    this.qrCode = '',
    this.qrCodeImageDataUrl = '',
    this.qrUsed = false,
    this.guaranteeLetterUrl = '',
  });

  final String referenceNumber;
  final PatientDetails patient;
  final String assistanceType;
  final DateTime submittedAt;
  final List<String> documentNames;
  final String incomeSource;
  final String patientCircumstance;
  final String additionalDetails;
  // Retained only so cached applications created before structured intake
  // remain readable. New applications do not populate this field.
  final String reason;
  String status;
  String remarks;
  String qrCode;
  String qrCodeImageDataUrl;
  bool qrUsed;
  String guaranteeLetterUrl;

  Map<String, dynamic> toJson() => {
    'referenceNumber': referenceNumber,
    'patient': patient.toJson(),
    'assistanceType': assistanceType,
    'submittedAt': submittedAt.toIso8601String(),
    'documentNames': documentNames,
    'incomeSource': incomeSource,
    'patientCircumstance': patientCircumstance,
    'additionalDetails': additionalDetails,
    if (reason.isNotEmpty) 'reason': reason,
    'status': status,
    'remarks': remarks,
    'qrCode': qrCode,
    'qrCodeImageDataUrl': qrCodeImageDataUrl,
    'qrUsed': qrUsed,
    'guaranteeLetterUrl': guaranteeLetterUrl,
  };

  factory AssistanceApplication.fromJson(Map<String, dynamic> json) =>
      AssistanceApplication(
        referenceNumber: json['referenceNumber'] ?? '',
        patient: PatientDetails.fromJson(json['patient']),
        assistanceType: json['assistanceType'] ?? '',
        submittedAt: DateTime.parse(json['submittedAt']),
        documentNames: List<String>.from(json['documentNames'] ?? const []),
        incomeSource: json['incomeSource'] ?? '',
        patientCircumstance: json['patientCircumstance'] ?? '',
        additionalDetails: json['additionalDetails'] ?? '',
        reason: json['reason'] ?? '',
        status: json['status'] ?? 'pending',
        remarks: json['remarks'] ?? '',
        qrCode: qrCodeValueFrom(json['qrCode']),
        qrCodeImageDataUrl:
            json['qrCodeImageDataUrl']?.toString() ??
            qrCodeImageFrom(json['qrCode']),
        qrUsed: json['qrUsed'] ?? false,
        guaranteeLetterUrl: documentUrlFrom(json['guaranteeLetterUrl']),
      );
}

class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
  AppProvider({AidLinkApi? api}) : _api = api ?? AidLinkApi();

  final AidLinkApi _api;
  static const _requestorKey = 'aidlink_requestor';
  static const _applicantIdKey = 'aidlink_applicant_id';
  static const _tokenKey = 'aidlink_applicant_token';
  static const _secureStorage = FlutterSecureStorage();
  static const _legacyApplicationsKey = 'aidlink_applications';
  static const _applicationsKeyPrefix = 'aidlink_applications.';
  static const _signedInKey = 'aidlink_signed_in';
  static const _apiUrlKey = 'aidlink_api_url';
  RequestorProfile? _requestor;
  String? _applicantId;
  final List<AssistanceApplication> _applications = [];
  List<ApplicantRequest> _applicantRequests = const [];
  final Map<String, Future<AssistanceApplication>> _submissionsInFlight = {};
  List<ApplicantNotification> _notifications = const [];
  bool _loadingRequests = false;
  bool _loadingNotifications = false;
  bool _isOnline = true;
  DateTime? _lastSyncedAt;
  String? _connectionError;
  Timer? _notificationPoller;
  int _sessionRevision = 0;
  String? _serverSessionError;
  IdentityVerification _identityVerification = const IdentityVerification(
    status: 'unverified',
    accountStatus: 'basic',
  );

  RequestorProfile? get requestor => _requestor;
  String? get applicantId => _applicantId;
  List<AssistanceApplication> get applications =>
      List.unmodifiable(_applications);
  bool get isSignedIn => _requestor != null;
  bool get hasServerSession =>
      isSignedIn && (_api.applicantToken?.trim().isNotEmpty ?? false);
  String? get serverSessionMessage => !isSignedIn || hasServerSession
      ? null
      : _serverSessionError ??
            'Your profile is saved on this device. Online account access is not connected yet.';
  List<ApplicantRequest> get applicantRequests =>
      List.unmodifiable(_applicantRequests);
  List<ApplicantNotification> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadNotificationCount =>
      _notifications.where((item) => !item.read).length;
  bool get loadingRequests => _loadingRequests;
  bool get loadingNotifications => _loadingNotifications;
  bool get isOnline => _isOnline;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get connectionError => _connectionError;
  String get apiUrl => _api.baseUrl;
  IdentityVerification get identityVerification => _identityVerification;
  bool get isIdentityVerified => _identityVerification.isApproved;

  List<AssignedFacility> get assignedFacilities {
    final unique = <String, AssignedFacility>{};
    for (final request in _applicantRequests) {
      final facility = request.assignedFacility;
      if (facility != null) {
        unique[facility.id.isEmpty ? facility.name : facility.id] = facility;
      }
    }
    return List.unmodifiable(unique.values);
  }

  String resolveApiUrl(String value) => _api.resolveUrl(value);
  Future<Uint8List> downloadFile(String value) =>
      _runAuthenticated(() => _api.downloadFile(value), requiresToken: false);

  Future<Map<String, dynamic>> uploadDocument({
    required String requirement,
    required XFile file,
  }) => _api.uploadDocument(requirement: requirement, file: file);

  Future<DocumentAnalysis> analyzeDocument({
    required XFile file,
    required String documentType,
  }) => _runAuthenticated(
    () => _api.analyzeDocument(file: file, documentType: documentType),
  );

  Future<Map<String, dynamic>> uploadApplicantDocument({
    required XFile file,
    required String documentType,
  }) => _runAuthenticated(
    () => _api.uploadApplicantDocument(file: file, documentType: documentType),
  );

  Future<void> refreshIdentityVerification() async {
    if (!hasServerSession) return;
    _identityVerification = await _runAuthenticated(
      _api.getIdentityVerification,
    );
    _startNotificationPolling();
    notifyListeners();
  }

  Future<void> uploadIdentityDocument(XFile file) async {
    _identityVerification = await _runAuthenticated(
      () => _api.uploadIdentityDocument(file),
    );
    notifyListeners();
  }

  Future<ApplicationRequirements> getApplicationRequirements(
    String assistanceType,
  ) => _runAuthenticated(() => _api.getApplicationRequirements(assistanceType));

  Future<void> setApplicantToken(String token) async {
    final value = token.trim();
    if (value.isEmpty) {
      await _secureStorage.delete(key: _tokenKey);
    } else {
      await _secureStorage.write(key: _tokenKey, value: value);
    }
    _sessionRevision++;
    _api.applicantToken = value.isEmpty ? null : value;
    _serverSessionError = null;
    _startNotificationPolling();
    notifyListeners();
  }

  Future<T> _runAuthenticated<T>(
    Future<T> Function() operation, {
    bool requiresToken = true,
  }) async {
    if (requiresToken && !hasServerSession) {
      throw AidLinkApiException(
        serverSessionMessage ?? 'Sign in before accessing your online account.',
      );
    }
    final revision = _sessionRevision;
    final token = _api.applicantToken;
    try {
      return await operation();
    } on AidLinkAuthenticationException {
      if (token != null && revision == _sessionRevision) {
        _sessionRevision++;
        _api.applicantToken = null;
        _serverSessionError =
            'Online account access has expired. Your saved profile is still available on this device.';
        _applicantRequests = const [];
        _notifications = const [];
        _startNotificationPolling();
        notifyListeners();
        await _secureStorage.delete(key: _tokenKey);
      }
      rethrow;
    }
  }

  Future<void> refreshApplicantRequests() async {
    if (!hasServerSession || !isIdentityVerified || _loadingRequests) return;
    final revision = _sessionRevision;
    _loadingRequests = true;
    notifyListeners();
    try {
      final requests = await _runAuthenticated(_api.getApplicantRequests);
      if (revision != _sessionRevision) return;
      _applicantRequests = deduplicateApplicantRequests(requests);
      _markConnected();
    } on AidLinkApiException catch (error) {
      if (revision == _sessionRevision) _markFailure(error);
      rethrow;
    } finally {
      _loadingRequests = false;
      notifyListeners();
    }
  }

  Future<ApplicantRequest> getApplicantRequest(String id) =>
      _runAuthenticated(() => _api.getApplicantRequest(id));

  void _replaceApplicantRequest(ApplicantRequest request) {
    _applicantRequests = deduplicateApplicantRequests([
      request,
      ..._applicantRequests,
    ]);
    notifyListeners();
  }

  Future<ApplicantRequest> uploadCorrectionDocument({
    required String requestId,
    required String documentId,
    required String documentType,
    required XFile file,
  }) async {
    final request = await _runAuthenticated(
      () => _api.uploadCorrectionDocument(
        requestId: requestId,
        documentId: documentId,
        documentType: documentType,
        file: file,
      ),
    );
    _replaceApplicantRequest(request);
    return request;
  }

  Future<ApplicantRequest> submitCorrections(String requestId) async {
    final request = await _runAuthenticated(
      () => _api.submitCorrections(requestId),
    );
    _replaceApplicantRequest(request);
    await refreshNotifications().catchError((_) {});
    return request;
  }

  Future<void> refreshNotifications() async {
    if (!hasServerSession || !isIdentityVerified || _loadingNotifications) {
      return;
    }
    final revision = _sessionRevision;
    _loadingNotifications = true;
    notifyListeners();
    try {
      final notifications = await _runAuthenticated(_api.getNotifications);
      if (revision != _sessionRevision) return;
      _notifications = notifications;
      _markConnected();
    } on AidLinkApiException catch (error) {
      if (revision == _sessionRevision) _markFailure(error);
      rethrow;
    } finally {
      _loadingNotifications = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationRead(String id) async {
    await _runAuthenticated(() => _api.markNotificationRead(id));
    _notifications = markNotificationReadLocally(_notifications, id);
    _markConnected();
    notifyListeners();
  }

  void _markConnected() {
    _isOnline = true;
    _connectionError = null;
    _lastSyncedAt = DateTime.now();
  }

  void _markFailure(AidLinkApiException error) {
    if (isOfflineMessage(error.message)) {
      _isOnline = false;
      _connectionError = error.message;
    }
  }

  Future<void> refreshAll() async {
    if (!isSignedIn || !isIdentityVerified) return;
    final results = await Future.wait([
      refreshApplicantRequests()
          .then<Object?>((_) => null)
          .catchError((_) => null),
      refreshNotifications().then<Object?>((_) => null).catchError((_) => null),
      refreshStatuses().then<Object?>((_) => null).catchError((_) => null),
    ]);
    // Retain all calls in the Future so pull-to-refresh does not finish early.
    assert(results.length == 3);
  }

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    final preferences = await SharedPreferences.getInstance();
    _api.baseUrl =
        preferences.getString(_apiUrlKey) ?? AidLinkApi.defaultBaseUrl;
    String? token;
    try {
      token = await _secureStorage.read(key: _tokenKey);
    } on Exception {
      token = null;
    }

    final requestorJson = preferences.getString(_requestorKey);
    final applicantId = preferences.getString(_applicantIdKey)?.trim();
    final signedIn = preferences.getBool(_signedInKey) ?? false;
    // Never migrate the old global cache: it cannot be attributed safely to
    // an authenticated account.
    await preferences.remove(_legacyApplicationsKey);
    if (signedIn &&
        requestorJson != null &&
        applicantId != null &&
        applicantId.isNotEmpty &&
        token != null &&
        token.trim().isNotEmpty) {
      try {
        _requestor = RequestorProfile.fromJson(jsonDecode(requestorJson));
        _applicantId = applicantId;
        _api.applicantToken = token;
        _loadApplications(preferences, applicantId);
      } on Object {
        await _clearPersistedApplicantData(preferences);
        await _secureStorage.delete(key: _tokenKey);
        _clearApplicantState();
      }
    } else {
      await _clearPersistedApplicantData(preferences);
      await _secureStorage.delete(key: _tokenKey);
      _clearApplicantState();
    }
    _startNotificationPolling();
  }

  static String _applicationsKeyFor(String applicantId) =>
      '$_applicationsKeyPrefix${base64Url.encode(utf8.encode(applicantId))}';

  void _loadApplications(SharedPreferences preferences, String applicantId) {
    final applicationsJson = preferences.getString(
      _applicationsKeyFor(applicantId),
    );
    _applications.clear();
    if (applicationsJson == null) return;
    _applications.addAll(
      _deduplicateCachedApplications(
        (jsonDecode(applicationsJson) as List).map(
          (item) => AssistanceApplication.fromJson(item),
        ),
      ),
    );
  }

  static List<AssistanceApplication> _deduplicateCachedApplications(
    Iterable<AssistanceApplication> applications,
  ) {
    final byReference = <String, AssistanceApplication>{};
    for (final application in applications) {
      final key = application.referenceNumber.trim();
      if (key.isEmpty) continue;
      final existing = byReference[key];
      if (existing == null ||
          !application.submittedAt.isBefore(existing.submittedAt)) {
        byReference[key] = application;
      }
    }
    final result = byReference.values.toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return result;
  }

  void _clearApplicantState() {
    _requestor = null;
    _applicantId = null;
    _applications.clear();
    _applicantRequests = const [];
    _notifications = const [];
    _api.applicantToken = null;
    _identityVerification = const IdentityVerification(
      status: 'unverified',
      accountStatus: 'basic',
    );
  }

  Future<void> _clearPersistedApplicantData(
    SharedPreferences preferences,
  ) async {
    await preferences.remove(_requestorKey);
    await preferences.remove(_applicantIdKey);
    await preferences.remove(_signedInKey);
    await preferences.remove(_legacyApplicationsKey);
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith(_applicationsKeyPrefix),
    )) {
      await preferences.remove(key);
    }
  }

  void _startNotificationPolling() {
    _notificationPoller?.cancel();
    if (!hasServerSession || !isIdentityVerified) return;
    _notificationPoller = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _refreshNotificationsInBackground(),
    );
  }

  Future<void> _refreshNotificationsInBackground() async {
    try {
      await refreshNotifications();
    } on AidLinkApiException {
      // Refresh records connection failures; background work has no caller
      // to handle a rejected Future. User-initiated refreshes still report it.
    }
  }

  Future<void> _refreshIdentityInBackground() async {
    try {
      await refreshIdentityVerification();
    } on AidLinkApiException {
      // The identity screen keeps the last known state and offers manual retry.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (isIdentityVerified) {
        _refreshNotificationsInBackground();
      } else {
        _refreshIdentityInBackground();
      }
    }
  }

  Future<void> saveApiUrl(String value) async {
    final normalized = _normalizeApiUrl(value);
    _api.baseUrl = normalized;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_apiUrlKey, normalized);
    notifyListeners();
  }

  Future<void> testApiConnection() async {
    try {
      await _api.testConnection();
      _markConnected();
      notifyListeners();
    } on AidLinkApiException catch (error) {
      _markFailure(error);
      notifyListeners();
      rethrow;
    }
  }

  static String _normalizeApiUrl(String value) {
    var candidate = value.trim();
    if (!candidate.contains('://')) candidate = 'http://$candidate';
    while (candidate.endsWith('/')) {
      candidate = candidate.substring(0, candidate.length - 1);
    }
    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException(
        'Enter a valid service address, for example http://192.168.1.5:5000.',
      );
    }
    return candidate;
  }

  Future<void> _persist() async {
    final requestor = _requestor;
    final applicantId = _applicantId;
    if (requestor == null || applicantId == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_requestorKey, jsonEncode(requestor.toJson()));
    await preferences.setString(_applicantIdKey, applicantId);
    await preferences.setBool(_signedInKey, true);
    final uniqueApplications = _deduplicateCachedApplications(_applications);
    _applications
      ..clear()
      ..addAll(uniqueApplications);
    await preferences.setString(
      _applicationsKeyFor(applicantId),
      jsonEncode(_applications.map((item) => item.toJson()).toList()),
    );
    await preferences.remove(_legacyApplicationsKey);
  }

  Future<void> _saveSignedInProfile(
    RequestorProfile requestor,
    String token,
    String applicantId,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final savedProfile = await preferences.setString(
      _requestorKey,
      jsonEncode(requestor.toJson()),
    );
    final savedApplicant =
        savedProfile &&
        await preferences.setString(_applicantIdKey, applicantId);
    final savedSession =
        savedApplicant && await preferences.setBool(_signedInKey, true);
    if (!savedSession) {
      await _clearPersistedApplicantData(preferences);
      throw const AidLinkApiException(
        'Could not save your account on this device. Please try again.',
      );
    }
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } on Exception {
      await _clearPersistedApplicantData(preferences);
      await _secureStorage.delete(key: _tokenKey);
      rethrow;
    }
  }

  Future<void> _activateApplicantSession(
    RequestorProfile requestor,
    ApplicantSession session,
  ) async {
    _sessionRevision++;
    _notificationPoller?.cancel();
    _notificationPoller = null;
    final preferences = await SharedPreferences.getInstance();
    final previousApplicantId = preferences.getString(_applicantIdKey)?.trim();
    _clearApplicantState();
    if (previousApplicantId != null &&
        previousApplicantId.isNotEmpty &&
        previousApplicantId != session.applicantId) {
      await _clearPersistedApplicantData(preferences);
    }
    await preferences.remove(_legacyApplicationsKey);
    await _saveSignedInProfile(requestor, session.token, session.applicantId);
    _loadApplications(preferences, session.applicantId);
    _applicantId = session.applicantId;
    _api.applicantToken = session.token;
    _serverSessionError = null;
    _requestor = requestor;
    _identityVerification = IdentityVerification.fromJson(session.user);
    _markConnected();
    _startNotificationPolling();
    notifyListeners();
  }

  Future<void> register(
    RequestorProfile requestor, {
    required String password,
  }) async {
    final session = await _api.registerApplicant(
      fullName: requestor.fullName,
      email: requestor.email,
      phone: requestor.contactNumber,
      address: [
        requestor.street,
        requestor.subdivision,
        requestor.barangay,
        requestor.district,
      ].where((part) => part.trim().isNotEmpty).join(', '),
      dateOfBirth: requestor.birthDate,
      password: password,
    );
    await _activateApplicantSession(requestor, session);
  }

  Future<bool> login(String email, String password) async {
    final session = await _api.loginApplicant(email: email, password: password);
    final requestor = RequestorProfile.fromApplicantAccount(session.user);
    await _activateApplicantSession(requestor, session);
    return true;
  }

  Future<bool> completeMfaLogin({
    required ApplicantMfaChallenge challenge,
    required String method,
    required String code,
  }) async {
    final session = await _api.verifyApplicantMfa(
      challenge: challenge,
      method: method,
      code: code,
    );
    final requestor = RequestorProfile.fromApplicantAccount(session.user);
    await _activateApplicantSession(requestor, session);
    return true;
  }

  Future<void> requestMfaSms(
    ApplicantMfaChallenge challenge, {
    bool stepUp = false,
  }) => _api.requestApplicantMfaSms(challenge, stepUp: stepUp);

  Future<ApplicantMfaStatus> getMfaStatus() =>
      _runAuthenticated(_api.getApplicantMfaStatus);

  Future<ApplicantMfaEnrollment> startMfaEnrollment(String currentPassword) =>
      _runAuthenticated(
        () => _api.startApplicantMfaEnrollment(currentPassword),
      );

  Future<ApplicantMfaRecoveryResult> confirmMfaEnrollment(String code) async {
    final result = await _runAuthenticated(
      () => _api.confirmApplicantMfaEnrollment(code),
    );
    if (result.token.isNotEmpty) await setApplicantToken(result.token);
    return result;
  }

  Future<ApplicantStepUpStart> startStepUp(String currentPassword) =>
      _runAuthenticated(() => _api.startApplicantStepUp(currentPassword));

  Future<String> completeStepUp({
    required ApplicantMfaChallenge challenge,
    required String method,
    required String code,
  }) => _runAuthenticated(
    () => _api.verifyApplicantStepUp(
      challenge: challenge,
      method: method,
      code: code,
    ),
  );

  Future<ApplicantMfaRecoveryResult> regenerateRecoveryCodes(
    String stepUpToken,
  ) async {
    final result = await _runAuthenticated(
      () => _api.regenerateApplicantRecoveryCodes(stepUpToken),
    );
    if (result.token.isNotEmpty) await setApplicantToken(result.token);
    return result;
  }

  Future<ApplicantMfaStatus> disableMfa(String stepUpToken) async {
    final result = await _runAuthenticated(
      () => _api.disableApplicantMfa(stepUpToken),
    );
    final token = _api.applicantToken;
    if (token != null && token.isNotEmpty) await setApplicantToken(token);
    return result;
  }

  Future<void> changePassword({
    required String stepUpToken,
    required String newPassword,
  }) async {
    final token = await _runAuthenticated(
      () => _api.changeApplicantPassword(
        stepUpToken: stepUpToken,
        newPassword: newPassword,
      ),
    );
    if (token.isNotEmpty) await setApplicantToken(token);
  }

  Future<void> updateApplicantContact({
    required String stepUpToken,
    required String email,
    required String phone,
  }) async {
    final session = await _runAuthenticated(
      () => _api.updateApplicantContact(
        stepUpToken: stepUpToken,
        email: email,
        phone: phone,
      ),
    );
    final updated = RequestorProfile.fromApplicantAccount(session.user);
    await _activateApplicantSession(updated, session);
  }

  Future<AssistanceApplication> submitApplication({
    required String clientSubmissionId,
    required PatientDetails patient,
    required String assistanceType,
    required String incomeSource,
    required String patientCircumstance,
    String additionalDetails = '',
    required List<Map<String, dynamic>> documents,
    required Map<String, dynamic> facilityEvidence,
  }) {
    final submissionKey = clientSubmissionId.trim();
    if (submissionKey.isEmpty) {
      return Future.error(
        const AidLinkApiException('A submission identifier is required.'),
      );
    }
    final active = _submissionsInFlight[submissionKey];
    if (active != null) return active;
    late final Future<AssistanceApplication> guarded;
    guarded =
        _submitApplicationOnce(
          clientSubmissionId: submissionKey,
          patient: patient,
          assistanceType: assistanceType,
          incomeSource: incomeSource,
          patientCircumstance: patientCircumstance,
          additionalDetails: additionalDetails,
          documents: documents,
          facilityEvidence: facilityEvidence,
        ).whenComplete(() {
          if (identical(_submissionsInFlight[submissionKey], guarded)) {
            _submissionsInFlight.remove(submissionKey);
          }
        });
    _submissionsInFlight[submissionKey] = guarded;
    return guarded;
  }

  Future<AssistanceApplication> _submitApplicationOnce({
    required String clientSubmissionId,
    required PatientDetails patient,
    required String assistanceType,
    required String incomeSource,
    required String patientCircumstance,
    required String additionalDetails,
    required List<Map<String, dynamic>> documents,
    required Map<String, dynamic> facilityEvidence,
  }) async {
    final requestor = _requestor;
    final applicantId = _applicantId;
    if (requestor == null || applicantId == null || !hasServerSession) {
      throw const AidLinkApiException(
        'Sign in before submitting an assistance request.',
      );
    }
    final revision = _sessionRevision;
    final submitted = await _runAuthenticated(
      () => _api.submitApplication(
        clientSubmissionId: clientSubmissionId,
        beneficiaryType: patient.beneficiaryType,
        fullName: patient.fullName,
        email: requestor.email,
        phone: requestor.contactNumber,
        address: [
          patient.street,
          patient.subdivision,
          patient.barangay,
          patient.district,
        ].where((part) => part.trim().isNotEmpty).join(', '),
        dateOfBirth: patient.birthDate,
        relationshipToPatient: patient.relationshipToPatient,
        sex: patient.sex,
        assistanceType: assistanceType,
        incomeSource: incomeSource,
        patientCircumstance: patientCircumstance,
        additionalDetails: additionalDetails,
        documents: documents,
        facilityEvidence: facilityEvidence,
      ),
    );
    if (revision != _sessionRevision || applicantId != _applicantId) {
      throw const AidLinkAuthenticationException();
    }
    final application = AssistanceApplication(
      referenceNumber: submitted.referenceNumber,
      patient: patient,
      assistanceType: assistanceType,
      submittedAt: submitted.submittedAt,
      documentNames: List.unmodifiable(
        documents.map((document) => document['name']!),
      ),
      incomeSource: incomeSource,
      patientCircumstance: patientCircumstance,
      additionalDetails: additionalDetails,
      status: submitted.status,
    );
    final uniqueApplications = _deduplicateCachedApplications([
      ..._applications,
      application,
    ]);
    _applications
      ..clear()
      ..addAll(uniqueApplications);
    notifyListeners();
    await _persist();
    return application;
  }

  Future<void> refreshStatuses() async {
    if (!hasServerSession) return;
    final revision = _sessionRevision;
    final applicantId = _applicantId;
    for (final application in List<AssistanceApplication>.of(_applications)) {
      try {
        final latest = await _runAuthenticated(
          () => _api.getApplicationStatus(
            referenceNumber: application.referenceNumber,
          ),
        );
        if (revision != _sessionRevision || applicantId != _applicantId) return;
        application.status = latest.status;
        application.remarks = latest.remarks;
        application.qrCode = latest.qrCode;
        application.qrCodeImageDataUrl = latest.qrCodeImageDataUrl;
        application.qrUsed = latest.qrUsed;
        application.guaranteeLetterUrl = latest.guaranteeLetterUrl;
      } on AidLinkApiException {
        // Keep the last known state when offline or when an old request cannot
        // be found. Other applications should still be refreshed.
      }
    }
    if (revision == _sessionRevision && applicantId == _applicantId) {
      await _persist();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _sessionRevision++;
    _notificationPoller?.cancel();
    _notificationPoller = null;
    _clearApplicantState();
    _isOnline = true;
    _connectionError = null;
    _lastSyncedAt = null;
    _serverSessionError = null;
    await _secureStorage.delete(key: _tokenKey);
    final preferences = await SharedPreferences.getInstance();
    await _clearPersistedApplicantData(preferences);
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationPoller?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
