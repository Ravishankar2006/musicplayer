import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _recentlyPlayedKey = 'recently_played_song_paths';
const _recentlyPlayedMax = 20;

final recentlyPlayedProvider =
StateNotifierProvider<RecentlyPlayedNotifier, List<String>>((ref) {
  return RecentlyPlayedNotifier(ref);
});

class RecentlyPlayedNotifier extends StateNotifier<List<String>> {
  RecentlyPlayedNotifier(this.ref) : super([]) {
    _loadRecentlyPlayed();
  }

  final Ref ref;

  Future<SharedPreferences> get _prefs async {
    return SharedPreferences.getInstance();
  }

  Future<void> _loadRecentlyPlayed() async {
    final prefs = await _prefs;
    state = prefs.getStringList(_recentlyPlayedKey) ?? [];
  }

  Future<void> addPlayedSong(String songPath) async {
    final prefs = await _prefs;

    final updated = <String>[
      songPath,
      ...state.where((path) => path != songPath),
    ];

    final trimmed = updated.take(_recentlyPlayedMax).toList();
    state = trimmed;
    await prefs.setStringList(_recentlyPlayedKey, trimmed);
  }

  Future<void> clearHistory() async {
    final prefs = await _prefs;
    state = [];
    await prefs.remove(_recentlyPlayedKey);
  }
}