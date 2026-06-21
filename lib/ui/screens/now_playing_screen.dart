import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/providers/music_providers.dart';
import 'package:musicplayer/ui/widgets/glass_container.dart';

import '../widgets/music_waveform.dart';


class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Ambient Background (Blurred Album Art placeholder)
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
                // Top Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('NOW PLAYING', style: TextStyle(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Album Art
                currentItemAsync.when(
                  data: (item) => Center(
                    child: AppGlassContainer(
                      width: 300,
                      height: 300,
                      padding: const EdgeInsets.all(20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          color: Colors.white10,
                          child: const Icon(Icons.music_note, size: 100, color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => const Icon(Icons.error),
                ),
                
                const SizedBox(height: 40),
                
                // Track Info
                currentItemAsync.when(
                  data: (item) => Column(
                    children: [
                      Text(
                        item?.title ?? 'No Track',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item?.artist ?? 'Unknown Artist',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                  loading: () => Container(),
                  error: (e, s) => Container(),
                ),
                
                const Spacer(),
                
                // Visualizer
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
                
                const SizedBox(height: 20),
                
                // Playback Controls Dock
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AppGlassContainer(
                    height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shuffle, color: Colors.white54),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 36),
                          onPressed: () => ref.read(audioHandlerProvider).skipToPrevious(),
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
                              backgroundColor: const Color(0xFF00E5FF).withAlpha((0.8 * 255).round()),
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
                          onPressed: () => ref.read(audioHandlerProvider).skipToNext(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.repeat, color: Colors.white54),
                          onPressed: () {},
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
