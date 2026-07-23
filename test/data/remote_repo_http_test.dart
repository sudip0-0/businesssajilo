import 'dart:convert';

import 'package:businesssajilo/core/errors/app_failure.dart';
import 'package:businesssajilo/data/remote/supabase_bills_repository.dart';
import 'package:businesssajilo/data/remote/supabase_categories_repository.dart';
import 'package:businesssajilo/data/remote/supabase_credit_notes_repository.dart';
import 'package:businesssajilo/data/remote/supabase_customers_repository.dart';
import 'package:businesssajilo/data/remote/supabase_members_repository.dart';
import 'package:businesssajilo/data/remote/supabase_orders_repository.dart';
import 'package:businesssajilo/data/remote/supabase_payments_repository.dart';
import 'package:businesssajilo/data/remote/supabase_products_repository.dart';
import 'package:businesssajilo/data/remote/supabase_reports_repository.dart';
import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/data/repositories/payments_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/credit_note.dart';
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

    test('record posts record_payment RPC payload', () async {
      final capture = _Capture();
      final client = _client(
        MockClient((request) async {
          capture.paths.add(request.url.path);
          capture.bodies.add(request.body);
          return _json(request, {
            'payment': {
              'id': 'pay-new',
              'business_id': 'biz',
              'customer_id': 'cust-1',
              'bill_id': 'bill-1',
              'amount': 500,
              'method': 'cash',
              'received_by': 'member-1',
            },
          });
        }),
      );
      final repo = SupabasePaymentsRepository(client);
      final payment = await repo.record(
        customerId: 'cust-1',
        amount: 500,
        method: PaymentMethod.cash,
        billId: 'bill-1',
        receivedByMemberId: 'member-1',
      );
      expect(payment.amount, 500);
      expect(capture.paths.single, contains('/rest/v1/rpc/record_payment'));
      final rpcBody = jsonDecode(capture.bodies.single!) as Map;
      final payload = rpcBody['p'] as Map;
      expect(payload['customer_id'], 'cust-1');
      expect(payload['bill_id'], 'bill-1');
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

    test('create_bill idempotent replay maps existing bill', () async {
      var call = 0;
      final client = _client(
        MockClient((request) async {
          call++;
          if (request.url.path.contains('create_bill')) {
            return _json(request, {
              'bill': {
                'id': 'bill-replay',
                'business_id': 'biz',
                'bill_no': 'BS-0099',
                'status': 'due',
                'created_by': 'member-1',
                'items_total': 1000,
                'discount': 0,
                'grand_total': 1000,
              },
              'created': false,
            });
          }
          return _json(request, {
            'id': 'bill-replay',
            'business_id': 'biz',
            'bill_no': 'BS-0099',
            'status': 'due',
            'created_by': 'member-1',
            'items_total': 1000,
            'discount': 0,
            'grand_total': 1000,
            'customers': {'shop_name': 'Replay Shop'},
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
      expect(bill.billNo, 'BS-0099');
      expect(bill.customerShopName, 'Replay Shop');
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

  group('SupabaseProductsRepository', () {
    test('lowStockCount calls low_stock_count RPC', () async {
      final capture = _Capture();
      final client = _client(
        MockClient((request) async {
          capture.paths.add(request.url.path);
          return _json(request, 3);
        }),
      );
      final repo = SupabaseProductsRepository(client);
      expect(await repo.lowStockCount(), 3);
      expect(capture.paths.single, contains('/rest/v1/rpc/low_stock_count'));
    });

    test('listLowStock maps RPC rows to products', () async {
      final client = _client(
        MockClient((request) async {
          return _json(request, [
            {
              'id': 'prod-low',
              'business_id': 'biz',
              'name': 'Low Widget',
              'unit': 'piece',
              'stock_cached': 1,
              'low_stock_threshold': 5,
              'is_active': true,
            },
          ]);
        }),
      );
      final repo = SupabaseProductsRepository(client);
      final rows = await repo.listLowStock(limit: 2);
      expect(rows, hasLength(1));
      expect(rows.single.name, 'Low Widget');
    });
  });

  group('SupabaseReportsRepository', () {
    test('ownerDashboardStats maps RPC KPI fields', () async {
      final client = _client(
        MockClient((request) async {
          return _json(request, {
            'today_sales': 12000,
            'yesterday_sales': 8000,
            'total_dues': 45000,
            'low_stock_count': 2,
            'pending_orders': 5,
          });
        }),
      );
      final repo = SupabaseReportsRepository(client);
      final stats = await repo.ownerDashboardStats();
      expect(stats.todaySales, 12000);
      expect(stats.totalDues, 45000);
      expect(stats.lowStockCount, 2);
      expect(stats.pendingOrders, 5);
    });

    test('duesAging maps bucket totals and customer rows', () async {
      final client = _client(
        MockClient((request) async {
          return _json(request, {
            'bucket_0_30': 1000,
            'bucket_31_60': 500,
            'bucket_60_plus': 200,
            'customers': [
              {
                'customer_id': 'cust-1',
                'shop_name': 'Due Shop',
                'balance_due': 700,
                'oldest_due_at': '2026-01-01T00:00:00Z',
                'age_days': 45,
                'bucket': '31-60',
              },
            ],
          });
        }),
      );
      final repo = SupabaseReportsRepository(client);
      final report = await repo.duesAging();
      expect(report.bucket0to30, 1000);
      expect(report.bucket31to60, 500);
      expect(report.customers, hasLength(1));
      expect(report.customers.single.shopName, 'Due Shop');
      expect(report.customers.single.bucket, '31-60');
    });
  });

  group('SupabaseCustomersRepository', () {
    test('list maps customer_balances rows with balance_due', () async {
      final client = _client(
        MockClient((request) async {
          return _json(request, [
            {
              'customer_id': 'cust-1',
              'business_id': 'biz',
              'member_id': 'mem-1',
              'shop_name': 'Ram Store',
              'contact_name': 'Ram',
              'phone': '+9779800000000',
              'opening_balance': 0,
              'balance_due': 1500,
              'created_at': '2026-01-01T00:00:00Z',
            },
          ]);
        }),
      );
      final repo = SupabaseCustomersRepository(client);
      final rows = await repo.list(limit: 10);
      expect(rows.single.shopName, 'Ram Store');
      expect(rows.single.balanceDue, 1500);
    });
  });

  group('SupabaseCategoriesRepository', () {
    test('list maps category rows', () async {
      final client = _client(
        MockClient((request) async {
          return _json(request, [
            {
              'id': 'cat-1',
              'business_id': 'biz',
              'name': 'Beverages',
              'name_np': 'पेय',
            },
          ]);
        }),
      );
      final repo = SupabaseCategoriesRepository(client);
      final rows = await repo.list();
      expect(rows.single.name, 'Beverages');
      expect(rows.single.nameNp, 'पेय');
    });
  });

  group('SupabaseMembersRepository', () {
    test('deactivateMember PATCHes is_active false', () async {
      final capture = _Capture();
      final client = _client(
        MockClient((request) async {
          capture.paths.add(request.url.path);
          capture.bodies.add(request.body);
          return _json(request, {});
        }),
      );
      final repo = SupabaseMembersRepository(client);
      await repo.deactivateMember('member-1');
      expect(capture.paths.single, contains('/rest/v1/members'));
      final body = jsonDecode(capture.bodies.single!) as Map;
      expect(body['is_active'], isFalse);
    });
  });

  group('SupabaseCreditNotesRepository', () {
    test('create maps create_credit_note RPC and item rows', () async {
      var call = 0;
      final client = _client(
        MockClient((request) async {
          call++;
          if (request.url.path.contains('create_credit_note')) {
            return _json(request, {
              'credit_note': {
                'id': 'cn-1',
                'business_id': 'biz',
                'bill_id': 'bill-1',
                'customer_id': 'cust-1',
                'credit_no': 'CN-0001',
                'items_total': 500,
                'discount': 0,
                'grand_total': 500,
                'restock': true,
                'created_by': 'member-1',
              },
            });
          }
          return _json(request, [
            {
              'id': 'cni-1',
              'credit_note_id': 'cn-1',
              'bill_item_id': 'bi-1',
              'product_id': 'prod-1',
              'name_snapshot': 'Cola',
              'qty_returned': 1,
              'rate': 500,
              'discount': 0,
              'line_total': 500,
            },
          ]);
        }),
      );
      final repo = SupabaseCreditNotesRepository(client);
      final note = await repo.create(
        billId: 'bill-1',
        createdByMemberId: 'member-1',
        restock: true,
        lines: const [
          CreditNoteLineInput(
            billItemId: 'bi-1',
            qtyReturned: 1,
            rate: 500,
            discount: 0,
          ),
        ],
      );
      expect(note.creditNo, 'CN-0001');
      expect(note.items, hasLength(1));
      expect(call, greaterThanOrEqualTo(2));
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
