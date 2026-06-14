import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'csv_writer.dart';

class ExportShareService {
  const ExportShareService({CsvWriter? csvWriter})
      : _csvWriter = csvWriter ?? const CsvWriter();

  final CsvWriter _csvWriter;

  Future<void> shareCsv({
    required String filename,
    required List<List<String>> rows,
    String? subject,
  }) async {
    final csv = _csvWriter.build(rows);
    final bytes = Uint8List.fromList(_csvWriter.encodeUtf8(csv));
    await Share.shareXFiles(
      [XFile.fromData(bytes, name: filename, mimeType: 'text/csv')],
      subject: subject,
    );
  }
}

final exportShareServiceProvider =
    Provider<ExportShareService>((ref) => const ExportShareService());
