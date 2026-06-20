import 'package:isar/isar.dart';
import 'package:musicplayer/models/playlist.dart';
import 'package:musicplayer/models/song.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [SongSchema, PlaylistSchema],
      directory: dir.path,
    );
  }

  // Song operations
  Future<void> saveSongs(List<Song> songs) async {
    await isar.writeTxn(() async {
      await isar.songs.putAll(songs);
    });
  }

  Future<List<Song>> getAllSongs() async {
    return await isar.songs.where().findAll();
  }

  Future<void> updateSong(Song song) async {
    await isar.writeTxn(() async {
      await isar.songs.put(song);
    });
  }

  // Playlist operations
  Future<void> savePlaylist(Playlist playlist) async {
    await isar.writeTxn(() async {
      await isar.playlists.put(playlist);
    });
  }

  Future<List<Playlist>> getAllPlaylists() async {
    return await isar.playlists.where().findAll();
  }

  Future<void> deletePlaylist(int id) async {
    await isar.writeTxn(() async {
      await isar.playlists.delete(id);
    });
  }
}
