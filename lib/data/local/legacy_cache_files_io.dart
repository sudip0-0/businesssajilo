import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'legacy_cache_files.dart' show LegacyCacheSnapshot;

Future<bool> legacyCacheExists(String path) => File(path).exists();

Future<void> withLegacySnapshot(
  String path,
  Future<void> Function(LegacyCacheSnapshot) use,
) async {
  final source = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    source.execute('PRAGMA busy_timeout = 1000');
    source.execute('PRAGMA query_only = ON');
    source.execute('BEGIN');
    try {
      source.select('SELECT name FROM sqlite_master LIMIT 1');
      await use(_SqliteLegacyCacheSnapshot(source));
    } finally {
      source.execute('ROLLBACK');
    }
  } finally {
    source.close();
  }
}

final class _SqliteLegacyCacheSnapshot implements LegacyCacheSnapshot {
  _SqliteLegacyCacheSnapshot(this._source);

  final Database _source;

  @override
  List<Map<String, dynamic>> select(
    String sql, [
    List<Object?> parameters = const [],
  ]) => _source
      .select(sql, parameters)
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
}
