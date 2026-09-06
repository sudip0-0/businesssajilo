import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import 'app_database.dart';
import 'legacy_cache_files.dart'
    if (dart.library.io) 'legacy_cache_files_io.dart';

const legacyRecoveryNoticeKey = 'legacy_recovery_notice';

final _recoveries = <AppDatabase, Future<void>>{};

Future<void> waitForCacheRecovery(AppDatabase db) async {
  await _recoveries[db];
}

Future<void> recoverPreviousCaches({
  required AppDatabase db,
  required String businessId,
  required String memberId,
  required Role role,
}) {
  return _recoveries[db] ??= () async {
    try {
      final databases = await db.customSelect('PRAGMA database_list').get();
      final path =
          databases.where((r) => r.data['name'] == 'main').first.data['file']
              as String;
      if (path.isEmpty) return;
      final directory = path.replaceAll('\\', '/');
      final parent = directory.substring(0, directory.lastIndexOf('/') + 1);
      final names = [
        'businesssajilo_local',
        for (final previousRole in [Role.owner, Role.sales, Role.warehouse])
          if (previousRole != role)
            AppDatabase.scopedName(
              businessId: businessId,
              memberId: memberId,
              role: previousRole,
            ),
      ];
      for (final name in names) {
        final sourcePath = '$parent$name.sqlite';
        try {
          if (!await legacyCacheExists(sourcePath)) continue;
          await recoverLegacyCache(
            db: db,
            sourcePath: sourcePath,
            businessId: businessId,
            memberId: memberId,
            role: role,
          );
        } catch (_) {
          await db.setMetaValue(legacyRecoveryNoticeKey, 'retained');
        }
      }
    } finally {
      _recoveries.removeWhere((key, _) => identical(key, db));
    }
  }();
}

Future<void> recoverLegacyCache({
  required AppDatabase db,
  required String sourcePath,
  required String businessId,
  required String memberId,
  required Role role,
}) async {
  await withLegacySnapshot(sourcePath, (source) async {
    await db.transaction(() async {
      final tables = source
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((r) => r['name'] as String)
          .toSet();
      if (!tables.contains('sync_queue')) {
        await db.setMetaValue(legacyRecoveryNoticeKey, 'retained');
        return;
      }
      final queue = source.select(
        "SELECT * FROM sync_queue WHERE status IN ('pending', 'failed') ORDER BY created_at, id",
      );
      final pendingRecords = <String>[];
      final pendingEntityIds = <Object?>{};
      for (final entry in const {
        'local_bills': 'bill',
        'local_payments': 'payment',
        'local_stock_movements': 'stock_movement',
      }.entries) {
        if (!tables.contains(entry.key)) continue;
        final rows = source.select(
          "SELECT id FROM ${entry.key} WHERE sync_status IN ('pending', 'failed')",
        );
        for (final row in rows) {
          pendingEntityIds.add(row['id']);
          pendingRecords.add(
            'recovery:${jsonEncode([sourcePath, entry.value, row['id']])}',
          );
        }
      }
      if (queue.isEmpty && pendingRecords.isEmpty) return;
      var retained = false;
      final recovered = <String>{};
      final remaining = List<Map<String, dynamic>>.of(queue);
      final pendingIds = {
        ...pendingEntityIds,
        ...queue.map((q) => q['entity_id']),
      };
      final duplicateKeys = <String, int>{};
      for (final item in queue) {
        final key = jsonEncode([item['entity_type'], item['entity_id']]);
        duplicateKeys[key] = (duplicateKeys[key] ?? 0) + 1;
      }

      Future<Map<String, dynamic>?> row(String table, Object? id) async {
        if (id is! String || !tables.contains(table)) return null;
        final rows = source.select('SELECT * FROM $table WHERE id = ?', [id]);
        return rows.length == 1 ? rows.single : null;
      }

      bool owned(Map<String, dynamic>? value, String actor) =>
          value != null &&
          value['business_id'] == businessId &&
          value[actor] == memberId;

      bool payloadOwner(Map<String, dynamic> payload, String actor) =>
          (!payload.containsKey('business_id') ||
              payload['business_id'] == businessId) &&
          (!payload.containsKey(actor) || payload[actor] == memberId);

      Future<bool> insert(String table, Map<String, dynamic> value) async {
        final columns =
            (await db.customSelect('PRAGMA main.table_info($table)').get())
                .map((r) => r.read<String>('name'))
                .toSet();
        final keys = value.keys.where(columns.contains).toList();
        await db.customStatement(
          'INSERT OR IGNORE INTO main.$table (${keys.join(',')}) VALUES (${List.filled(keys.length, '?').join(',')})',
          keys.map((k) => value[k]).toList(),
        );
        final changed = await db
            .customSelect('SELECT changes() AS n')
            .getSingle();
        return changed.read<int>('n') != 0;
      }

      Future<void> identity(Object? id) async {
        final customer = await row('local_customers', id);
        if (customer == null || customer['business_id'] != businessId) return;
        await insert('local_customers', {
          ...customer,
          'opening_balance': 0,
          'balance_due': 0,
        });
      }

      Future<void> balance(Object? customerId, int delta) async {
        if (!role.canViewCustomerBalance ||
            customerId is! String ||
            delta == 0) {
          return;
        }
        await db.customStatement(
          'UPDATE local_customers SET balance_due = balance_due + ? WHERE id = ? AND business_id = ?',
          [delta, customerId, businessId],
        );
      }

      await db.transaction(() async {
        while (remaining.isNotEmpty) {
          var progressed = false;
          for (final item in List<Map<String, dynamic>>.of(remaining)) {
            final id = item['entity_id'];
            final type = item['entity_type'];
            if (id is! String || type is! String) continue;
            if (duplicateKeys[jsonEncode([type, id])] != 1) continue;
            final receipt = 'recovery:${jsonEncode([sourcePath, type, id])}';
            if (await db.metaValue(receipt) != null) {
              recovered.add(id);
              remaining.remove(item);
              progressed = true;
              continue;
            }
            final dependency = item['depends_on_id'];
            if (dependency != null &&
                pendingIds.contains(dependency) &&
                !recovered.contains(dependency)) {
              continue;
            }
            Map<String, dynamic> payload;
            try {
              payload = Map<String, dynamic>.from(
                jsonDecode(item['payload_json'] as String) as Map,
              );
            } catch (_) {
              continue;
            }
            if (payload['id'] != id) continue;
            final table = switch (type) {
              'bill' => 'local_bills',
              'payment' => 'local_payments',
              'stock_movement' => 'local_stock_movements',
              _ => null,
            };
            if (table == null) continue;
            final actor = type == 'payment' ? 'received_by' : 'created_by';
            final local = await row(table, id);
            if (!owned(local, actor) || !payloadOwner(payload, actor)) continue;
            if (!const ['pending', 'failed'].contains(local!['sync_status'])) {
              continue;
            }
            final existing = await db
                .customSelect(
                  'SELECT * FROM main.$table WHERE id = ?',
                  variables: [Variable<String>(id)],
                )
                .get();
            if (existing.isNotEmpty && !owned(existing.single.data, actor)) {
              continue;
            }
            if (existing.isNotEmpty &&
                existing.single.data['sync_status'] == 'synced') {
              await db.setMetaValue(receipt, 'already_synced');
              recovered.add(id);
              remaining.remove(item);
              progressed = true;
              continue;
            }
            final items = <Map<String, dynamic>>[];
            final mirrors = <Map<String, dynamic>>[];
            Map<String, dynamic>? payment;
            if (type == 'bill') {
              if (!const ['paid', 'partial', 'due'].contains(local['status']) ||
                  local['grand_total'] is! int ||
                  local['bill_no'] is! String ||
                  (local['bill_no'] as String).isEmpty) {
                continue;
              }
              if (role == Role.customer ||
                  local['order_id'] != null ||
                  payload['order_id'] != null) {
                continue;
              }
              if (payload['customer_id'] != local['customer_id']) continue;
              final manual = payload['manual_sale'] == true;
              if (role == Role.warehouse &&
                  (manual ||
                      payload['payment'] != null ||
                      local['status'] != 'due')) {
                continue;
              }
              if (manual) {
                if (payload['amount'] != local['grand_total']) continue;
              } else if (payload['status'] != local['status']) {
                continue;
              }
              if (!tables.contains('local_bill_items')) continue;
              items.addAll(
                source.select(
                  'SELECT * FROM local_bill_items WHERE bill_id = ?',
                  [id],
                ),
              );
              if (items.isEmpty ||
                  items.any(
                    (i) =>
                        i['qty'] is! int ||
                        (i['qty'] as int) <= 0 ||
                        i['rate'] is! int ||
                        i['discount'] is! int ||
                        i['line_total'] is! int ||
                        i['name_snapshot'] is! String,
                  )) {
                continue;
              }
              if (!manual) {
                final lines = payload['items'];
                if (lines is! List || lines.length != items.length) continue;
                final unmatched = List<Map<String, dynamic>>.of(items);
                var valid = true;
                for (final line in lines) {
                  if (line is! Map) {
                    valid = false;
                    break;
                  }
                  final index = unmatched.indexWhere(
                    (i) =>
                        (i['product_id'] == '' ? null : i['product_id']) ==
                            line['product_id'] &&
                        i['name_snapshot'] == line['name_snapshot'] &&
                        i['qty'] == line['qty'] &&
                        i['rate'] == line['rate'] &&
                        i['discount'] == (line['discount'] ?? 0),
                  );
                  if (index < 0) {
                    valid = false;
                    break;
                  }
                  unmatched.removeAt(index);
                }
                if (!valid) continue;
              }
              if (payload['payment'] != null) {
                final embedded = payload['payment'];
                if (embedded is! Map) continue;
                payment = await row('local_payments', embedded['id']);
                if (!owned(payment, 'received_by') ||
                    !payloadOwner(
                      Map<String, dynamic>.from(embedded),
                      'received_by',
                    ) ||
                    payment!['bill_id'] != id ||
                    payment['customer_id'] != local['customer_id'] ||
                    payment['amount'] is! int ||
                    (payment['amount'] as int) <= 0 ||
                    payment['amount'] != embedded['amount'] ||
                    !const [
                      'cash',
                      'cheque',
                      'wallet',
                      'bank',
                    ].contains(payment['method']) ||
                    payment['method'] != embedded['method']) {
                  continue;
                }
              }
              if (tables.contains('local_stock_movements')) {
                final columns = source
                    .select('PRAGMA table_info(local_stock_movements)')
                    .map((r) => r['name'] as String)
                    .toSet();
                if (columns.contains('ref_bill_id')) {
                  final sourceMirrors = source.select(
                    'SELECT * FROM local_stock_movements WHERE ref_bill_id = ?',
                    [id],
                  );
                  final unmatchedMirrors = List<Map<String, dynamic>>.of(items);
                  for (final mirror in sourceMirrors) {
                    final matching = unmatchedMirrors.indexWhere(
                      (i) =>
                          i['product_id'] == mirror['product_id'] &&
                          i['qty'] is int &&
                          -(i['qty'] as int) == mirror['qty_delta'],
                    );
                    if (owned(mirror, 'created_by') &&
                        mirror['type'] == 'dispatch' &&
                        const [
                          'pending',
                          'failed',
                        ].contains(mirror['sync_status']) &&
                        matching >= 0) {
                      unmatchedMirrors.removeAt(matching);
                      mirrors.add(mirror);
                    }
                  }
                }
              }
            } else if (type == 'payment') {
              if (!role.canViewCustomerBalance ||
                  local['amount'] is! int ||
                  (local['amount'] as int) <= 0 ||
                  !const [
                    'cash',
                    'cheque',
                    'wallet',
                    'bank',
                  ].contains(local['method']) ||
                  payload['customer_id'] != local['customer_id'] ||
                  payload['amount'] != local['amount'] ||
                  payload['method'] != local['method'] ||
                  payload['bill_id'] != local['bill_id']) {
                continue;
              }
              final billId = local['bill_id'];
              if (billId != null &&
                  pendingIds.contains(billId) &&
                  !recovered.contains(billId)) {
                continue;
              }
            } else {
              if ((role != Role.owner && role != Role.warehouse) ||
                  local['qty_delta'] is! int ||
                  (local['qty_delta'] as int) == 0 ||
                  payload['product_id'] != local['product_id'] ||
                  payload['type'] != local['type'] ||
                  payload['qty_delta'] != local['qty_delta'] ||
                  !const ['in', 'adjust'].contains(local['type'])) {
                continue;
              }
            }
            await identity(local['customer_id']);
            final inserted = await insert(table, local);
            if (inserted && type == 'bill') {
              await balance(local['customer_id'], local['grand_total'] as int);
            }
            if (inserted && type == 'payment') {
              await balance(local['customer_id'], -(local['amount'] as int));
            }
            for (final itemRow in items) {
              await insert('local_bill_items', itemRow);
            }
            for (final mirror in mirrors) {
              await insert('local_stock_movements', mirror);
              await db.setMetaValue(
                'recovery:${jsonEncode([sourcePath, 'stock_movement', mirror['id']])}',
                'copied_snapshot',
              );
            }
            if (payment != null && await insert('local_payments', payment)) {
              await balance(
                payment['customer_id'],
                -(payment['amount'] as int),
              );
            }
            if (payment != null) {
              await db.setMetaValue(
                'recovery:${jsonEncode([sourcePath, 'payment', payment['id']])}',
                'copied_snapshot',
              );
            }
            final existingQueue = await db
                .customSelect(
                  'SELECT id FROM sync_queue WHERE entity_type = ? AND entity_id = ?',
                  variables: [Variable<String>(type), Variable<String>(id)],
                )
                .get();
            if (existingQueue.isEmpty &&
                (existing.isEmpty ||
                    existing.single.data['sync_status'] != 'synced')) {
              await insert('sync_queue', {...item}..remove('id'));
            }
            await db.setMetaValue(receipt, 'copied');
            recovered.add(id);
            remaining.remove(item);
            progressed = true;
          }
          if (!progressed) break;
        }
        retained = remaining.isNotEmpty;
        for (final receipt in pendingRecords) {
          if (await db.metaValue(receipt) == null) retained = true;
        }
        final previous = await db.metaValue(legacyRecoveryNoticeKey);
        await db.setMetaValue(
          legacyRecoveryNoticeKey,
          retained || previous == 'retained' ? 'retained' : 'recovered',
        );
      });
    });
  });
}
