import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/models/song.dart';
import 'package:musicplayer/services/audio_handler.dart';
import 'package:musicplayer/services/database_service.dart';
import 'package:musicplayer/services/music_scanner.dart';

// Service Providers
final dbServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final musicScannerProvider = Provider((ref) {
  final dbService = ref.watch(dbServiceProvider);
  return MusicScanner(dbService);
});

final queueProvider = StreamProvider<List<MediaItem>>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.queue;
});

// Audio Handler Provider (initialized in main)
late MyAudioHandler globalAudioHandler;
final audioHandlerProvider = Provider((ref) => globalAudioHandler);

// Data Providers
final songsProvider = FutureProvider<List<Song>>((ref) async {
  final dbService = ref.watch(dbServiceProvider);
  return dbService.getAllSongs();
});

// Playback State Providers
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState.stream;
});

final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.mediaItem.stream;
});
