import '../../domain/models/bill.dart';

/// Display name for a bill's customer.
///
/// Uses the shop/guest name stored on the bill. Falls back to [walkInLabel]
/// only when that name is missing or blank.
String billCustomerLabel(Bill bill, {required String walkInLabel}) {
  final name = bill.customerShopName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return walkInLabel;
}
