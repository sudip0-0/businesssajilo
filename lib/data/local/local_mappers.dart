import '../../domain/enums.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/bill_item.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/payment.dart';
import '../../domain/models/product.dart';
import '../../domain/models/stock_movement.dart';
import 'app_database.dart';

Bill mapLocalBill(LocalBill row, List<LocalBillItem> items) {
  return Bill(
    id: row.id,
    businessId: row.businessId,
    customerId: row.customerId,
    orderId: row.orderId,
    billNo: row.billNo,
    devicePrefix: row.devicePrefix,
    itemsTotal: row.itemsTotal,
    discount: row.discount,
    grandTotal: row.grandTotal,
    status: BillStatus.values.byName(row.status),
    createdBy: row.createdBy,
    createdAt: row.createdAt,
    customerShopName: row.customerShopName,
    pendingSync: row.syncStatus != 'synced',
    items: items
        .map(
          (i) => BillItem(
            id: i.id,
            billId: i.billId,
            productId: i.productId,
            nameSnapshot: i.nameSnapshot,
            qty: i.qty,
            rate: i.rate,
            discount: i.discount,
            lineTotal: i.lineTotal,
          ),
        )
        .toList(),
  );
}

Product mapLocalProduct(LocalProduct row) {
  return Product(
    id: row.id,
    businessId: row.businessId,
    categoryId: row.categoryId,
    name: row.name,
    nameNp: row.nameNp,
    sku: row.sku,
    unit: row.unit,
    costPrice: row.costPrice,
    referencePrice: row.referencePrice,
    imageUrl: row.imageUrl,
    lowStockThreshold: row.lowStockThreshold,
    stockCached: row.stockCached,
    isActive: row.isActive,
    categoryName: row.categoryName,
    updatedAt: row.updatedAt,
    createdAt: row.createdAt,
  );
}

Customer mapLocalCustomer(LocalCustomer row) {
  return Customer(
    id: row.id,
    businessId: row.businessId,
    memberId: row.memberId,
    shopName: row.shopName,
    contactName: row.contactName,
    phone: row.phone,
    address: row.address,
    openingBalance: row.openingBalance,
    balanceDue: row.balanceDue,
    createdAt: row.createdAt,
  );
}

Payment mapLocalPayment(LocalPayment row) {
  return Payment(
    id: row.id,
    businessId: row.businessId,
    customerId: row.customerId,
    billId: row.billId,
    amount: row.amount,
    method: PaymentMethod.values.byName(row.method),
    refNote: row.refNote,
    receivedBy: row.receivedBy,
    createdAt: row.createdAt,
  );
}

StockMovement mapLocalMovement(LocalStockMovement row) {
  return StockMovement(
    id: row.id,
    businessId: row.businessId,
    productId: row.productId,
    type: switch (row.type) {
      'stock_in' => StockMovementType.stockIn,
      'adjust' => StockMovementType.adjust,
      'dispatch' => StockMovementType.dispatch,
      'return' => StockMovementType.return_,
      _ => StockMovementType.adjust,
    },
    qtyDelta: row.qtyDelta,
    reason: row.reason,
    createdBy: row.createdBy,
    createdByName: row.createdByName,
    createdAt: row.createdAt,
  );
}
