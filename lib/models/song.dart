import 'package:isar/isar.dart';

part 'song.g.dart';

@collection
class Song {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String path;

  final String title;
  final String? artist;
  final String? album;
  final int? duration;
  final int? size;
  final DateTime? dateAdded;
  final int? trackNumber;
  final int? discNumber;
  final String? genre;
  
  bool isFavorite = false;
  int playCount = 0;
  DateTime? lastPlayed;

  Song({
    required this.path,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.size,
    this.dateAdded,
    this.trackNumber,
    this.discNumber,
    this.genre,
    this.isFavorite = false,
    this.playCount = 0,
    this.lastPlayed,
  });
}
