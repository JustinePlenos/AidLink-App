import 'dart:convert';
import 'dart:typed_data';

import 'package:aidlink_app/data/services/aidlink_api.dart';
import 'package:aidlink_app/presentation/history/screens/application_history_screen.dart';
import 'package:aidlink_app/presentation/shared/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ImageApi extends AidLinkApi {
  String? downloadedUrl;

  @override
  Future<Uint8List> downloadFile(String value) async {
    downloadedUrl = value;
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
  }
}

void main() {
  testWidgets('labels an opened Medicine Assistance request as historical', (
    tester,
  ) async {
    final request = ApplicantRequest(
      id: 'legacy-medicine-request',
      assistanceType: 'Medicine Assistance',
      dateSubmitted: DateTime(2025),
      status: 'pending',
      remarks: '',
    );

    await tester.pumpWidget(
      MaterialApp(home: ApplicantRequestDetailsScreen(request: request)),
    );

    expect(find.text('Medicine Assistance'), findsOneWidget);
    expect(
      find.textContaining('no longer available for new applications'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows only requested replacements and blocks incomplete correction submission',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final request = ApplicantRequest(
        id: 'request-correction',
        assistanceType: 'Hospital Assistance',
        dateSubmitted: DateTime(2026, 9, 13),
        status: 'correction_requested',
        remarks: '',
        supportingDocuments: const [
          SupportingDocument(
            id: 'document-id',
            name: 'valid-id.jpg',
            url: '/uploads/valid-id.jpg',
            type: 'valid_id',
          ),
          SupportingDocument(
            id: 'document-social',
            name: 'social-case-study.pdf',
            url: '/uploads/social-case-study.pdf',
            type: 'social_case_study',
          ),
        ],
        correctionRequest: CorrectionRequest(
          id: 'correction-1',
          remark: 'Retake the ID with all four edges visible.',
          requestedAt: DateTime(2026, 9, 13, 8),
          requestedBy: 'Case Worker One',
          documents: const [
            CorrectionDocumentRequest(
              documentId: 'document-id',
              name: 'valid-id.jpg',
              label: 'Valid ID',
              documentType: 'valid_id',
            ),
          ],
          replacedDocumentIds: const {},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: ApplicantRequestDetailsScreen(request: request)),
      );

      expect(find.text('Document corrections requested'), findsOneWidget);
      expect(
        find.text('Retake the ID with all four edges visible.'),
        findsWidgets,
      );
      expect(
        find.textContaining('Requested by Case Worker One on'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Replace'), findsOneWidget);
      final submit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit corrections'),
      );
      expect(submit.onPressed, isNull);
    },
  );

  testWidgets('opens an approved image in the in-app viewer', (tester) async {
    final api = _ImageApi();
    final request = ApplicantRequest(
      id: 'request-1',
      assistanceType: 'Medical Assistance',
      dateSubmitted: DateTime(2026),
      status: 'ready_for_claiming',
      remarks: '',
      guaranteeLetter: const GuaranteeLetter(
        name: 'Guarantee Letter',
        url: 'http://localhost:5000/uploads/approval.png',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(api: api),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ApprovalVerification(request: request),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('View guarantee letter'));
    await tester.pumpAndSettle();

    expect(api.downloadedUrl, request.guaranteeLetter!.url);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Guarantee Letter'), findsOneWidget);
  });
}
