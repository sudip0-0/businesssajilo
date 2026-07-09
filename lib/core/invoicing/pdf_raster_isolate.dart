import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as im;
import 'package:printing/printing.dart';

/// Rasterizes the first PDF page, then encodes PNG off the UI isolate.
///
/// [Printing.raster] must run on the root isolate (platform channel). The
/// heavier RGBA→PNG encode runs in [compute] via the pure-Dart `image` package.
Future<Uint8List> rasterPdfFirstPageToPng(
  Uint8List pdfBytes, {
  double dpi = 180,
}) async {
  final images = Printing.raster(pdfBytes, pages: const [0], dpi: dpi);
  PdfRaster? first;
  await for (final page in images) {
    first = page;
    break;
  }
  if (first == null) {
    throw StateError('Failed to rasterize PDF');
  }
  return encodeRgbaToPng(
    width: first.width,
    height: first.height,
    pixels: first.pixels,
  );
}

/// Encodes raw RGBA pixels to PNG, preferring a background isolate.
Future<Uint8List> encodeRgbaToPng({
  required int width,
  required int height,
  required Uint8List pixels,
}) {
  return compute(_encodeRgbaToPngIsolate, <Object>[width, height, pixels]);
}

/// Pure encoder used by [compute] and unit tests.
Uint8List encodeRgbaToPngSync({
  required int width,
  required int height,
  required Uint8List pixels,
}) {
  final image = im.Image.fromBytes(
    width: width,
    height: height,
    bytes: pixels.buffer,
    bytesOffset: pixels.offsetInBytes,
    format: im.Format.uint8,
    numChannels: 4,
  );
  return Uint8List.fromList(im.PngEncoder().encode(image));
}

Uint8List _encodeRgbaToPngIsolate(List<Object> args) {
  final width = args[0] as int;
  final height = args[1] as int;
  final pixels = args[2] as Uint8List;
  return encodeRgbaToPngSync(width: width, height: height, pixels: pixels);
}
