import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongArtwork extends StatelessWidget {
  final int? mediaStoreId;
  final String? localArtworkPath;
  final double size;
  final double borderRadius;

  const SongArtwork({
    super.key,
    this.mediaStoreId,
    this.localArtworkPath,
    this.size = 50,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    Widget? artwork;

    // 1. Try local extracted artwork (Works on Linux and as fallback on Android)
    if (localArtworkPath != null) {
      final file = File(localArtworkPath!);
      if (file.existsSync()) {
        artwork = Image.file(
          file,
          fit: BoxFit.cover,
          width: size,
          height: size,
          cacheWidth: (size * 2).toInt(), // Optimization
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    }

    // 2. Try MediaStore artwork (Android only)
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: Colors.white10,
        child: artwork ?? _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.music_note,
        size: size * 0.5,
        color: Colors.white24,
      ),
    );
  }
}
