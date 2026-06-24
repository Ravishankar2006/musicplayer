import 'dart:convert';
import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
      Tag? tag;
      String? localArtPath;

      try {
        tag = await AudioTags.read(file.path);
        debugPrint('Scanning: ${file.path}');
        debugPrint('Pictures count: ${tag?.pictures?.length ?? 0}');

        final pictures = tag?.pictures;
        if (pictures != null && pictures.isNotEmpty) {
          final bytes = pictures.first.bytes;
          if (bytes.isNotEmpty) {
            final hash = _generateFileHash(file.path);
            final artFile = File('${artworkDir.path}/$hash.jpg');

            if (!artFile.existsSync()) {
              await artFile.writeAsBytes(bytes);
              debugPrint('Saved artwork to: ${artFile.path}');
            }

            localArtPath = artFile.path;
          }
        } else {
          debugPrint('No embedded artwork for: ${file.path}');
        }
      } catch (e) {
        debugPrint('Metadata error for ${file.path}: $e');
      }

      songsToSave.add(
        Song(
          path: file.path,
          title: (tag?.title != null && tag!.title!.trim().isNotEmpty)
              ? tag.title!
              : p.basenameWithoutExtension(file.path),
          artist: (tag?.trackArtist != null && tag!.trackArtist!.trim().isNotEmpty)
              ? tag.trackArtist!
              : 'Unknown Artist',
          album: (tag?.album != null && tag!.album!.trim().isNotEmpty)
              ? tag.album!
              : 'Unknown Album',
          duration: tag?.duration,
          size: await file.length(),
          dateAdded: DateTime.now(),
          trackNumber: tag?.trackNumber,
          discNumber: tag?.discNumber,
          genre: tag?.genre,
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