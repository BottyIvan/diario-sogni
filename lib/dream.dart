class Dream {
  const Dream({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.durationMs,
    required this.audio,
    this.transcript = '',
    this.automaticTranscript,
    this.transcriptEdited = false,
  });
  final String id, title, audio, transcript;
  final String? automaticTranscript;
  final bool transcriptEdited;
  final DateTime createdAt;
  final int durationMs;
  Dream edited({required String title, required String transcript}) => Dream(
    id: id,
    title: title.trim().isEmpty ? this.title : title.trim(),
    createdAt: createdAt,
    durationMs: durationMs,
    audio: audio,
    transcript: transcript.trim(),
    automaticTranscript: automaticTranscript,
    transcriptEdited: transcriptEdited || transcript.trim() != this.transcript,
  );
  bool matches(String query) {
    final text = '$title $transcript'.toLowerCase();
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .every(text.contains);
  }

  Map<String, Object?> toMap() => {
    'schema': 1,
    'title': title,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'durationMs': durationMs,
    'audio': audio,
    'transcript': transcript,
    'automaticTranscript': automaticTranscript,
    'transcriptEdited': transcriptEdited,
  };
  factory Dream.fromMap(String id, Map<String, Object?> map) => Dream(
    id: id,
    title: map['title'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    durationMs: map['durationMs'] as int,
    audio: map['audio'] as String,
    transcript: map['transcript'] as String? ?? '',
    automaticTranscript: map['automaticTranscript'] as String?,
    transcriptEdited:
        map['transcriptEdited'] as bool? ??
        (map['transcript'] as String? ?? '').isNotEmpty,
  );
  Dream withAutomaticTranscript(String text) => Dream(
    id: id,
    title: title,
    createdAt: createdAt,
    durationMs: durationMs,
    audio: audio,
    transcript: transcriptEdited ? transcript : text,
    automaticTranscript: text,
    transcriptEdited: transcriptEdited,
  );
}

String twoDigits(int value) => value.toString().padLeft(2, '0');
String dreamDate(DateTime date) {
  final local = date.toLocal();
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} · ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

String audioDuration(Duration duration) =>
    '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}';
String defaultTitle(DateTime date) {
  const weekdays = [
    'lunedì',
    'martedì',
    'mercoledì',
    'giovedì',
    'venerdì',
    'sabato',
    'domenica',
  ];
  final local = date.toLocal();
  return 'Sogno: ${weekdays[local.weekday - 1]} '
      '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
