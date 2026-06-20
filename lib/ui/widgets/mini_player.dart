import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/providers/music_providers.dart';
import 'package:musicplayer/ui/screens/now_playing_screen.dart';
import 'package:musicplayer/ui/widgets/glass_container.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);

    return currentItemAsync.when(
      data: (item) {
        if (item == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
              );
            },
            child: AppGlassContainer(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 45,
                      height: 45,
                      color: Colors.white10,
                      child: const Icon(Icons.music_note, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.artist ?? 'Unknown Artist',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  playbackStateAsync.when(
                    data: (state) => IconButton(
                      icon: Icon(state.playing ? Icons.pause : Icons.play_arrow),
                      onPressed: () {
                        if (state.playing) {
                          ref.read(audioHandlerProvider).pause();
                        } else {
                          ref.read(audioHandlerProvider).play();
                        }
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => const Icon(Icons.error),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
