import 'dart:typed_data';

/// Copies a PNG to the system clipboard once [pngFuture] completes.
Future<void> copyPngToClipboard(Future<Uint8List> pngFuture) async {
  await pngFuture;
  throw UnsupportedError(
    'Copying images to the clipboard is not supported on this platform.',
  );
}
