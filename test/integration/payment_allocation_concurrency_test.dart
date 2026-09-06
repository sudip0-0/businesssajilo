import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:businesssajilo/core/config/env.dart';
import 'package:businesssajilo/data/remote/supabase_bills_repository.dart';
import 'package:businesssajilo/data/remote/supabase_members_repository.dart';
import 'package:businesssajilo/data/remote/supabase_payments_repository.dart';
import 'package:businesssajilo/data/remote/supabase_products_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../support/hardening_gate.dart';

const _container = String.fromEnvironment(
  'LOCAL_DB_CONTAINER',
  defaultValue: 'supabase_db_businesssajilo',
);

Future<String> _sql(String sql) async {
  final result = await Process.run('docker', [
    'exec',
    _container,
    'psql',
    '-U',
    'postgres',
    '-d',
    'postgres',
    '-At',
    '-v',
    'ON_ERROR_STOP=1',
    '-c',
    sql,
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return result.stdout.toString().trim();
}

Future<List<Map<String, dynamic>>> _overlap(
  String billId,
  List<Future<Map<String, dynamic>> Function()> requests,
) async {
  final lock = await Process.start('docker', [
    'exec',
    '-i',
    _container,
    'psql',
    '-U',
    'postgres',
    '-d',
    'postgres',
    '-At',
    '-v',
    'ON_ERROR_STOP=1',
  ]);
  final ready = Completer<void>();
  final output = <String>[];
  final stdout = lock.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        output.add(line);
        if (line == 'allocation_lock_ready' && !ready.isCompleted) {
          ready.complete();
        }
      });
  final stderr = lock.stderr.transform(utf8.decoder).join();
  Future<List<Map<String, dynamic>>>? pending;
  try {
    lock.stdin.writeln('begin;');
    lock.stdin.writeln(
      "set local idle_in_transaction_session_timeout = '20s';",
    );
    lock.stdin.writeln("select id from bills where id='$billId' for update;");
    lock.stdin.writeln(r'\echo allocation_lock_ready');
    await lock.stdin.flush();
    await ready.future.timeout(const Duration(seconds: 10));
    expect(output, contains(billId), reason: 'Lock only the new test bill');
    pending = Future.wait(requests.map((request) => request()));
    var waitingSessions = 0;
    for (var attempt = 0; attempt < 40; attempt++) {
      waitingSessions = int.parse(
        await _sql(
          "select count(distinct pid) from pg_stat_activity "
          "where datname=current_database() and usename='authenticator' "
          "and wait_event_type='Lock' and query like '%record_payment%';",
        ),
      );
      if (waitingSessions >= 2) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(
      waitingSessions,
      greaterThanOrEqualTo(2),
      reason: 'Two real PostgREST database sessions must overlap behind locks',
    );
  } finally {
    lock.stdin.writeln('commit;');
    lock.stdin.writeln(r'\q');
    await lock.stdin.close();
    expect(await lock.exitCode.timeout(const Duration(seconds: 10)), 0);
    await stdout.cancel();
    expect(await stderr, isEmpty);
  }
  return pending;
}

void main() {
  test(
    'separate HTTP sessions allocate net dues and replay split receipts once',
    () async {
      requireForHardeningGate(
        Env.isConfigured,
        'Concurrency integration requires local Supabase, Docker and create-member',
      );
      if (!Env.isConfigured) return;
      expect(
        Uri.parse(Env.supabaseUrl).host,
        isIn(['127.0.0.1', 'localhost', '::1']),
        reason:
            'This test creates retained fixtures and refuses remote servers',
      );
      final owner = SupabaseClient(
        Env.supabaseUrl,
        Env.supabaseAnonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final sales = SupabaseClient(
        Env.supabaseUrl,
        Env.supabaseAnonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(owner.dispose);
      addTearDown(sales.dispose);
      await owner.auth.signInWithPassword(
        email: const String.fromEnvironment(
          'E2E_EMAIL',
          defaultValue: 'e2e-owner@test.com',
        ),
        password: const String.fromEnvironment(
          'E2E_PASSWORD',
          defaultValue: 'password123',
        ),
      );
      const uuid = Uuid();
      final suffix = uuid.v4();
      final members = SupabaseMembersRepository(owner);
      final customer = await members.createMember(
        email: 'allocation-customer-$suffix@test.invalid',
        password: uuid.v4(),
        role: Role.customer,
        displayName: 'Allocation concurrency customer',
        shopName: 'Allocation concurrency $suffix',
      );
      final salesEmail = 'allocation-sales-$suffix@test.invalid';
      final salesPassword = uuid.v4();
      await members.createMember(
        email: salesEmail,
        password: salesPassword,
        role: Role.sales,
        displayName: 'Allocation concurrency sales',
      );
      await sales.auth.signInWithPassword(
        email: salesEmail,
        password: salesPassword,
      );
      expect(sales.auth.currentUser!.id, isNot(owner.auth.currentUser!.id));
      expect(
        sales.auth.currentSession!.accessToken,
        isNot(owner.auth.currentSession!.accessToken),
      );
      final product = await SupabaseProductsRepository(owner).create(
        name: 'Allocation concurrency $suffix',
        unit: 'piece',
        costPrice: 50,
        referencePrice: 100,
        lowStockThreshold: 0,
      );
      Future<String> bill(int qty) async {
        final id = uuid.v4();
        final response = await owner.rpc(
          'create_bill',
          params: {
            'p': {
              'id': id,
              'customer_id': customer.customerId!,
              'items': [
                {
                  'product_id': product.id,
                  'name_snapshot': product.name,
                  'qty': qty,
                  'rate': 100,
                  'discount': 0,
                },
              ],
            },
          },
        );
        expect(response['created'], true);
        return id;
      }

      Future<void> credit(String id, int qty) async {
        final item = await owner
            .from('bill_items')
            .select('id,business_id')
            .eq('bill_id', id)
            .single();
        expect(item['business_id'], isNotNull);
        await owner.rpc(
          'create_credit_note',
          params: {
            'p': {
              'id': uuid.v4(),
              'bill_id': id,
              'restock': false,
              'items': [
                {
                  'bill_item_id': item['id'],
                  'qty_returned': qty,
                  'rate': 100,
                  'discount': 0,
                },
              ],
            },
          },
        );
      }

      Future<Map<String, dynamic>> pay(
        SupabaseClient client,
        String id,
        int amount, {
        String? billId,
        required String reference,
      }) async => Map<String, dynamic>.from(
        await client.rpc(
              'record_payment',
              params: {
                'p': {
                  'id': id,
                  'customer_id': customer.customerId!,
                  'bill_id': billId,
                  'amount': amount,
                  'method': 'cash',
                  'allocate': billId == null ? 'oldest_first' : '',
                  'ref_note': reference,
                },
              },
            )
            as Map,
      );

      Future<int> allocated(String id) async {
        final payments = await owner
            .from('payments')
            .select('amount')
            .eq('bill_id', id);
        return payments.fold<int>(
          0,
          (sum, row) => sum + (row['amount'] as int),
        );
      }

      final first = await bill(10);
      final second = await bill(10);
      await credit(first, 2);
      await pay(
        owner,
        uuid.v4(),
        100,
        billId: first,
        reference: 'prior-$suffix',
      );
      final results = await _overlap(first, [
        () => pay(owner, uuid.v4(), 1000, reference: 'owner-$suffix'),
        () => pay(sales, uuid.v4(), 1000, reference: 'sales-$suffix'),
      ]);
      expect(results.map((result) => result['created']), everyElement(true));
      expect(await allocated(first), 800);
      expect(await allocated(second), 1000);
      for (final ref in ['owner-$suffix', 'sales-$suffix']) {
        final receipts = await owner
            .from('payments')
            .select('amount')
            .eq('ref_note', ref);
        expect(
          receipts.fold<int>(0, (sum, row) => sum + (row['amount'] as int)),
          1000,
        );
      }
      final accountCredit = await owner
          .from('payments')
          .select('amount')
          .eq('customer_id', customer.customerId!)
          .isFilter('bill_id', null);
      expect(
        accountCredit.fold<int>(0, (sum, row) => sum + (row['amount'] as int)),
        300,
      );
      final bills = SupabaseBillsRepository(
        owner,
        SupabasePaymentsRepository(owner),
      );
      expect((await bills.get(first)).status, BillStatus.paid);
      expect((await bills.get(second)).status, BillStatus.paid);
      expect((await bills.get(first)).items.single.nameSnapshot, product.name);

      final third = await bill(6);
      final fourth = await bill(6);
      await credit(third, 2);
      final replayId = uuid.v4();
      final replayRef = 'same-id-$suffix';
      final replay = await _overlap(third, [
        () => pay(owner, replayId, 1200, reference: replayRef),
        () => pay(sales, replayId, 1200, reference: replayRef),
      ]);
      expect(replay.where((result) => result['created'] == true), hasLength(1));
      expect(
        replay.where((result) => result['created'] == false),
        hasLength(1),
      );
      expect(replay[0]['payment'], replay[1]['payment']);
      expect(await allocated(third), 400);
      expect(await allocated(fourth), 600);
      final split = await owner
          .from('payments')
          .select('id,bill_id,amount')
          .eq('ref_note', replayRef);
      expect(split, hasLength(3));
      expect(
        split.fold<int>(0, (sum, row) => sum + (row['amount'] as int)),
        1200,
      );
      expect(split.singleWhere((row) => row['bill_id'] == null)['amount'], 200);
      expect((await bills.get(third)).status, BillStatus.paid);
      expect((await bills.get(fourth)).status, BillStatus.paid);
      await pay(
        owner,
        uuid.v4(),
        5000,
        billId: third,
        reference: 'whole-$suffix',
      );
      expect(await allocated(third), 5400);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
