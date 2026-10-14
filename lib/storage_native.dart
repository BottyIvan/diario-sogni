import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openDreamDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  return databaseFactoryIo.openDatabase(
    '${directory.path}/dreams.db',
    version: 1,
  );
}

Future<String> recordingPath(String id) async {
  final directory = await getApplicationDocumentsDirectory();
  final audio = Directory('${directory.path}/audio');
  await audio.create(recursive: true);
  return '${audio.path}/$id.m4a';
}

Future<String> persistAudio(String path) async {
  final file = File(path);
  if (!await file.exists() || await file.length() == 0) {
    throw StateError('Audio non disponibile');
  }
  return path;
}

String playbackUrl(String audio) => Uri.file(audio).toString();

Future<Uint8List> readAudio(String audio) => File(audio).readAsBytes();
String audioExtension(String audio) =>
    audio.toLowerCase().endsWith('.webm') ? 'webm' : 'm4a';
Future<String> importAudio(String id, String extension, Uint8List bytes) async {
  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id) ||
      !['m4a', 'webm'].contains(extension)) {
    throw FormatException('Nome audio non valido');
  }
  final directory = await getApplicationDocumentsDirectory();
  final folder = Directory('${directory.path}/audio');
  await folder.create(recursive: true);
  final file = File('${folder.path}/$id.$extension');
  final temporary = File('${file.path}.import');
  await temporary.writeAsBytes(bytes, flush: true);
  await temporary.rename(file.path);
  return file.path;
}

Future<void> deleteAudio(String audio) async {
  if (audio.isEmpty) return;
  if (!(await Future.wait(
    [
      audio,
      '$audio.asr.wav',
      '$audio.import',
    ].map((path) => File(path).exists()),
  )).any((exists) => exists)) {
    return;
  }
  final directory = await getApplicationDocumentsDirectory();
  final folder = Directory('${directory.path}/audio');
  await deleteAudioFromFolder(audio, folder);
}

Future<void> deleteAudioFromFolder(String audio, Directory folder) async {
  final files = <File>[];
  for (final path in [audio, '$audio.asr.wav', '$audio.import']) {
    final file = File(path);
    if (await file.exists()) files.add(file);
  }
  if (files.isEmpty) return;
  final resolvedFolder = await folder.resolveSymbolicLinks();
  // Validate all resolved paths before removing any file.
  for (final file in files) {
    final resolvedFile = await file.resolveSymbolicLinks();
    if (!resolvedFile.startsWith('$resolvedFolder${Platform.pathSeparator}')) {
      throw StateError('Audio fuori dall’archivio dell’app');
    }
  }
  for (final file in files) {
    await file.delete();
  }
}
