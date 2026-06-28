import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/providers/music_providers.dart';
import 'package:musicplayer/ui/screens/now_playing_screen.dart';
import 'package:musicplayer/ui/widgets/song_artwork.dart';
import 'package:musicplayer/utils/app_colors.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);

    return currentItemAsync.when(
      data: (item) {
        if (item == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const NowPlayingScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.elevatedSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Progress Bar (Bottom)
                Positioned(bottom: 0, left: 20, right: 20, child: playbackStateAsync.when(
                  data: (state) {
                    final position = state.updatePosition.inMilliseconds.toDouble();
                    final duration = item.duration?.inMilliseconds.toDouble() ?? 1.0;
                    return LinearProgressIndicator(
                      value: (position / duration).clamp(0.0, 1.0),
                      backgroundColor: Colors.white10,
                      color: AppColors.primaryText.withValues(alpha: 0.5),
                      minHeight: 2,
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'artwork',
                        child: SongArtwork(
                          mediaStoreId: item.extras?['mediaStoreId'] as int?,
                          localArtworkPath: item.extras?['localArtworkPath'] as String?,
                          size: 48,
                          borderRadius: 12,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                            ),
                            Text(
                              item.artist ?? 'Unknown Artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      playbackStateAsync.when(
                        data: (state) => IconButton(
                          icon: Icon(
                            state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: AppColors.primaryText,
                            size: 28,
                          ),
                          onPressed: () {
                            if (state.playing) {
                              ref.read(audioHandlerProvider).pause();
                            } else {
                              ref.read(audioHandlerProvider).play();
                            }
                          },
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, _) => const Icon(Icons.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
