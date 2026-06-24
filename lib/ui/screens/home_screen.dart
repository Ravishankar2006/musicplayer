import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/providers/music_providers.dart';
import 'package:musicplayer/ui/widgets/glass_container.dart';
import 'package:musicplayer/ui/widgets/mini_player.dart';
import 'package:musicplayer/ui/widgets/song_artwork.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 150,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('MY LIBRARY', style: TextStyle(letterSpacing: 2, fontSize: 16)),
                  centerTitle: true,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1A1A2E), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              songsAsync.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No music found. Tap refresh to scan.')),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = songs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: AppGlassContainer(
                              borderRadius: 15,
                              height: 70,
                              child: ListTile(
                                leading: SongArtwork(
                                  localArtworkPath: song.localArtworkPath,
                                  audioPath: song.path,
                                  size: 45,
                                ),
                                title: Text(song.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                subtitle: Text(song.artist ?? 'Unknown Artist', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                                onTap: () {
                                  ref.read(audioHandlerProvider).playSong(song);
                                },
                              ),
                            ),
                          );
                        },
                        childCount: songs.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF00E5FF),
          onPressed: () async {
            await ref.read(musicScannerProvider).scanFolder();
            ref.invalidate(songsProvider);
          },
          label: const Text('SCAN FOLDER', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.folder_open, color: Colors.black),
        ),
      ),
    );
  }
}
