import 'dart:convert';
import 'dart:io';

import 'package:aidlink_app/data/services/aidlink_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'password login surfaces a typed MFA challenge without a session',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((request) async {
        expect(request.uri.path, '/api/applicant/auth/login');
        final payload =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        expect(payload['email'], 'applicant@example.com');
        request.response
          ..statusCode = HttpStatus.accepted
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'mfaRequired': true,
              'challengeToken': 'short-lived-challenge',
              'methods': ['totp', 'sms', 'recovery_code'],
              'maskedPhone': '********4567',
            }),
          );
        await request.response.close();
      });

      final api = AidLinkApi(
        baseUrl: 'http://${server.address.host}:${server.port}',
      );
      try {
        await api.loginApplicant(
          email: 'applicant@example.com',
          password: 'strong-pass',
        );
        fail('MFA-enabled login must not return an applicant session yet.');
      } on ApplicantMfaChallengeException catch (error) {
        expect(error.challenge.challengeToken, 'short-lived-challenge');
        expect(error.challenge.methods, ['totp', 'sms', 'recovery_code']);
        expect(error.challenge.maskedPhone, '********4567');
      }
    },
  );

  test('MFA status exposes only safe enrollment metadata', () {
    final status = ApplicantMfaStatus.fromJson({
      'enabled': true,
      'primaryMethod': 'totp',
      'smsFallbackAvailable': true,
      'recoveryCodesRemaining': 7,
      'enrolledAt': '2026-09-14T10:00:00.000Z',
      'totpSecretEncrypted': 'must-not-be-modeled',
      'recoveryCodeHashes': ['must-not-be-modeled'],
    });

    expect(status.enabled, true);
    expect(status.smsFallbackAvailable, true);
    expect(status.recoveryCodesRemaining, 7);
    expect(status.enrolledAt, DateTime.utc(2026, 9, 14, 10));
  });
}
