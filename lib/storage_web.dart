import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:sembast_web/sembast_web.dart';

Future<Database> openDreamDatabase() =>
    databaseFactoryWeb.openDatabase('diario-sogni-v1', version: 1);
Future<String> recordingPath(String id) async => '$id.webm';
Future<String> persistAudio(String path) async {
  final response = await http.get(Uri.parse(path));
  if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
    throw StateError('Audio non disponibile');
  }
  final mime = response.headers['content-type'] ?? 'audio/webm';
  return 'data:$mime;base64,${base64Encode(response.bodyBytes)}';
}

String playbackUrl(String audio) => audio;

Future<Uint8List> readAudio(String audio) async =>
    UriData.fromUri(Uri.parse(audio)).contentAsBytes();
String audioExtension(String audio) =>
    audio.startsWith('data:audio/mp4') ? 'm4a' : 'webm';
Future<String> importAudio(
  String id,
  String extension,
  Uint8List bytes,
) async =>
    'data:${extension == 'm4a' ? 'audio/mp4' : 'audio/webm'};base64,${base64Encode(bytes)}';
// The data URI lives in the database record, removed by markDeleted.
Future<void> deleteAudio(String audio) async {}
