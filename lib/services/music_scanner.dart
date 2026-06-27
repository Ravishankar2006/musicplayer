import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:musicplayer/models/song.dart';
import 'package:musicplayer/services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicScanner {
  final DatabaseService _dbService;

  MusicScanner(this._dbService);

  String _generateFileHash(String path) {
    return md5.convert(utf8.encode(path)).toString();
  }

  Future<void> scanFolder() async {
    if (Platform.isAndroid) {
      await [
        Permission.audio,
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();
    }

    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    final directory = Directory(selectedDirectory);
    const audioExtensions = ['.mp3', '.wav', '.m4a', '.flac', '.ogg'];
    final List<File> audioFiles = [];

    try {
      final entities = directory.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (audioExtensions.contains(ext)) {
            audioFiles.add(entity);
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory: $e');
      return;
    }

    if (audioFiles.isEmpty) return;

    final songsToSave = <Song>[];

    final cacheDir = await getApplicationDocumentsDirectory();
    final artworkDir = Directory('${cacheDir.path}/artworks');
    if (!artworkDir.existsSync()) {
      artworkDir.createSync(recursive: true);
    }

    for (final file in audioFiles) {
      Metadata? metadata;
      String? localArtPath;

      try {
        metadata = await MetadataRetriever.fromFile(file);
        
        final albumArt = metadata.albumArt;
        if (albumArt != null && albumArt.isNotEmpty) {
          final hash = _generateFileHash(file.path);
          final artFile = File('${artworkDir.path}/$hash.jpg');

          if (!artFile.existsSync()) {
            await artFile.writeAsBytes(albumArt);
          }

          localArtPath = artFile.path;
        }
      } catch (e) {
        debugPrint('Metadata error for ${file.path}: $e');
      }

      songsToSave.add(
        Song(
          path: file.path,
          title: (metadata?.trackName != null && metadata!.trackName!.trim().isNotEmpty)
              ? metadata.trackName!
              : p.basenameWithoutExtension(file.path),
          artist: (metadata?.trackArtistNames != null && metadata!.trackArtistNames!.isNotEmpty)
              ? metadata.trackArtistNames!.join(', ')
              : 'Unknown Artist',
          album: (metadata?.albumName != null && metadata!.albumName!.trim().isNotEmpty)
              ? metadata.albumName!
              : 'Unknown Album',
          duration: metadata?.trackDuration,
          size: await file.length(),
          dateAdded: DateTime.now(),
          trackNumber: metadata?.trackNumber,
          localArtworkPath: localArtPath,
        ),
      );
    }

    if (songsToSave.isNotEmpty) {
      await _dbService.saveSongs(songsToSave);
      debugPrint('Saved ${songsToSave.length} songs.');
    }
  }
}
