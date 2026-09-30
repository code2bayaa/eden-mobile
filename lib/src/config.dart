/// Where this build points. Both values are `--dart-define`s, read from the git-ignored `.env` beside
/// pubspec.yaml:
///
///   flutter run --dart-define-from-file=.env
///   flutter build apk --release --dart-define=EDEN_API=https://entry.uko-app.co.ke --dart-define=EDEN_MOBILE_KEY=...
///
/// `EDEN_MOBILE_KEY` must equal `mobile_api_key` in eden/back-end/.env — the backend's mobile entry is
/// closed without it.
library;

abstract final class Config {
  /// Origin only, no trailing slash. The Android emulator reaches the dev machine as 10.0.2.2; a real
  /// phone needs the laptop's LAN address, and the iOS simulator can use 127.0.0.1.
  static const apiBase = String.fromEnvironment('EDEN_API', defaultValue: 'http://10.0.2.2:5005');

  static const mobileKey = String.fromEnvironment('EDEN_MOBILE_KEY');

  /// The web app, for the jobs the phone does not do (uploads, casting, cast & crew editing).
  static const webUrl = String.fromEnvironment('EDEN_WEB', defaultValue: 'https://eden.uko-app.co.ke');

  static const sessionKey = 'uko_eden_session';
}
