import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicplayer/models/song.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform, File;

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlaybackEvent>? _playbackEventSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<int?>? _currentIndexSub;

  SharedPreferences? _prefs;
  Timer? _positionSaveTimer;
  bool _isRestoringSession = false;

  static const String _sessionQueueKey = 'session_queue';
  static const String _sessionIndexKey = 'session_index';
  static const String _sessionPositionKey = 'session_position';
  static const String _sessionRepeatModeKey = 'session_repeat_mode';
  static const String _sessionShuffleModeKey = 'session_shuffle_mode';
  static const String _sessionHasDataKey = 'session_has_data';

  MyAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenToPositionChanges();
    _listenToDurationChanges();
    _listenToCurrentIndexChanges();
    _initSessionRestore();
  }

  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  AudioServiceShuffleMode _shuffleMode = AudioServiceShuffleMode.none;

  List<MediaItem> _originalQueue = [];
  List<MediaItem> _shuffledQueue = [];

  Future<void> _initSessionRestore() async {
    _prefs = await SharedPreferences.getInstance();
    await _restoreSession();
  }

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

    await _saveSession();
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
      if (_player.playing) {
        _schedulePositionSave();
      }
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
      if (item == null) return;

      final current = mediaItem.value;

      if (current != null && current.id == item.id) {
        mediaItem.add(
          item.copyWith(
            duration: (current.duration != null && current.duration! > Duration.zero)
                ? current.duration
                : item.duration,
          ),
        );
      } else {
        mediaItem.add(item);
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() async {
    await _player.pause();
    await _saveSession();
    await _savePosition();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _saveSession();
    await _savePosition();
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

    _originalQueue = List<MediaItem>.from(mediaItems);

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

    await _saveSession();
    await _savePosition();
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

    _originalQueue = List<MediaItem>.from(mediaItems);
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

    await _saveSession();
    await _savePosition();
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

    if (Platform.isLinux) {
      await _setLinuxShuffleMode(shuffleMode);
    } else {
      if (shuffleMode == AudioServiceShuffleMode.all) {
        await _player.shuffle();
        await _player.setShuffleModeEnabled(true);
      } else {
        await _player.setShuffleModeEnabled(false);
      }
    }

    playbackState.add(
      playbackState.value.copyWith(
        shuffleMode: shuffleMode,
      ),
    );

    await _saveSession();
    await _savePosition();
  }

  Future<void> _setLinuxShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final currentItem = mediaItem.value;
    final currentQueue = List<MediaItem>.from(_originalQueue);

    if (currentQueue.isEmpty) return;

    if (shuffleMode == AudioServiceShuffleMode.all) {
      final shuffled = List<MediaItem>.from(currentQueue);
      shuffled.shuffle();

      if (currentItem != null) {
        final currentIndex = shuffled.indexWhere((item) => item.id == currentItem.id);
        if (currentIndex > 0) {
          final current = shuffled.removeAt(currentIndex);
          shuffled.insert(0, current);
        }
      }

      _shuffledQueue = shuffled;
      queue.add(shuffled);
      await _rebuildPlaylistFromQueue(shuffled, startFromFirst: true);
    } else {
      queue.add(currentQueue);

      int restoreIndex = 0;
      if (currentItem != null) {
        restoreIndex = currentQueue.indexWhere((item) => item.id == currentItem.id);
        if (restoreIndex < 0) restoreIndex = 0;
      }

      await _rebuildPlaylistFromQueue(currentQueue, startIndex: restoreIndex);
    }
  }

  Future<void> _rebuildPlaylistFromQueue(
      List<MediaItem> items, {
        bool startFromFirst = false,
        int startIndex = 0,
      }) async {

    final current = mediaItem.value;

    final audioSources = items.map((item) {
      final taggedItem =
      current != null &&
          current.id == item.id &&
          current.duration != null &&
          current.duration! > Duration.zero
          ? item.copyWith(duration: current.duration)
          : item;

      return AudioSource.file(
        item.id,
        tag: taggedItem,
      );
    }).toList();

    final wasPlaying = _player.playing;
    final currentPosition = _player.position;

    final resolvedIndex =
    (startFromFirst ? 0 : startIndex).clamp(0, items.length - 1);

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: resolvedIndex,
      initialPosition: startFromFirst ? Duration.zero : currentPosition,
    );

    if (wasPlaying) {
      await _player.play();
    }

    final resolvedItem = audioSources[resolvedIndex].tag as MediaItem;
    mediaItem.add(resolvedItem);
  }

  Map<String, dynamic> _mediaItemToMap(MediaItem item) {
    return {
      'id': item.id,
      'album': item.album,
      'title': item.title,
      'artist': item.artist,
      'duration': item.duration?.inMilliseconds,
      'extras': item.extras,
    };
  }

  MediaItem _mediaItemFromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as String,
      album: map['album'] as String?,
      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String?,
      duration: map['duration'] != null
          ? Duration(milliseconds: map['duration'] as int)
          : Duration.zero,
      extras: map['extras'] != null
          ? Map<String, dynamic>.from(map['extras'] as Map)
          : null,
    );
  }

  Future<void> _saveSession() async {
    final prefs = _prefs;
    if (prefs == null || _isRestoringSession) return;

    final currentQueue = queue.value;
    if (currentQueue.isEmpty) {
      await prefs.setBool(_sessionHasDataKey, false);
      return;
    }

    final currentIndex = _player.currentIndex ?? 0;
    final encodedQueue = jsonEncode(
      currentQueue.map((item) => _mediaItemToMap(item)).toList(),
    );

    await prefs.setString(_sessionQueueKey, encodedQueue);
    await prefs.setInt(_sessionIndexKey, currentIndex);
    await prefs.setInt(_sessionRepeatModeKey, _repeatMode.index);
    await prefs.setInt(_sessionShuffleModeKey, _shuffleMode.index);
    await prefs.setBool(_sessionHasDataKey, true);
  }

  Future<void> _savePosition() async {
    final prefs = _prefs;
    if (prefs == null || _isRestoringSession) return;

    await prefs.setInt(
      _sessionPositionKey,
      _player.position.inMilliseconds,
    );
  }

  void _schedulePositionSave() {
    if (_isRestoringSession) return;

    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer(const Duration(seconds: 2), () {
      _savePosition();
    });
  }

  Future<void> _restoreSession() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final hasData = prefs.getBool(_sessionHasDataKey) ?? false;
    if (!hasData) return;

    final queueJson = prefs.getString(_sessionQueueKey);
    if (queueJson == null || queueJson.isEmpty) return;

    _isRestoringSession = true;

    try {
      final decoded = jsonDecode(queueJson) as List<dynamic>;
      final restoredItems = decoded
          .map((e) => _mediaItemFromMap(Map<String, dynamic>.from(e as Map)))
          .where((item) => File(item.id).existsSync())
          .toList();

      if (restoredItems.isEmpty) {
        await prefs.setBool(_sessionHasDataKey, false);
        return;
      }

      _originalQueue = List<MediaItem>.from(restoredItems);
      queue.add(restoredItems);

      final savedIndex = prefs.getInt(_sessionIndexKey) ?? 0;
      final savedPositionMs = prefs.getInt(_sessionPositionKey) ?? 0;
      final savedRepeatMode = prefs.getInt(_sessionRepeatModeKey) ?? 0;
      final savedShuffleMode = prefs.getInt(_sessionShuffleModeKey) ?? 0;

      final resolvedIndex = savedIndex.clamp(0, restoredItems.length - 1);

      _repeatMode = AudioServiceRepeatMode.values[
      savedRepeatMode.clamp(0, AudioServiceRepeatMode.values.length - 1)];
      _shuffleMode = AudioServiceShuffleMode.values[
      savedShuffleMode.clamp(0, AudioServiceShuffleMode.values.length - 1)];

      final restoredPosition = Duration(
        milliseconds: savedPositionMs < 0 ? 0 : savedPositionMs,
      );

      final playlist = ConcatenatingAudioSource(
        children: restoredItems.map((item) {
          return AudioSource.file(
            item.id,
            tag: item,
          );
        }).toList(),
      );

      await _player.setAudioSource(
        playlist,
        initialIndex: resolvedIndex,
        initialPosition: restoredPosition,
      );

      await _player.setLoopMode(
        _repeatMode == AudioServiceRepeatMode.one
            ? LoopMode.one
            : _repeatMode == AudioServiceRepeatMode.all
            ? LoopMode.all
            : LoopMode.off,
      );

      if (_shuffleMode == AudioServiceShuffleMode.all) {
        if (Platform.isLinux) {
          await _setLinuxShuffleMode(AudioServiceShuffleMode.all);
        } else {
          await _player.shuffle();
          await _player.setShuffleModeEnabled(true);
        }
      } else {
        await _player.setShuffleModeEnabled(false);
      }

      final restoredCurrent = restoredItems[resolvedIndex];
      final playerDuration = _player.duration;

      mediaItem.add(
        restoredCurrent.copyWith(
          duration: (playerDuration != null && playerDuration > Duration.zero)
              ? playerDuration
              : restoredCurrent.duration,
        ),
      );

      playbackState.add(
        playbackState.value.copyWith(
          repeatMode: _repeatMode,
          shuffleMode: _shuffleMode,
        ),
      );
    } catch (_) {
      await prefs.setBool(_sessionHasDataKey, false);
    } finally {
      _isRestoringSession = false;
    }
  }

  Future<void> disposePlayer() async {
    await _playbackEventSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _currentIndexSub?.cancel();
    _positionSaveTimer?.cancel();
    await _saveSession();
    await _savePosition();
    await _player.dispose();
  }
}