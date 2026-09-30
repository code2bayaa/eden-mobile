/// Eden — the Garden of New African Cinema, on the phone.
///
/// Points at the Eden API (`eden/back-end`, port 5005) through its mobile entry. Run with
/// `flutter run --dart-define-from-file=.env`; see `src/config.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const EdenApp());
}
