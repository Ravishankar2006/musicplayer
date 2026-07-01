import 'dart:io';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/providers/favorites_provider.dart';
import 'package:musicplayer/providers/music_providers.dart';
import 'package:musicplayer/ui/widgets/song_artwork.dart';
import 'package:musicplayer/ui/widgets/fullscreen_toggle.dart';
import 'package:musicplayer/utils/app_colors.dart';
import 'dart:math';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);
    final favorites = ref.watch(favoritesProvider);
    final currentItem = currentItemAsync.value;
    final currentSongPath = currentItem?.id;
    final isFavorite =
        currentSongPath != null && favorites.contains(currentSongPath);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: currentItemAsync.when(
        data: (item) {
          if (item == null) return const Center(child: Text('No song playing'));
          
          final localArtworkPath = item.extras?['localArtworkPath'] as String?;
          final mediaStoreId = item.extras?['mediaStoreId'] as int?;

          return Stack(
            children: [
              // Immersive Background
              if (localArtworkPath != null && File(localArtworkPath).existsSync())
                Positioned.fill(
                  child: Image.file(
                    File(localArtworkPath),
                    fit: BoxFit.cover,
                  ),
                ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(
                    color: AppColors.background.withValues(alpha: 0.85),
                  ),
                ),
              ),

              // Main Content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape = constraints.maxWidth > constraints.maxHeight;

                    if (isLandscape) {
                      return _buildLandscapeLayout(
                        context,
                        ref,
                        item,
                        playbackStateAsync,
                        localArtworkPath,
                        mediaStoreId,
                        isFavorite,
                        currentSongPath,
                      );
                    } else {
                      return _buildPortraitLayout(
                        context,
                        ref,
                        item,
                        playbackStateAsync,
                        localArtworkPath,
                        mediaStoreId,
                        isFavorite,
                        currentSongPath,
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPortraitLayout(
      BuildContext context,
      WidgetRef ref,
      MediaItem item,
      AsyncValue<PlaybackState> playbackStateAsync,
      String? localArtworkPath,
      int? mediaStoreId,
      bool isFavorite,
      String? currentSongPath,
      ) {
    return Column(
      children: [
        _buildAppBar(context, ref),
        const Spacer(),
        
        // Artwork
        Hero(
          tag: 'artwork',
          child: SongArtwork(
            mediaStoreId: mediaStoreId,
            localArtworkPath: localArtworkPath,
            size: min(MediaQuery.of(context).size.width * 0.8, MediaQuery.of(context).size.height * 0.4),
            borderRadius: 24,
            showShadow: true,
          ),
        ),
        
        const Spacer(),

        // Typography & Metadata
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.artist ?? 'Unknown Artist',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.redAccent : AppColors.primaryText,
                  size: 28,
                ),
                onPressed: currentSongPath == null
                    ? null
                    : () async {
                  await ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(currentSongPath);
                },
              ),
            ],
          ),
        ),

        const Spacer(),

        // Controls
        _buildControls(ref, playbackStateAsync, item),
        
        const SizedBox(height: 64),
      ],
    );
  }

  Widget _buildLandscapeLayout(
      BuildContext context,
      WidgetRef ref,
      MediaItem item,
      AsyncValue<PlaybackState> playbackStateAsync,
      String? localArtworkPath,
      int? mediaStoreId,
      bool isFavorite,
      String? currentSongPath,
      ) {
    return Column(
      children: [
        _buildAppBar(context, ref),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Artwork
                Hero(
                  tag: 'artwork',
                  child: SongArtwork(
                    mediaStoreId: mediaStoreId,
                    localArtworkPath: localArtworkPath,
                    size: min(MediaQuery.of(context).size.width * 0.4, MediaQuery.of(context).size.height * 0.6),
                    borderRadius: 24,
                    showShadow: true,
                  ),
                ),
                const SizedBox(width: 64),
                // Right: Metadata & Controls
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontSize: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item.artist ?? 'Unknown Artist',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppColors.secondaryText,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFavorite ? Colors.redAccent : AppColors.primaryText,
                                size: 30,
                              ),
                              onPressed: currentSongPath == null
                                  ? null
                                  : () async {
                                await ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(currentSongPath);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 64),
                        _buildControls(ref, playbackStateAsync, item, isLandscape: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'NOW PLAYING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.secondaryText.withValues(alpha: 0.8),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FullScreenToggle(),
              IconButton(
                icon: const Icon(Icons.queue_music_rounded),
                onPressed: () => _showQueueSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(WidgetRef ref, AsyncValue<PlaybackState> stateAsync, MediaItem item, {bool isLandscape = false}) {
    final audioHandler = ref.read(audioHandlerProvider);

    return Column(
      crossAxisAlignment: isLandscape ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Progress Slider
        stateAsync.when(
          data: (state) {
            final position = state.updatePosition.inMilliseconds.toDouble();
            final duration = item.duration?.inMilliseconds.toDouble() ?? 1.0;
            
            return Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: AppColors.primaryText,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: AppColors.primaryText,
                    overlayColor: AppColors.primaryText.withValues(alpha: 0.1),
                  ),
                  child: Slider(
                    value: position.clamp(0.0, duration),
                    max: duration,
                    onChanged: (value) {
                      audioHandler.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(state.updatePosition), style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      Text(_formatDuration(item.duration ?? Duration.zero), style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 24),

        // Playback Buttons
        Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              stateAsync.when(
                data: (state) {
                  final isShuffleOn = state.shuffleMode == AudioServiceShuffleMode.all;
                  return IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      size: 20,
                      color: isShuffleOn ? AppColors.primaryText : AppColors.secondaryText,
                    ),
                    onPressed: () => audioHandler.setShuffleMode(
                      isShuffleOn ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
                    ),
                  );
                },
                loading: () => const IconButton(
                  icon: Icon(Icons.shuffle_rounded),
                  onPressed: null,
                ),
                error: (_, _) => const Icon(Icons.error),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 36),
                color: AppColors.primaryText,
                onPressed: () => audioHandler.skipToPrevious(),
              ),
              const SizedBox(width: 16),
              stateAsync.when(
                data: (state) => Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryText,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 36,
                      color: AppColors.background,
                    ),
                    onPressed: () {
                      if (state.playing) {
                        audioHandler.pause();
                      } else {
                        audioHandler.play();
                      }
                    },
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => const Icon(Icons.error),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 36),
                color: AppColors.primaryText,
                onPressed: () => audioHandler.skipToNext(),
              ),
              const SizedBox(width: 16),
              stateAsync.when(
                data: (state) {
                  IconData icon = Icons.repeat_rounded;
                  Color color = AppColors.secondaryText;
                  if (state.repeatMode == AudioServiceRepeatMode.one) {
                    icon = Icons.repeat_one_rounded;
                    color = AppColors.primaryText;
                  } else if (state.repeatMode == AudioServiceRepeatMode.all) {
                    icon = Icons.repeat_rounded;
                    color = AppColors.primaryText;
                  }
                  return IconButton(
                    icon: Icon(icon, size: 20, color: color),
                    onPressed: () async {
                      final current = state.repeatMode;
                      final next = switch (current) {
                        AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
                        AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
                        AudioServiceRepeatMode.one => AudioServiceRepeatMode.none,
                        _ => AudioServiceRepeatMode.none,
                      };

                      await audioHandler.setRepeatMode(next);
                    },
                  );
                },
                loading: () => const IconButton(
                  icon: Icon(Icons.repeat_rounded),
                  onPressed: null,
                ),
                error: (_, _) => const Icon(Icons.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QueueSheet(),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);
    final audioHandler = ref.read(audioHandlerProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Queue',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: queueAsync.when(
                data: (queue) => playbackStateAsync.when(
                  data: (playbackState) {
                    final currentIndex = playbackState.queueIndex ?? 0;

                    if (queue.isEmpty) {
                      return const Center(
                        child: Text(
                          'Queue is empty',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      );
                    }

                    return ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: queue.length,
                      onReorderItem: (oldIndex, newIndex) async {
                        await audioHandler.customAction(
                          'moveQueueItem',
                          {
                            'oldIndex': oldIndex,
                            'newIndex': newIndex,
                          },
                        );
                      },
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        final isCurrent = index == currentIndex;
                        final artPath = item.extras?['localArtworkPath'] as String?;
                        final mediaStoreId = item.extras?['mediaStoreId'] as int?;

                        return Container(
                          key: ValueKey(item.id),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primaryText.withValues(alpha: 0.08)
                                : AppColors.background.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            leading: SongArtwork(
                              mediaStoreId: mediaStoreId,
                              localArtworkPath: artPath,
                              size: 48,
                              borderRadius: 10,
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              item.artist ?? 'Unknown Artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            onTap: () async {
                              await audioHandler.skipToQueueItem(index);
                              if (context.mounted) Navigator.pop(context);
                            },
                            trailing: SizedBox(
                              width: 72,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      await audioHandler.customAction(
                                        'removeQueueItemAt',
                                        {'index': index},
                                      );
                                    },
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.secondaryText,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(
                                      Icons.drag_handle_rounded,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(child: Text('Failed to load playback state')),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text('Failed to load queue')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
