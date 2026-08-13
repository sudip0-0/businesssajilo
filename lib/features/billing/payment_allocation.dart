/// How a customer payment should hit open bills.
enum PaymentAllocateMode {
  /// Ledger only — do not attach to a bill (v1 default).
  account,

  /// Split across oldest due/partial bills first.
  oldestFirst,

  /// Attach the whole amount to [billId].
  bill,
}

class PaymentAllocation {
  const PaymentAllocation({required this.mode, this.billId});

  final PaymentAllocateMode mode;
  final String? billId;

  String? get rpcBillId => mode == PaymentAllocateMode.bill ? billId : null;

  String? get rpcAllocate =>
      mode == PaymentAllocateMode.oldestFirst ? 'oldest_first' : null;
}
