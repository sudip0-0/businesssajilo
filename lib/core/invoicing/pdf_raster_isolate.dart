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
///
/// Android's PDF renderer starts from a transparent bitmap. Transparent
/// pixels flatten onto white so WhatsApp and other share targets do not
/// show a black page with only grey footer text.
Uint8List encodeRgbaToPngSync({
  required int width,
  required int height,
  required Uint8List pixels,
}) {
  final rgba = flattenRgbaOntoWhite(pixels);
  final image = im.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba.buffer,
    bytesOffset: rgba.offsetInBytes,
    format: im.Format.uint8,
    numChannels: 4,
  );
  return Uint8List.fromList(im.PngEncoder().encode(image));
}

/// Copies [pixels] and composites any transparent samples onto white.
@visibleForTesting
Uint8List flattenRgbaOntoWhite(Uint8List pixels) {
  final rgba = Uint8List.fromList(pixels);
  for (var i = 0; i < rgba.length; i += 4) {
    final alpha = rgba[i + 3];
    if (alpha == 255) continue;
    if (alpha == 0) {
      rgba[i] = 255;
      rgba[i + 1] = 255;
      rgba[i + 2] = 255;
      rgba[i + 3] = 255;
      continue;
    }
    final inv = 255 - alpha;
    rgba[i] = (rgba[i] * alpha + 255 * inv) ~/ 255;
    rgba[i + 1] = (rgba[i + 1] * alpha + 255 * inv) ~/ 255;
    rgba[i + 2] = (rgba[i + 2] * alpha + 255 * inv) ~/ 255;
    rgba[i + 3] = 255;
  }
  return rgba;
}

Uint8List _encodeRgbaToPngIsolate(List<Object> args) {
  final width = args[0] as int;
  final height = args[1] as int;
  final pixels = args[2] as Uint8List;
  return encodeRgbaToPngSync(width: width, height: height, pixels: pixels);
}
