import 'package:json_annotation/json_annotation.dart';

/// Core enums — names must match Postgres enums exactly (see Agent.md).
enum Role { owner, sales, warehouse, customer }

enum OrderStatus {
  placed,
  received,
  billed,
}

enum QuoteStatus { sent, accepted, rejected, superseded }

enum BillStatus { paid, partial, due }

enum PaymentMethod { cash, cheque, wallet, bank }

enum ReportRange { today, week, month, last7Days, last30Days }

enum AgingBucket { bucket0to30, bucket31to60, bucket60plus }

extension AgingBucketX on AgingBucket {
  String get dbValue => switch (this) {
    AgingBucket.bucket0to30 => '0_30',
    AgingBucket.bucket31to60 => '31_60',
    AgingBucket.bucket60plus => '60_plus',
  };
}

enum StockMovementType {
  @JsonValue('stock_in')
  stockIn,
  @JsonValue('adjust')
  adjust,
  @JsonValue('dispatch')
  dispatch,
  @JsonValue('return')
  return_,
}

/// Allowed order state transitions (validated server-side too).
/// `placed|received → billed` is applied only by `create_bill`, not client updateStatus.
const Map<OrderStatus, Set<OrderStatus>> orderTransitions = {
  OrderStatus.placed: {OrderStatus.received, OrderStatus.billed},
  OrderStatus.received: {OrderStatus.billed},
  OrderStatus.billed: {},
};

extension RolePermissions on Role {
  bool get canBill => this == Role.owner || this == Role.sales;
  bool get canManageStock => this == Role.owner || this == Role.warehouse;
  bool get canQuote => this == Role.owner || this == Role.sales;
  bool get canRecordPayments => this == Role.owner || this == Role.sales;
  bool get canManageMembers => this == Role.owner;
  bool get canManageCustomers => this == Role.owner;
  bool get canManageProducts => this == Role.owner;
  bool get isStaff => this != Role.customer;
}
