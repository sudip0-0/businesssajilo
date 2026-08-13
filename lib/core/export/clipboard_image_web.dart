import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart';

/// Copies a PNG to the clipboard.
///
/// Starts [Clipboard.write] immediately with a deferred blob so the call can
/// stay inside the user-gesture from tapping A4/A5, while PDF rasterization
/// finishes asynchronously.
Future<void> copyPngToClipboard(Future<Uint8List> pngFuture) async {
  final blobPromise = Future<Blob>(() async {
    final bytes = await pngFuture;
    return _pngBlob(bytes);
  }).toJS;

  final items = JSObject();
  items.setProperty('image/png'.toJS, blobPromise);
  final item = ClipboardItem(items);
  await window.navigator.clipboard.write([item].toJS).toDart;
}

Blob _pngBlob(Uint8List bytes) {
  return Blob([bytes.toJS].toJS, BlobPropertyBag(type: 'image/png'));
}
