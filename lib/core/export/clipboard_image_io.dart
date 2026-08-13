import 'dart:typed_data';

import 'package:pasteboard/pasteboard.dart';

/// Copies a PNG to the system clipboard once [pngFuture] completes.
Future<void> copyPngToClipboard(Future<Uint8List> pngFuture) async {
  final bytes = await pngFuture;
  await Pasteboard.writeImage(bytes);
}
