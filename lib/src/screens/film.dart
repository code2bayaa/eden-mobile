/// One film: poster, studio, genres and synopsis. Playback is not wired yet — the API has no public
/// stream route for viewers.
library;

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import 'widgets/common.dart';

class FilmScreen extends StatelessWidget {
  const FilmScreen({super.key, required this.api, required this.film});
  final EdenApi api;
  final Film film;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Center(
              child: SizedBox(
                width: 220,
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Poster(api: api, image: film.poster, title: film.title),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(film.title, style: fraunces(28)),
            const SizedBox(height: 4),
            Text(film.studio.name, style: const TextStyle(color: EdenColors.clay300)),
            if (film.meta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(film.meta, style: const TextStyle(color: EdenColors.muted)),
            ],
            if (film.genres.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in film.genres)
                    Chip(
                      label: Text(g),
                      backgroundColor: EdenColors.earth800,
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
            if (film.overview.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(film.overview, style: const TextStyle(height: 1.5, color: EdenColors.sand200)),
            ],
          ],
        ),
      );
}
