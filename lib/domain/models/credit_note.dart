class CreditNoteItem {
  const CreditNoteItem({
    required this.id,
    required this.creditNoteId,
    required this.billItemId,
    required this.productId,
    required this.nameSnapshot,
    required this.qtyReturned,
    required this.rate,
    required this.discount,
    required this.lineTotal,
  });

  factory CreditNoteItem.fromJson(Map<String, dynamic> json) {
    return CreditNoteItem(
      id: json['id'] as String,
      creditNoteId: json['credit_note_id'] as String,
      billItemId: json['bill_item_id'] as String,
      productId: json['product_id'] as String,
      nameSnapshot: json['name_snapshot'] as String,
      qtyReturned: (json['qty_returned'] as num).toInt(),
      rate: (json['rate'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String creditNoteId;
  final String billItemId;
  final String productId;
  final String nameSnapshot;
  final int qtyReturned;
  final int rate;
  final int discount;
  final int lineTotal;
}

class CreditNote {
  const CreditNote({
    required this.id,
    required this.businessId,
    required this.billId,
    required this.customerId,
    required this.creditNo,
    required this.itemsTotal,
    required this.discount,
    required this.grandTotal,
    required this.restock,
    this.reason,
    required this.createdBy,
    this.createdAt,
    this.items = const [],
  });

  factory CreditNote.fromJson(Map<String, dynamic> json) {
    return CreditNote(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      billId: json['bill_id'] as String,
      customerId: json['customer_id'] as String,
      creditNo: json['credit_no'] as String,
      itemsTotal: (json['items_total'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      grandTotal: (json['grand_total'] as num?)?.toInt() ?? 0,
      restock: json['restock'] as bool? ?? true,
      reason: json['reason'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  final String id;
  final String businessId;
  final String billId;
  final String customerId;
  final String creditNo;
  final int itemsTotal;
  final int discount;
  final int grandTotal;
  final bool restock;
  final String? reason;
  final String createdBy;
  final DateTime? createdAt;
  final List<CreditNoteItem> items;

  CreditNote copyWithItems(List<CreditNoteItem> items) {
    return CreditNote(
      id: id,
      businessId: businessId,
      billId: billId,
      customerId: customerId,
      creditNo: creditNo,
      itemsTotal: itemsTotal,
      discount: discount,
      grandTotal: grandTotal,
      restock: restock,
      reason: reason,
      createdBy: createdBy,
      createdAt: createdAt,
      items: items,
    );
  }
}

class CreditNoteLineInput {
  const CreditNoteLineInput({
    required this.billItemId,
    required this.qtyReturned,
    required this.rate,
    required this.discount,
  });

  final String billItemId;
  final int qtyReturned;
  final int rate;
  final int discount;
}

class BillItemReturnSummary {
  const BillItemReturnSummary({
    required this.billItemId,
    required this.returnedQty,
  });

  factory BillItemReturnSummary.fromJson(Map<String, dynamic> json) {
    return BillItemReturnSummary(
      billItemId: json['bill_item_id'] as String,
      returnedQty: (json['returned_qty'] as num?)?.toInt() ?? 0,
    );
  }

  final String billItemId;
  final int returnedQty;
}
