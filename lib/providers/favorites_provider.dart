import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _favoritesKey = 'favorite_song_paths';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final favoritesProvider =
StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this.ref) : super({}) {
    _loadFavorites();
  }

  final Ref ref;

  Future<void> _loadFavorites() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final saved = prefs.getStringList(_favoritesKey) ?? [];
    state = saved.toSet();
  }

  Future<void> toggleFavorite(String songPath) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);

    final updated = Set<String>.from(state);
    if (updated.contains(songPath)) {
      updated.remove(songPath);
    } else {
      updated.add(songPath);
    }

    state = updated;
    await prefs.setStringList(_favoritesKey, updated.toList());
  }

  bool isFavorite(String songPath) {
    return state.contains(songPath);
  }
}