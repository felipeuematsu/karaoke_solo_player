enum Strings {
  appName,
  home,
  songs,
  users,
  playlists,
  queue,
  removeSongFromQueue,
  areYouSureRemoveSongFromQueue,
  ok,
  cancel,
  ;

  String get tr => _stringsMap[this] ?? '';
}

const _stringsMap = {
  Strings.appName: 'Karaoke Player',
  Strings.home: 'Home',
  Strings.songs: 'Songs',
  Strings.users: 'Users',
  Strings.playlists: 'Playlists',
  Strings.queue: 'Queue',
  Strings.removeSongFromQueue: 'Remove song from queue',
  Strings.areYouSureRemoveSongFromQueue: 'Are you sure you want to remove this song from queue?',
  Strings.ok: 'Ok',
  Strings.cancel: 'Cancel',
};