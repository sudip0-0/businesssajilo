import 'package:businesssajilo/data/repositories/bills_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:businesssajilo/domain/models/bill_item.dart';
import 'package:businesssajilo/features/billing/copy_last_bill.dart';
import 'package:flutter_test/flutter_test.dart';

class _ListGetBills implements BillsRepository {
  _ListGetBills({required this.listed, this.detailed});

  final List<Bill> listed;
  final Bill? detailed;
  var getCalls = 0;

  @override
  Future<List<Bill>> list({
    int offset = 0,
    int? limit,
    BillStatus? status,
  }) async => listed;

  @override
  Future<Bill> get(String id) async {
    getCalls++;
    return detailed ?? (throw StateError('missing $id'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Bill _bill({required String id, List<BillItem> items = const []}) {
  return Bill(
    id: id,
    businessId: 'biz',
    billNo: 'BS-0001',
    createdBy: 'm1',
    status: BillStatus.due,
    items: items,
  );
}

void main() {
  test(
    'fetchLatestBillWithItems returns null when there are no bills',
    () async {
      final repo = _ListGetBills(listed: const []);
      expect(await fetchLatestBillWithItems(repo), isNull);
      expect(repo.getCalls, 0);
    },
  );

  test('fetchLatestBillWithItems uses list when items are present', () async {
    final withItems = _bill(
      id: 'b1',
      items: const [
        BillItem(
          id: 'i1',
          billId: 'b1',
          productId: 'p1',
          nameSnapshot: 'Rice',
          qty: 1,
        ),
      ],
    );
    final repo = _ListGetBills(listed: [withItems]);
    expect(await fetchLatestBillWithItems(repo), withItems);
    expect(repo.getCalls, 0);
  });

  test('fetchLatestBillWithItems loads get() when list omits items', () async {
    final header = _bill(id: 'b1');
    final detailed = _bill(
      id: 'b1',
      items: const [
        BillItem(
          id: 'i1',
          billId: 'b1',
          productId: 'p1',
          nameSnapshot: 'Rice',
          qty: 2,
        ),
      ],
    );
    final repo = _ListGetBills(listed: [header], detailed: detailed);
    final result = await fetchLatestBillWithItems(repo);
    expect(repo.getCalls, 1);
    expect(result!.items, hasLength(1));
    expect(result.items.single.qty, 2);
  });
}
