# AidLink

AidLink is a Flutter application for submitting and tracking social assistance
requests in Davao.

## Run locally

```sh
flutter pub get
flutter run
```

The server address can be changed inside the app from **Server Settings** on
the sign-in or profile screen. It is saved on the phone, so changing Wi-Fi does
not require rebuilding the APK. Connect the phone and backend computer to the
same network, allow port 5000 through the computer firewall, run `ipconfig` to
find the computer's LAN IPv4 address, then enter a URL such as
`http://192.168.1.5:5000` in the app.

The default can still be overridden for a development build:

```sh
flutter run --dart-define=AIDLINK_API_URL=http://172.21.240.43:5000
```

You can also override the initial default when creating the phone APK:

```sh
flutter build apk --release --dart-define=AIDLINK_API_URL=http://172.21.240.43:5000
```

For web development, use `flutter run -d chrome`.

## Download the Android app

Download [AidLink for Android](release/AidLink-release.apk), copy the APK to an
Android phone, and open it to install. Android may ask you to allow installs
from the browser or file manager used to open the file.

To create an updated APK after changing the app, run:

```sh
flutter build apk --release
```

Then copy `build/app/outputs/flutter-apk/app-release.apk` to
`release/AidLink-release.apk`.

If Windows reports a file lock on `generate_cxx_metadata_*_timing.txt`, use
this PowerShell build command with the required Android NDK already installed:

```powershell
$env:AIDLINK_SKIP_NDK_BOOTSTRAP = '1'
try {
    flutter build apk --release
} finally {
    Remove-Item Env:AIDLINK_SKIP_NDK_BOOTSTRAP
}
```

This skips only Flutter's empty NDK download bootstrap. The build checks that
the required NDK is installed and refuses to skip a real app CMake project.

## Applicant feature dependencies

Applicant registration uses `POST /api/applicant/auth/register`, and sign-in
uses `POST /api/applicant/auth/login`. Both require a password and return a
Bearer token that is saved in encrypted device storage. Registration completion
is shown only after the server creates the account and the local session is
saved.

A `401` clears rejected server credentials and online account data while
preserving the saved profile. The dashboard then offers a sign-in action so the
applicant can renew access. Background refresh failures never silently sign the
applicant out.
Firebase Cloud Messaging is
not enabled until an FCM registration flow and backend delivery service are
configured.

For an Android emulator use `http://10.0.2.2:5000`. On a physical phone enter
the computer's LAN URL, such as `http://192.168.1.5:5000`, in Server Settings.
API-returned file URLs are resolved against that configured server and are not
rewritten to localhost.

## Approval proof API contract

The mobile app reads approval proof from the bearer-authenticated
`GET /api/applicant/requests/:requestId` endpoint. The backend must derive the
applicant from the verified token and must not accept an applicant ID or email
as a history filter. For an approved request, it should return:

```json
{
  "status": "approved",
  "remarks": "Approved by CMO",
  "qrCode": "an-opaque-server-generated-token",
  "guaranteeLetterUrl": "/uploads/guarantee-letters/REQ-123.pdf"
}
```

The admin approval action must upload the guarantee letter and provide the QR
image fields consumed by the applicant request-details API. Screenshot
blocking, rotating codes, and single-use QR security are outside this mobile
app task.

Guarantee letters should be uploaded and served as valid PDF files with the
`application/pdf` content type. This allows the mobile app to send the letter
directly to the Android, iOS, desktop, or web print dialog.
