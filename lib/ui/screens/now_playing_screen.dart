import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/providers/music_providers.dart';
import 'package:musicplayer/ui/widgets/glass_container.dart';
import 'package:musicplayer/ui/widgets/song_artwork.dart';
import 'package:musicplayer/ui/widgets/music_waveform.dart';

import '../widgets/player_seek_bar.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);

    final playbackState = playbackStateAsync.maybeWhen(
      data: (state) => state,
      orElse: () => null,
    );

    final currentPosition = playbackState?.position ?? Duration.zero;

    final totalDuration = currentItemAsync.maybeWhen(
      data: (item) => item?.duration,
      orElse: () => null,
    ) ?? Duration.zero;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF0C0C0C)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                currentItemAsync.when(
                  data: (item) {
                    final localArtworkPath =
                    item?.extras?['localArtworkPath'] as String?;
                    final audioPath = item?.id;

                    return Center(
                      child: AppGlassContainer(
                        width: 300,
                        height: 300,
                        padding: const EdgeInsets.all(20),
                        child: SongArtwork(
                          localArtworkPath: localArtworkPath,
                          audioPath: audioPath,
                          size: 260,
                          borderRadius: 15,
                        ),
                      ),
                    );
                  },
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (e, s) => const Center(child: Icon(Icons.error)),
                ),
                const SizedBox(height: 40),
                currentItemAsync.when(
                  data: (item) => Column(
                    children: [
                      Text(
                        item?.title ?? 'No Track',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item?.artist ?? 'Unknown Artist',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                  loading: () => Container(),
                  error: (e, s) => Container(),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    height: 60,
                    child: Center(
                      child: playbackStateAsync.maybeWhen(
                        data: (state) => MusicWaveform(isPlaying: state.playing),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PlayerSeekBar(
                    position: currentPosition,
                    duration: totalDuration,
                    onSeek: (target) async {
                      await ref.read(audioHandlerProvider).seek(target);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AppGlassContainer(
                    height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        playbackStateAsync.when(
                          data: (state) {
                            final isShuffleOn = state.shuffleMode == AudioServiceShuffleMode.all;

                            return IconButton(
                              tooltip: isShuffleOn ? 'Shuffle on' : 'Shuffle off',
                              icon: Icon(
                                Icons.shuffle,
                                color: isShuffleOn ? const Color(0xFF00E5FF) : Colors.white54,
                              ),
                              onPressed: () async {
                                final handler = ref.read(audioHandlerProvider);
                                final current = state.shuffleMode;

                                await handler.setShuffleMode(
                                  current == AudioServiceShuffleMode.all
                                      ? AudioServiceShuffleMode.none
                                      : AudioServiceShuffleMode.all,
                                );
                              },
                            );
                          },
                          loading: () => IconButton(
                            icon: const Icon(Icons.shuffle, color: Colors.white54),
                            onPressed: null,
                          ),
                          error: (_, __) => IconButton(
                            icon: const Icon(Icons.shuffle, color: Colors.white54),
                            onPressed: null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 36),
                          onPressed: () =>
                              ref.read(audioHandlerProvider).skipToPrevious(),
                        ),
                        playbackStateAsync.when(
                          data: (state) => GestureDetector(
                            onTap: () {
                              if (state.playing) {
                                ref.read(audioHandlerProvider).pause();
                              } else {
                                ref.read(audioHandlerProvider).play();
                              }
                            },
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFF00E5FF)
                                  .withAlpha((0.8 * 255).round()),
                              child: Icon(
                                state.playing ? Icons.pause : Icons.play_arrow,
                                color: Colors.black,
                                size: 32,
                              ),
                            ),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (e, s) => const Icon(Icons.error),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 36),
                          onPressed: () =>
                              ref.read(audioHandlerProvider).skipToNext(),
                        ),
                        playbackStateAsync.when(
                          data: (state) {
                            final repeatMode = state.repeatMode;

                            final IconData icon;
                            final Color color;
                            final String tooltip;

                            switch (repeatMode) {
                              case AudioServiceRepeatMode.one:
                                icon = Icons.repeat_one;
                                color = const Color(0xFF00E5FF);
                                tooltip = 'Repeat one';
                                break;
                              case AudioServiceRepeatMode.all:
                                icon = Icons.repeat;
                                color = const Color(0xFF00E5FF);
                                tooltip = 'Repeat all';
                                break;
                              case AudioServiceRepeatMode.none:
                              default:
                                icon = Icons.repeat;
                                color = Colors.white54;
                                tooltip = 'Repeat off';
                                break;
                            }

                            return IconButton(
                              tooltip: tooltip,
                              icon: Icon(icon, color: color),
                              onPressed: () {
                                ref.read(audioHandlerProvider).customAction('cycleRepeatMode');
                              },
                            );
                          },
                          loading: () => IconButton(
                            icon: const Icon(Icons.repeat, color: Colors.white54),
                            onPressed: null,
                          ),
                          error: (_, __) => IconButton(
                            icon: const Icon(Icons.repeat, color: Colors.white54),
                            onPressed: null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}