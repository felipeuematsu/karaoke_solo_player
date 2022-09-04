class SongModel {
  SongModel(this.songId, this.duration, this.title, this.artist, this.path, [this.lastPlayed]);

  final int songId, duration;
  final String title, artist, path;
  final DateTime? lastPlayed;

  Map<String, dynamic> toMap() {
    return {
      'songId': songId,
      'duration': duration,
      'title': title,
      'artist': artist,
      'path': path,
      'lastPlayed': lastPlayed,
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      map['songId'] as int,
      map['duration'] as int,
      map['title'] as String,
      map['artist'] as String,
      map['path'] as String,
      DateTime.tryParse(map['lastPlayed'] as String? ?? ''),
    );
  }
}
