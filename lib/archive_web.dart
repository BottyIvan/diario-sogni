import 'dart:js_interop';
import 'dart:typed_data';

import 'archive_port.dart';

@JS('dreamArchive.supported')
external bool get _supported;
@JS('dreamArchive.restore')
external JSPromise<JSAny?> _restore();
@JS('dreamArchive.choose')
external JSPromise<JSAny?> _choose();
@JS('dreamArchive.disconnect')
external JSPromise<JSAny?> _disconnect();
@JS('dreamArchive.list')
external JSPromise<JSArray<JSString>> _list();
@JS('dreamArchive.read')
external JSPromise<JSUint8Array> _read(JSString name);
@JS('dreamArchive.write')
external JSPromise<JSAny?> _write(JSString name, JSUint8Array bytes);
@JS('dreamArchive.remove')
external JSPromise<JSAny?> _remove(JSString name);

ArchivePort createArchivePort() => BrowserArchivePort();

class BrowserArchivePort implements ArchivePort {
  @override
  bool get supported => _supported;
  @override
  Future<String?> restore() async =>
      (await _restore().toDart as JSString?)?.toDart;
  @override
  Future<String?> choose() async =>
      (await _choose().toDart as JSString?)?.toDart;
  @override
  Future<void> disconnect() async {
    await _disconnect().toDart;
  }

  @override
  Future<List<String>> list() async =>
      (await _list().toDart).toDart.map((value) => value.toDart).toList();
  @override
  Future<Uint8List> read(String name) async =>
      (await _read(name.toJS).toDart).toDart;
  @override
  Future<void> write(String name, Uint8List bytes) async {
    await _write(name.toJS, bytes.toJS).toDart;
  }

  @override
  Future<void> remove(String name) async {
    await _remove(name.toJS).toDart;
  }
}
