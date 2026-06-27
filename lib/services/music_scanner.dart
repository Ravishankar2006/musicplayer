import 'dart:convert';
import 'dart:io';

import 'package:audio_info/audio_info.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:musicplayer/models/song.dart';
import 'package:musicplayer/services/database_service.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicScanner {
  final DatabaseService _dbService;
  final oaq.OnAudioQuery _audioQuery = oaq.OnAudioQuery();

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

    // Pre-query all device songs for matching IDs (Android only)
    List<oaq.SongModel> allDeviceSongs = [];
    if (Platform.isAndroid) {
      try {
        allDeviceSongs = await _audioQuery.querySongs(
          uriType: oaq.UriType.EXTERNAL,
          ignoreCase: true,
        );
      } catch (e) {}
    }

    for (final file in audioFiles) {
      AudioData? info;
      String? localArtPath;

      try {
        info = await AudioInfo.getAudioInfo(file.path);
        
        if (info != null && info.hasArtwork == true) {
          final albumArt = await AudioInfo.getAudioImage(file.path);
          if (albumArt != null && albumArt.isNotEmpty) {
            final hash = _generateFileHash(file.path);
            final artFile = File('${artworkDir.path}/$hash.jpg');

            if (!artFile.existsSync()) {
              await artFile.writeAsBytes(albumArt);
            }

            localArtPath = artFile.path;
          }
        }
      } catch (e) {
        debugPrint('Metadata error for ${file.path}: $e');
      }

      int? mediaStoreId;
      if (Platform.isAndroid) {
        final normalizedPath = file.path.replaceAll('//', '/');
        final matchedSong = allDeviceSongs.where((s) {
          final sData = s.data.replaceAll('//', '/');
          return sData == normalizedPath;
        }).firstOrNull;
        mediaStoreId = matchedSong?.id;
      }

      final title = (info?.title != null && info!.title.trim().isNotEmpty)
          ? info.title
          : p.basenameWithoutExtension(file.path);
      
      final artist = (info?.artist != null && info!.artist.trim().isNotEmpty)
          ? info.artist
          : 'Unknown Artist';
          
      final album = (info?.album != null && info!.album.trim().isNotEmpty)
          ? info.album
          : 'Unknown Album';

      songsToSave.add(
        Song(
          path: file.path,
          title: title,
          artist: artist,
          album: album,
          duration: info?.durationMs,
          size: await file.length(),
          dateAdded: DateTime.now(),
          trackNumber: info?.trackNumber != null ? int.tryParse(info!.trackNumber.toString()) : null,
          mediaStoreId: mediaStoreId,
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
