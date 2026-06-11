import 'package:json_annotation/json_annotation.dart';

/// Core enums — names must match Postgres enums exactly (see Agent.md).
enum Role { owner, sales, warehouse, customer }

enum OrderStatus {
  draft,
  placed,
  quoted,
  accepted,
  rejected,
  confirmed,
  packed,
  dispatched,
  billed,
  closed,
  cancelled,
}

enum QuoteStatus { sent, accepted, rejected }

enum BillStatus { paid, partial, due }

enum PaymentMethod { cash, cheque, wallet, bank }

enum ReportRange { today, week, month, last7Days }

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
}

/// Allowed order state transitions (validated server-side too).
const Map<OrderStatus, Set<OrderStatus>> orderTransitions = {
  OrderStatus.draft: {OrderStatus.placed, OrderStatus.cancelled},
  OrderStatus.placed: {OrderStatus.quoted, OrderStatus.cancelled},
  OrderStatus.quoted: {
    OrderStatus.accepted,
    OrderStatus.rejected,
    OrderStatus.quoted, // re-quote (new version)
    OrderStatus.cancelled,
  },
  OrderStatus.accepted: {OrderStatus.confirmed, OrderStatus.cancelled},
  OrderStatus.rejected: {OrderStatus.quoted, OrderStatus.cancelled},
  OrderStatus.confirmed: {OrderStatus.packed, OrderStatus.cancelled},
  OrderStatus.packed: {OrderStatus.dispatched},
  OrderStatus.dispatched: {OrderStatus.billed},
  OrderStatus.billed: {OrderStatus.closed},
  OrderStatus.closed: {},
  OrderStatus.cancelled: {},
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
