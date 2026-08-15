import 'dart:typed_data';

import 'package:businesssajilo/core/invoicing/pdf_raster_isolate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodeRgbaToPngSync produces PNG signature for 1x1 pixel', () {
    final pixels = Uint8List.fromList([255, 0, 0, 255]);
    final png = encodeRgbaToPngSync(width: 1, height: 1, pixels: pixels);
    expect(png, isNotEmpty);
    // PNG magic bytes
    expect(png[0], 0x89);
    expect(png[1], 0x50); // P
    expect(png[2], 0x4E); // N
    expect(png[3], 0x47); // G
  });

  test('encodeRgbaToPng via compute returns non-empty PNG', () async {
    final pixels = Uint8List.fromList([0, 255, 0, 255]);
    final png = await encodeRgbaToPng(width: 1, height: 1, pixels: pixels);
    expect(png.length, greaterThan(20));
    expect(png[0], 0x89);
  });

  test('flattenRgbaOntoWhite turns transparent pixels white', () {
    final pixels = Uint8List.fromList([
      0, 0, 0, 0, // transparent black (Android PDF backdrop)
      10, 10, 10, 255, // opaque near-black text
      120, 120, 120, 128, // semi-transparent grey
    ]);
    final flat = flattenRgbaOntoWhite(pixels);
    expect(flat.sublist(0, 4), [255, 255, 255, 255]);
    expect(flat.sublist(4, 8), [10, 10, 10, 255]);
    expect(flat[8], greaterThan(120));
    expect(flat[11], 255);
  });
}
