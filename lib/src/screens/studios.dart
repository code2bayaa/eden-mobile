/// The studios a viewer can go and watch — only those that have published something (`/cinema/studios`).
library;

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import 'widgets/common.dart';

class StudiosScreen extends StatefulWidget {
  const StudiosScreen({super.key, required this.api});
  final EdenApi api;

  @override
  State<StudiosScreen> createState() => _StudiosScreenState();
}

class _StudiosScreenState extends State<StudiosScreen> {
  late Future<List<StudioCard>> _studios = widget.api.cinemaStudios();

  Future<void> _reload() async {
    setState(() => _studios = widget.api.cinemaStudios());
    await _studios.catchError((_) => <StudioCard>[]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Studios')),
        body: FutureBuilder<List<StudioCard>>(
          future: _studios,
          builder: (context, snap) {
            if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: _reload);
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            final studios = snap.data!;
            if (studios.isEmpty) {
              return const Center(child: Text('No studios yet.', style: TextStyle(color: EdenColors.muted)));
            }
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: studios.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final s = studios[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: EdenColors.clay500,
                        child: Text(s.name.isEmpty ? '?' : s.name[0].toUpperCase(),
                            style: fraunces(18)),
                      ),
                      title: Text(s.name, style: fraunces(17)),
                      subtitle: Text('${s.titles ?? 0} titles',
                          style: const TextStyle(color: EdenColors.muted)),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
}
