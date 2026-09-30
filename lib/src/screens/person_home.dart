/// A person's phone dashboard: who they are to Eden, their counts, and the studios they have credits with.
/// Profile edits and mini-series uploads stay on the web dashboard for now.
library;

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../session.dart';
import '../theme.dart';
import 'widgets/common.dart';

class PersonHome extends StatefulWidget {
  const PersonHome({super.key, required this.api, required this.session});
  final EdenApi api;
  final SessionController session;

  @override
  State<PersonHome> createState() => _PersonHomeState();
}

class _PersonHomeState extends State<PersonHome> {
  late Future<(PersonProfile, List<StudioCard>)> _data = _load();

  Future<(PersonProfile, List<StudioCard>)> _load() async =>
      (await widget.api.personProfile(), await widget.api.personStudios());

  Future<void> _reload() async {
    setState(() => _data = _load());
    await _data.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Cast & crew'),
          actions: [
            IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: widget.session.signOut),
          ],
        ),
        body: FutureBuilder(
          future: _data,
          builder: (context, snap) {
            if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: _reload);
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            final (p, studios) = snap.data!;
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(p.name.isEmpty ? 'Welcome' : p.name, style: fraunces(30)),
                  const SizedBox(height: 6),
                  _Verified(label: p.email, ok: p.emailVerified),
                  if (p.telephone.isNotEmpty) _Verified(label: p.telephone, ok: p.telephoneVerified),
                  const SizedBox(height: 18),
                  Row(children: [
                    _Stat('Credits', p.credits),
                    const SizedBox(width: 10),
                    _Stat('Studios', p.studios),
                    const SizedBox(width: 10),
                    _Stat('Followers', p.followers),
                  ]),
                  const SizedBox(height: 22),
                  Text('Your studios', style: fraunces(20)),
                  const SizedBox(height: 6),
                  if (studios.isEmpty)
                    const Text('No credits with a studio yet.', style: TextStyle(color: EdenColors.muted))
                  else
                    for (final s in studios)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.theaters, color: EdenColors.clay300),
                        title: Text(s.name),
                      ),
                ],
              ),
            );
          },
        ),
      );
}

class _Verified extends StatelessWidget {
  const _Verified({required this.label, required this.ok});
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Icon(ok ? Icons.verified : Icons.error_outline,
              size: 16, color: ok ? EdenColors.good : EdenColors.muted),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(color: EdenColors.sand200))),
        ]),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              Text('$value', style: fraunces(24)),
              Text(label, style: const TextStyle(color: EdenColors.muted, fontSize: 12)),
            ]),
          ),
        ),
      );
}
