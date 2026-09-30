/// Now Screening — every studio-published movie, twenty at a time, loading the next page as the
/// viewer nears the bottom. Same `/cinema` the web app's /cinema route reads.
library;

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import 'film.dart';
import 'widgets/common.dart';

class CinemaScreen extends StatefulWidget {
  const CinemaScreen({super.key, required this.api});
  final EdenApi api;

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen> {
  final _films = <Film>[];
  int _page = 0;
  int _pages = 1;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _more();
  }

  Future<void> _refresh() async {
    setState(() {
      _films.clear();
      _page = 0;
      _pages = 1;
    });
    await _more();
  }

  Future<void> _more() async {
    if (_loading || _page >= _pages) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = await widget.api.cinema(page: _page + 1);
      setState(() {
        _films.addAll(next.films);
        _page = next.page;
        _pages = next.pages;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 600) _more();
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(children: [
                      Image.asset('assets/eden-wordmark.png', height: 28),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Text('Now Screening', style: fraunces(28)),
                  ),
                ),
                if (_films.isEmpty && _error != null)
                  SliverFillRemaining(child: ErrorRetry(message: _error!, onRetry: _refresh))
                else if (_films.isEmpty && !_loading)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text('Nothing screening yet.', style: TextStyle(color: EdenColors.muted)),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.52,
                      ),
                      itemCount: _films.length,
                      itemBuilder: (context, i) => _FilmTile(api: widget.api, film: _films[i]),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: _loading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _FilmTile extends StatelessWidget {
  const _FilmTile({required this.api, required this.film});
  final EdenApi api;
  final Film film;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FilmScreen(api: api, film: film)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Poster(api: api, image: film.poster, title: film.title)),
            const SizedBox(height: 8),
            Text(film.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: fraunces(15)),
            Text(
              film.studio.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: EdenColors.clay300, fontSize: 12),
            ),
            if (film.meta.isNotEmpty)
              Text(
                film.meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: EdenColors.muted, fontSize: 12),
              ),
          ],
        ),
      );
}
