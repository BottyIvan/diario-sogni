// iOS can relocate an app's container during an update. Store audio relative
// to Documents, and migrate only the previously supported Documents/audio form.
String audioPathInDocuments(String stored, String documents) {
  String? name;
  if (stored.startsWith('audio/')) {
    name = stored.substring('audio/'.length);
  } else {
    const marker = '/Documents/audio/';
    final index = stored.lastIndexOf(marker);
    if (index >= 0) name = stored.substring(index + marker.length);
  }
  if (name == null) return stored;
  if (!RegExp(r'^[a-zA-Z0-9_-]+\.(m4a|webm)$').hasMatch(name)) {
    throw const FormatException('Percorso audio non valido');
  }
  return '$documents/audio/$name';
}

String relativeAudioInDocuments(String path, String documents) {
  final prefix = '$documents/audio/';
  if (!path.startsWith(prefix)) return path;
  final relative = 'audio/${path.substring(prefix.length)}';
  audioPathInDocuments(
    relative,
    documents,
  ); // Reject nested or traversal paths.
  return relative;
}
