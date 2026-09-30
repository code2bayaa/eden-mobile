/// One API client and one session controller for the life of the process, handed down explicitly.
/// Three tabs: the open cinema, the studios rail, and an account tab that is a sign-in until someone
/// signs in, then the studio's or the person's dashboard.
library;

import 'package:flutter/material.dart';

import 'api.dart';
import 'models.dart';
import 'screens/cinema.dart';
import 'screens/person_home.dart';
import 'screens/sign_in.dart';
import 'screens/studio_home.dart';
import 'screens/studios.dart';
import 'session.dart';
import 'theme.dart';

class EdenApp extends StatefulWidget {
  const EdenApp({super.key, this.api});

  /// Injected by tests; built here otherwise.
  final EdenApi? api;

  @override
  State<EdenApp> createState() => _EdenAppState();
}

class _EdenAppState extends State<EdenApp> {
  late final EdenApi _api;
  late final SessionController _session;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? EdenApi(onUnauthorized: () => _session.forget());
    _session = SessionController(api: _api)..restore();
  }

  @override
  void dispose() {
    _api.close();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Eden',
        theme: edenTheme(),
        debugShowCheckedModeBanner: false,
        home: AnimatedBuilder(
          animation: _session,
          builder: (context, _) {
            if (_session.restoring) return const _Splash();
            final account = switch (_session.kind) {
              SessionKind.studio => StudioHome(api: _api, session: _session),
              SessionKind.person => PersonHome(api: _api, session: _session),
              null => SignInScreen(api: _api, session: _session),
            };
            return Scaffold(
              body: IndexedStack(
                index: _tab,
                children: [CinemaScreen(api: _api), StudiosScreen(api: _api), account],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.movie_outlined), selectedIcon: Icon(Icons.movie), label: 'Cinema'),
                  NavigationDestination(icon: Icon(Icons.theaters_outlined), selectedIcon: Icon(Icons.theaters), label: 'Studios'),
                  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
                ],
              ),
            );
          },
        ),
      );
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Image.asset('assets/eden-logo-mark.png', width: 96)),
      );
}
