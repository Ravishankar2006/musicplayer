import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:musicplayer/models/song.dart';
import 'package:musicplayer/services/database_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class MusicScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final DatabaseService _dbService;

  MusicScanner(this._dbService);

  String _generateFileHash(String path) {
    return md5.convert(utf8.encode(path)).toString();
  }

  Future<void> scanFolder() async {
    // 1. Request permissions
    if (Platform.isAndroid) {
      await [
        Permission.audio,
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();
    }

    // 2. Select Directory
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    final directory = Directory(selectedDirectory);
    final audioExtensions = ['.mp3', '.wav', '.m4a', '.flac', '.ogg'];
    List<File> audioFiles = [];

    try {
      final List<FileSystemEntity> entities = directory.listSync(recursive: true);
      for (var entity in entities) {
        if (entity is File) {
          String ext = p.extension(entity.path).toLowerCase();
          if (audioExtensions.contains(ext)) {
            audioFiles.add(entity);
          }
        }
      }
    } catch (e) {
      print("Error scanning directory: $e");
      return;
    }

    if (audioFiles.isEmpty) return;

    final existingSongs = await _dbService.getAllSongs();
    final existingPaths = existingSongs.map((e) => e.path).toSet();

    List<Song> songsToSave = [];
    final cacheDir = await getApplicationDocumentsDirectory();
    final artworkDir = Directory('${cacheDir.path}/artworks');
    if (!artworkDir.existsSync()) artworkDir.createSync(recursive: true);

    // Pre-query all device songs for matching IDs (Android only)
    List<SongModel> allDeviceSongs = [];
    if (Platform.isAndroid) {
      try {
        allDeviceSongs = await _audioQuery.querySongs(
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
      } catch (e) {}
    }

    for (var file in audioFiles) {
      // Even if it exists, we might want to update it if it's missing metadata or art
      // For now, skip duplicates as before
      if (existingPaths.contains(file.path)) continue;

      AudioMetadata? metadata;
      String? localArtPath;
      try {
        // Force re-reading with getImage true
        metadata = readMetadata(file, getImage: true);
        
        // Save embedded artwork using path hash to avoid collisions
        if (metadata.pictures.isNotEmpty) {
          final picture = metadata.pictures.first;
          final hash = _generateFileHash(file.path);
          final artFile = File('${artworkDir.path}/$hash.jpg');
          
          if (!artFile.existsSync()) {
            await artFile.writeAsBytes(picture.bytes);
          }
          localArtPath = artFile.path;
        }
      } catch (e) {
        print("Metadata error for ${file.path}: $e");
      }

      int? mediaStoreId;
      if (Platform.isAndroid) {
        // Use normalized paths for better matching
        final normalizedPath = file.path.replaceAll('//', '/');
        final matchedSong = allDeviceSongs.where((s) {
          final sData = s.data.replaceAll('//', '/');
          return sData == normalizedPath;
        }).firstOrNull;
        mediaStoreId = matchedSong?.id;
      }

      songsToSave.add(Song(
        path: file.path,
        title: metadata?.title ?? p.basenameWithoutExtension(file.path),
        artist: metadata?.artist ?? 'Unknown Artist',
        album: metadata?.album ?? 'Unknown Album',
        duration: metadata?.duration?.inMilliseconds,
        size: await file.length(),
        dateAdded: DateTime.now(),
        trackNumber: metadata?.trackNumber,
        discNumber: metadata?.discNumber,
        genre: (metadata != null && metadata.genres.isNotEmpty) ? metadata.genres.first : null,
        mediaStoreId: mediaStoreId,
        localArtworkPath: localArtPath,
      ));
    }

    if (songsToSave.isNotEmpty) {
      await _dbService.saveSongs(songsToSave);
      print("Saved ${songsToSave.length} new songs with artwork metadata.");
    }
  }
}
