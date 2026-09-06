abstract interface class LegacyCacheSnapshot {
  List<Map<String, dynamic>> select(
    String sql, [
    List<Object?> parameters = const [],
  ]);
}

Future<bool> legacyCacheExists(String path) async => false;

Future<void> withLegacySnapshot(
  String path,
  Future<void> Function(LegacyCacheSnapshot) use,
) async {}
