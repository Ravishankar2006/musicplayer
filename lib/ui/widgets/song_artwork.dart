import 'dart:io';
import 'package:flutter/material.dart';

class SongArtwork extends StatelessWidget {
  final int? mediaStoreId;
  final String? localArtworkPath;
  final String? audioPath;
  final double size;
  final double borderRadius;

  const SongArtwork({
    super.key,
    this.mediaStoreId,
    this.localArtworkPath,
    this.audioPath,
    this.size = 200,
    this.borderRadius = 16,
  });

  bool _hasValidArtworkPath() {
    if (localArtworkPath == null || localArtworkPath!.trim().isEmpty) {
      return false;
    }
    return File(localArtworkPath!).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final hasArtwork = _hasValidArtworkPath();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: Colors.white10,
        child: hasArtwork
            ? Image.file(
          File(localArtworkPath!),
          fit: BoxFit.cover,
          width: size,
          height: size,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _buildFallbackArtwork(),
        )
            : _buildFallbackArtwork(),
      ),
    );
  }

  Widget _buildFallbackArtwork() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F1F2E),
            Color(0xFF101014),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 90,
          color: Colors.white24,
        ),
      ),
    );
  }
}