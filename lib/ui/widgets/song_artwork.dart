import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongArtwork extends StatelessWidget {
  final int? mediaStoreId;
  final String? localArtworkPath;
  final double size;
  final double borderRadius;
  final bool showShadow;

  const SongArtwork({
    super.key,
    this.mediaStoreId,
    this.localArtworkPath,
    this.size = 50,
    this.borderRadius = 12,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget? artwork;

    if (localArtworkPath != null) {
      final file = File(localArtworkPath!);
      if (file.existsSync()) {
        artwork = Image.file(
          file,
          fit: BoxFit.cover,
          width: size,
          height: size,
          cacheWidth: (size * 2).toInt(),
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    }

    if (artwork == null && Platform.isAndroid && mediaStoreId != null && mediaStoreId! > 0) {
      artwork = QueryArtworkWidget(
        id: mediaStoreId!,
        type: ArtworkType.AUDIO,
        artworkFit: BoxFit.cover,
        artworkWidth: size,
        artworkHeight: size,
        nullArtworkWidget: _buildPlaceholder(),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: artwork ?? _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1B2027),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: size * 0.5,
          color: const Color(0xFF98A2B3).withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
