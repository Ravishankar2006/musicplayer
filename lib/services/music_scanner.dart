import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:musicplayer/models/song.dart';
import 'package:musicplayer/services/database_service.dart';

class MusicScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final DatabaseService _dbService;

  MusicScanner(this._dbService);

  Future<void> scanMusic() async {
    // 1. Request permissions (should be handled in UI, but double check here)
    bool hasPermission = await _audioQuery.checkAndRequest();
    if (!hasPermission) return;

    // 2. Query songs from MediaStore
    List<SongModel> deviceSongs = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    // 3. Process and convert to our Song model
    List<Song> songsToSave = [];
    
    // Get existing paths to avoid duplicates or re-scanning everything if not needed
    // For MVP, we'll do a simple sync: check if path exists in DB
    final existingSongs = await _dbService.getAllSongs();
    final existingPaths = existingSongs.map((e) => e.path).toSet();

    for (var deviceSong in deviceSongs) {
      if (existingPaths.contains(deviceSong.data)) continue;

      // Extract more detailed metadata if available using audio_metadata_reader
      // This is useful for high-end players
      var metadata;
      try {
        final file = File(deviceSong.data);
        if (await file.exists()) {
          metadata = readMetadata(file);
        }
      } catch (e) {
        // Fallback to deviceSong info if metadata reader fails
      }

      songsToSave.add(Song(
        path: deviceSong.data,
        title: metadata?.title ?? deviceSong.title,
        artist: metadata?.artist ?? deviceSong.artist,
        album: metadata?.album ?? deviceSong.album,
        duration: deviceSong.duration,
        size: deviceSong.size,
        dateAdded: DateTime.fromMillisecondsSinceEpoch((deviceSong.dateAdded ?? 0) * 1000),
        trackNumber: metadata?.trackNumber,
        discNumber: metadata?.discNumber,
        genre: metadata?.genres?.isNotEmpty == true ? metadata.genres.first : null,
      ));
    }

    if (songsToSave.isNotEmpty) {
      await _dbService.saveSongs(songsToSave);
    }
  }
}
