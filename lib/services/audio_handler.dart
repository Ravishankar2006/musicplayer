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
  AudioServiceShuffleMode _shuffleMode = AudioServiceShuffleMode.none;

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
        shuffleMode: _shuffleMode,
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
          shuffleMode: _shuffleMode,
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
          repeatMode: _repeatMode,
          shuffleMode: _shuffleMode,
        ),
      );
    });
  }

  void _listenToDurationChanges() {
    _durationSub = _player.durationStream.listen((duration) {
      if (duration == null) return;

      final current = mediaItem.value;
      if (current == null) return;

      if (current.duration != duration) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  void _listenToCurrentIndexChanges() {
    _currentIndexSub = _player.currentIndexStream.listen((index) {
      if (index == null) return;

      final sequence = _player.sequence;
      if (sequence == null || index < 0 || index >= sequence.length) return;

      final source = sequence[index];
      final item = source.tag as MediaItem?;
      if (item != null) {
        mediaItem.add(item);
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

    if (_shuffleMode == AudioServiceShuffleMode.all) {
      await _player.shuffle();
      await _player.setShuffleModeEnabled(true);
    } else {
      await _player.setShuffleModeEnabled(false);
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

    if (_shuffleMode == AudioServiceShuffleMode.all) {
      await _player.shuffle();
      await _player.setShuffleModeEnabled(true);
    } else {
      await _player.setShuffleModeEnabled(false);
    }

    await _player.seek(Duration.zero, index: startIndex);

    var selectedItem = mediaItems[startIndex];
    final playerDuration = _player.duration;
    if (playerDuration != null && playerDuration > Duration.zero) {
      selectedItem = selectedItem.copyWith(duration: playerDuration);
    }

    await _player.play();

    Future.delayed(const Duration(milliseconds: 300), () {
      final duration = _player.duration;
      final current = mediaItem.value;

      if (duration != null && duration > Duration.zero && current != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleMode = shuffleMode;

    if (shuffleMode == AudioServiceShuffleMode.all) {
      await _player.shuffle();
      await _player.setShuffleModeEnabled(true);
    } else {
      await _player.setShuffleModeEnabled(false);
    }

    playbackState.add(
      playbackState.value.copyWith(
        shuffleMode: _shuffleMode,
        repeatMode: _repeatMode,
      ),
    );
  }

  Future<void> disposePlayer() async {
    await _playbackEventSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _currentIndexSub?.cancel();
    await _player.dispose();
  }
}