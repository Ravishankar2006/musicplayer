import 'package:isar/isar.dart';
import 'package:musicplayer/models/playlist.dart';
import 'package:musicplayer/models/song.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Isar? _isar;

  Isar get isar {
    if (_isar == null) {
      throw Exception('Isar has not been initialized. Call init() first.');
    }
    return _isar!;
  }

  Future<void> init() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [SongSchema, PlaylistSchema],
      directory: dir.path,
    );
  }

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