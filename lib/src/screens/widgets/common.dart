/// Small pieces every screen uses: the poster, the error-with-retry, and money formatting.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api.dart';
import '../../theme.dart';

final _kes = NumberFormat.decimalPattern('en_KE');
String kes(num amount) => 'KES ${_kes.format(amount)}';

/// A studio poster fetched through `/cinema/poster` (it is a POST, so Image.network cannot do it).
class Poster extends StatefulWidget {
  const Poster({super.key, required this.api, required this.image, this.title = ''});
  final EdenApi api;
  final String? image;
  final String title;

  @override
  State<Poster> createState() => _PosterState();
}

class _PosterState extends State<Poster> {
  Future<Uint8List?>? _bytes;

  @override
  void initState() {
    super.initState();
    if (widget.image != null) _bytes = widget.api.poster(widget.image!);
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ColoredBox(
          color: EdenColors.earth800,
          child: FutureBuilder<Uint8List?>(
            future: _bytes,
            builder: (context, snap) {
              final bytes = snap.data;
              if (bytes != null) return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: fraunces(14, color: EdenColors.muted),
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: EdenColors.muted)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
