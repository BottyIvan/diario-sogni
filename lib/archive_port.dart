import 'dart:typed_data';

abstract interface class ArchivePort {
  bool get supported;
  Future<String?> restore();
  Future<String?> choose();
  Future<void> disconnect();
  Future<List<String>> list();
  Future<Uint8List> read(String name);
  Future<void> write(String name, Uint8List bytes);
  Future<void> remove(String name);
}

bool validArchiveName(String name) =>
    RegExp(r'^[a-zA-Z0-9_.-]{1,200}$').hasMatch(name) && !name.contains('..');
