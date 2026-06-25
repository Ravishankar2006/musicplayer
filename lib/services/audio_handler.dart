import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicplayer/models/song.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlaybackEvent>? _playbackEventSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<int?>? _currentIndexSub;

  MyAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenToPositionChanges();
    _listenToDurationChanges();
    _listenToCurrentIndexChanges();
  }

  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;

  Future<void> cycleRepeatMode() async {
    switch (_repeatMode) {
      case AudioServiceRepeatMode.none:
        _repeatMode = AudioServiceRepeatMode.all;
        await _player.setLoopMode(LoopMode.all);
        break;
      case AudioServiceRepeatMode.all:
        _repeatMode = AudioServiceRepeatMode.one;
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.one:
        _repeatMode = AudioServiceRepeatMode.none;
        await _player.setLoopMode(LoopMode.off);
        break;
      default:
        _repeatMode = AudioServiceRepeatMode.none;
        await _player.setLoopMode(LoopMode.off);
    }

    playbackState.add(
      playbackState.value.copyWith(
        repeatMode: _repeatMode,
      ),
    );
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _playbackEventSub = _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
          repeatMode: _repeatMode,
        ),
      );
    });
  }

  void _listenToPositionChanges() {
    _positionSub = _player.positionStream.listen((position) {
      playbackState.add(
        playbackState.value.copyWith(
          updatePosition: position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          playing: _player.playing,
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
        ),
      );
    });
  }

  void _listenToDurationChanges() {
    _durationSub = _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null && current.duration != duration) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  void _listenToCurrentIndexChanges() {
    _currentIndexSub = _player.currentIndexStream.listen((index) {
      final currentQueue = queue.value;
      if (index != null && index >= 0 && index < currentQueue.length) {
        mediaItem.add(currentQueue[index]);
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_repeatMode == AudioServiceRepeatMode.all && queue.value.isNotEmpty) {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final currentPosition = _player.position;

    if (currentPosition > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> playSong(Song song) async {
    await playQueueAtIndex([song], 0);
  }

  Future<void> setQueue(List<Song> songs) async {
    final mediaItems = songs
        .map(
          (song) => MediaItem(
        id: song.path,
        album: song.album ?? 'Unknown Album',
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        duration: song.duration != null
            ? Duration(milliseconds: song.duration!)
            : Duration.zero,
        extras: {
          'mediaStoreId': song.mediaStoreId,
          'localArtworkPath': song.localArtworkPath,
        },
      ),
    )
        .toList();

    queue.add(mediaItems);

    final playlist = ConcatenatingAudioSource(
      children: mediaItems
          .map(
            (item) => AudioSource.file(
          item.id,
          tag: item,
        ),
      )
          .toList(),
    );

    await _player.setAudioSource(playlist);
    await _player.setLoopMode(
      _repeatMode == AudioServiceRepeatMode.one
          ? LoopMode.one
          : _repeatMode == AudioServiceRepeatMode.all
          ? LoopMode.all
          : LoopMode.off,
    );
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  Future<void> disposePlayer() async {
    await _playbackEventSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _currentIndexSub?.cancel();
    await _player.dispose();
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'cycleRepeatMode':
        await cycleRepeatMode();
        return null;
      default:
        return super.customAction(name, extras);
    }
  }

  Future<void> playQueueAtIndex(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return;
    if (startIndex < 0 || startIndex >= songs.length) return;

    final mediaItems = songs.map((song) {
      return MediaItem(
        id: song.path,
        album: song.album ?? 'Unknown Album',
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        duration: song.duration != null
            ? Duration(milliseconds: song.duration!)
            : Duration.zero,
        extras: {
          'mediaStoreId': song.mediaStoreId,
          'localArtworkPath': song.localArtworkPath,
        },
      );
    }).toList();

    queue.add(mediaItems);

    final playlist = ConcatenatingAudioSource(
      children: mediaItems.map((item) {
        return AudioSource.file(
          item.id,
          tag: item,
        );
      }).toList(),
    );

    await _player.setAudioSource(playlist);
    await _player.setLoopMode(
      _repeatMode == AudioServiceRepeatMode.one
          ? LoopMode.one
          : _repeatMode == AudioServiceRepeatMode.all
          ? LoopMode.all
          : LoopMode.off,
    );

    await _player.seek(Duration.zero, index: startIndex);
    mediaItem.add(mediaItems[startIndex]);
    await _player.play();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
  }
}