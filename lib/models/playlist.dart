import 'package:isar/isar.dart';

part 'playlist.g.dart';

@collection
class Playlist {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String name;

  final DateTime dateCreated;
  
  List<String> songPaths = [];

  Playlist({
    required this.name,
    required this.dateCreated,
    this.songPaths = const [],
  });
}
