import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/quote.dart';
import 'package:businesssajilo/domain/models/quote_item.dart';
import 'package:businesssajilo/features/billing/create_bill_from_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('billFromOrderDraftFromQuote maps items and recomputes totals', () {
    final quote = Quote(
      id: 'q1',
      orderId: 'o1',
      version: 1,
      status: QuoteStatus.accepted,
      total: 99999, // intentionally wrong — draft recomputes from lines
      createdBy: 'm1',
      items: [
        const QuoteItem(
          id: 'qi1',
          quoteId: 'q1',
          productId: 'p1',
          qty: 2,
          rate: 5000,
          discount: 500,
          lineTotal: 9500,
          productName: 'Rice',
        ),
        const QuoteItem(
          id: 'qi2',
          quoteId: 'q1',
          productId: 'p2',
          qty: 1,
          rate: 3000,
          discount: 0,
          lineTotal: 3000,
          productName: null,
        ),
      ],
    );

    final draft = billFromOrderDraftFromQuote(quote);

    expect(draft.lines, hasLength(2));
    expect(draft.lines[0].productId, 'p1');
    expect(draft.lines[0].nameSnapshot, 'Rice');
    expect(draft.lines[0].qty, 2);
    expect(draft.lines[0].rate, 5000);
    expect(draft.lines[0].discount, 500);
    expect(draft.lines[0].lineTotal, 9500);

    expect(draft.lines[1].nameSnapshot, '—');
    expect(draft.itemsTotal, 12500);
    expect(draft.discount, 0);
    expect(draft.grandTotal, 12500);
    expect(draft.isEmpty, isFalse);
  });

  test('empty quote yields empty draft', () {
    final quote = Quote(
      id: 'q1',
      orderId: 'o1',
      version: 1,
      status: QuoteStatus.accepted,
      createdBy: 'm1',
    );
    final draft = billFromOrderDraftFromQuote(quote);
    expect(draft.lines, isEmpty);
    expect(draft.itemsTotal, 0);
    expect(draft.isEmpty, isTrue);
  });
}
