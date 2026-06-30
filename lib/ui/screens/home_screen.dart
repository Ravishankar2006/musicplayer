import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/providers/music_providers.dart';
import 'package:musicplayer/ui/widgets/mini_player.dart';
import 'package:musicplayer/ui/widgets/song_artwork.dart';
import 'package:musicplayer/ui/widgets/fullscreen_toggle.dart';
import 'package:musicplayer/utils/app_colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);
    final audioHandler = ref.read(audioHandlerProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildAppBar(context, ref),
                  songsAsync.when(
                    data: (songs) {
                      if (songs.isEmpty) {
                        return SliverFillRemaining(
                          child: _buildEmptyState(ref),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.only(bottom: 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = songs[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => audioHandler.playQueueAtIndex(songs, index),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      children: [
                                        SongArtwork(
                                          mediaStoreId: song.mediaStoreId,
                                          localArtworkPath: song.localArtworkPath,
                                          size: 52,
                                          borderRadius: 12,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                song.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryText,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                song.artist ?? 'Unknown Artist',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.secondaryText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert_rounded,
                                            color: AppColors.secondaryText,
                                            size: 20,
                                          ),
                                          color: AppColors.elevatedSurface,
                                          onSelected: (value) async {
                                            switch (value) {
                                              case 'play_next':
                                                await audioHandler.playNext(song);
                                                break;
                                              case 'add_to_queue':
                                                await audioHandler.addSongToQueue(song);
                                                break;
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem<String>(
                                              value: 'play_next',
                                              child: Text('Play next'),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'add_to_queue',
                                              child: Text('Add to queue'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
                    error: (e, s) => SliverFillRemaining(
                      child: Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: MiniPlayer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
        title: Text(
          'Library',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
        ),
      ),
      actions: [
        const FullScreenToggle(),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryText),
          onPressed: () async {
            await ref.read(musicScannerProvider).scanFolder();
            ref.invalidate(songsProvider);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music_rounded, size: 64, color: AppColors.secondaryText.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          const Text(
            'Your library is empty',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () async {
              await ref.read(musicScannerProvider).scanFolder();
              ref.invalidate(songsProvider);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('SCAN FOLDER'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryText,
              backgroundColor: AppColors.elevatedSurface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
