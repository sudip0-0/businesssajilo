import 'dart:convert';

import 'package:businesssajilo/core/errors/app_failure.dart';
import 'package:businesssajilo/data/remote/supabase_bills_repository.dart';
import 'package:businesssajilo/data/remote/supabase_orders_repository.dart';
import 'package:businesssajilo/data/remote/supabase_payments_repository.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/data/repositories/payments_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/payment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Captures outbound request URLs/bodies for assertions.
class _Capture {
  final paths = <String>[];
  final bodies = <String?>[];
  final headers = <Map<String, String>>[];
}

http.Response _json(
  http.BaseRequest request,
  Object body, {
  int status = 200,
  Map<String, String>? headers,
}) {
  return http.Response(
    body is String ? body : jsonEncode(body),
    status,
    headers: {'content-type': 'application/json', ...?headers},
    request: request,
  );
}

SupabaseClient _client(MockClient mock) =>
    SupabaseClient('http://localhost', 'anon-key', httpClient: mock);

void main() {
  group('SupabasePaymentsRepository', () {
    test('totalDues calls total_dues RPC and maps int', () async {
      final capture = _Capture();
      final client = _client(
        MockClient((request) async {
          capture.paths.add(request.url.path);
          capture.bodies.add(request.body);
          return _json(request, 1500);
        }),
      );
      final repo = SupabasePaymentsRepository(client);
      expect(await repo.totalDues(), 1500);
      expect(capture.paths.single, contains('/rest/v1/rpc/total_dues'));
    });

    test('listByCustomer paginates via Range or offset/limit', () async {
      final capture = _Capture();
      late Uri requestUri;
      late Map<String, String> requestHeaders;
      final client = _client(
        MockClient((request) async {
          capture.paths.add(request.url.path);
          requestUri = request.url;
          requestHeaders = request.headers;
          final row = {
            'id': 'pay-1',
            'business_id': 'biz',
            'customer_id': 'cust-1',
            'amount': 100,
            'method': 'cash',
            'received_by': 'member-1',
          };
          return _json(request, [row]);
        }),
      );
      final repo = SupabasePaymentsRepository(client);
      final rows = await repo.listByCustomer('cust-1', offset: 10, limit: 5);
      expect(rows, hasLength(1));
      expect(rows.single.id, 'pay-1');
      expect(capture.paths.single, contains('/rest/v1/payments'));
      final range = requestHeaders['Range'] ?? requestHeaders['range'];
      final query = requestUri.query;
      final paged =
          range == '10-14' ||
          (query.contains('offset=10') && query.contains('limit=5'));
      expect(paged, isTrue, reason: 'headers=$requestHeaders query=$query');
    });

    test('totalDues maps permission failures via AppFailure', () async {
      final client = _client(
        MockClient((request) async {
          return _json(request, {
            'message': 'permission denied',
            'code': '42501',
          }, status: 403);
        }),
      );
      final repo = SupabasePaymentsRepository(client);
      try {
        await repo.totalDues();
        fail('expected exception');
      } catch (e) {
        final failure = AppFailure.from(e);
        expect(failure, isA<AppFailurePermission>());
      }
    });
  });

  group('SupabaseBillsRepository', () {
    test('get maps customer join and bill fields', () async {
      final capture = _Capture();
      final client = _client(
        MockClient((request) async {
          capture.paths.add(request.url.path);
          return _json(request, {
            'id': 'bill-1',
            'business_id': 'biz',
            'bill_no': 'BS-0001',
            'status': 'paid',
            'created_by': 'member-1',
            'items_total': 500,
            'discount': 0,
            'grand_total': 500,
            'customers': {'shop_name': 'Ram Store'},
            'bill_items': [
              {
                'id': 'item-1',
                'bill_id': 'bill-1',
                'product_id': 'prod-1',
                'name_snapshot': 'Cola',
                'qty': 1,
                'rate': 500,
                'discount': 0,
                'line_total': 500,
              },
            ],
          });
        }),
      );
      final repo = SupabaseBillsRepository(client, _UnusedPayments());
      final bill = await repo.get('bill-1');
      expect(bill.billNo, 'BS-0001');
      expect(bill.customerShopName, 'Ram Store');
      expect(bill.items, hasLength(1));
      expect(capture.paths.single, contains('/rest/v1/bills'));
    });

    test('create posts create_bill RPC payload with items', () async {
      final capture = _Capture();
      var call = 0;
      final client = _client(
        MockClient((request) async {
          capture.paths.add(request.url.path);
          capture.bodies.add(request.body);
          call++;
          if (request.url.path.contains('create_bill')) {
            return _json(request, {
              'bill': {
                'id': 'bill-new',
                'business_id': 'biz',
                'bill_no': 'BS-0002',
                'status': 'due',
                'created_by': 'member-1',
                'items_total': 1000,
                'discount': 0,
                'grand_total': 1000,
              },
              'created': true,
            });
          }
          // Follow-up get() after create.
          return _json(request, {
            'id': 'bill-new',
            'business_id': 'biz',
            'bill_no': 'BS-0002',
            'status': 'due',
            'created_by': 'member-1',
            'items_total': 1000,
            'discount': 0,
            'grand_total': 1000,
            'customers': null,
            'bill_items': [],
          });
        }),
      );
      final repo = SupabaseBillsRepository(client, _UnusedPayments());
      final bill = await repo.create(
        createdByMemberId: 'member-1',
        status: BillStatus.due,
        itemsTotal: 1000,
        discount: 0,
        grandTotal: 1000,
        lines: const [
          BillLineInput(
            productId: 'prod-1',
            nameSnapshot: 'Cola',
            qty: 2,
            rate: 500,
            lineTotal: 1000,
          ),
        ],
      );
      expect(bill.billNo, 'BS-0002');
      expect(capture.paths.first, contains('/rest/v1/rpc/create_bill'));
      final rpcBody = jsonDecode(capture.bodies.first!) as Map;
      final payload = rpcBody['p'] as Map;
      expect(payload['status'], 'due');
      expect(payload['items'], isA<List>());
      expect((payload['items'] as List).single['qty'], 2);
      expect(call, greaterThanOrEqualTo(2));
    });
  });

  group('SupabaseOrdersRepository', () {
    test('listForStaff maps customer shop name and filters status', () async {
      final capture = _Capture();
      final client = _client(
        MockClient((request) async {
          capture.paths.add(request.url.path);
          capture.bodies.add(request.url.query);
          return _json(request, [
            {
              'id': 'ord-1',
              'business_id': 'biz',
              'customer_id': 'cust-1',
              'status': 'placed',
              'customers': {'shop_name': 'Shop A'},
              'order_items': [
                {'id': 'oi-1'},
              ],
            },
          ]);
        }),
      );
      final repo = SupabaseOrdersRepository(client);
      final orders = await repo.listForStaff(
        statuses: [OrderStatus.placed],
        offset: 0,
        limit: 10,
      );
      expect(orders, hasLength(1));
      expect(orders.single.customerShopName, 'Shop A');
      expect(capture.paths.single, contains('/rest/v1/orders'));
      expect(capture.bodies.single, contains('status'));
      expect(capture.bodies.single, contains('placed'));
    });

    test('pendingCount hits orders with count prefer header', () async {
      final capture = _Capture();
      final client = _client(
        MockClient((request) async {
          capture.headers.add(request.headers);
          capture.paths.add(request.url.path);
          return _json(request, [], headers: {'content-range': '0-0/3'});
        }),
      );
      final repo = SupabaseOrdersRepository(client);
      final count = await repo.pendingCount();
      expect(count, 3);
      expect(capture.paths.single, contains('/rest/v1/orders'));
      expect(capture.headers.single['Prefer'], contains('count=exact'));
    });
  });
}

class _UnusedPayments implements PaymentsRepository {
  @override
  Future<List<Payment>> listByCustomer(
    String customerId, {
    int offset = 0,
    int limit = 50,
  }) async => const [];

  @override
  Future<Payment> record({
    String? id,
    required String customerId,
    required int amount,
    required PaymentMethod method,
    String? refNote,
    String? billId,
    required String receivedByMemberId,
    bool enqueueRemote = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> totalDues() async => 0;
}
