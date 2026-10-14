import 'dart:io';

import 'package:flutter/services.dart';

import 'archive_port.dart';

ArchivePort createArchivePort() => AndroidArchivePort();

class AndroidArchivePort implements ArchivePort {
  static const _channel = MethodChannel('it.diariosogni/archive');
  @override
  bool get supported => Platform.isAndroid;
  @override
  Future<String?> restore() async =>
      supported ? await _channel.invokeMethod<String>('restore') : null;
  @override
  Future<String?> choose() => _channel.invokeMethod<String>('choose');
  @override
  Future<void> disconnect() => _channel.invokeMethod<void>('disconnect');
  @override
  Future<List<String>> list() async =>
      await _channel.invokeListMethod<String>('list') ?? [];
  @override
  Future<Uint8List> read(String name) async =>
      (await _channel.invokeMethod<Uint8List>('read', {'name': name}))!;
  @override
  Future<void> write(String name, Uint8List bytes) =>
      _channel.invokeMethod<void>('write', {'name': name, 'bytes': bytes});
  @override
  Future<void> remove(String name) =>
      _channel.invokeMethod<void>('remove', {'name': name});
}
