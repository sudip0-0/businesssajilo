import 'package:businesssajilo/data/local/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generates provisional D-prefix bill numbers', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureDeviceMeta('device-abc');

    final first = await db.nextProvisionalBillNo();
    final second = await db.nextProvisionalBillNo();

    expect(first, matches(RegExp(r'^D\d+-\d+$')));
    expect(second, matches(RegExp(r'^D\d+-\d+$')));
    expect(first, isNot(second));

    final meta = await db.select(db.deviceMeta).getSingle();
    expect(meta.localBillSeq, 2);
    await db.close();
  });
}
