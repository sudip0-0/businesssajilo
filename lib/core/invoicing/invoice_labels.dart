/// Localized column / field labels for bill and credit-note PDFs.
class InvoiceLabels {
  const InvoiceLabels({
    required this.title,
    required this.billNo,
    required this.date,
    required this.customer,
    required this.name,
    required this.address,
    required this.item,
    required this.qty,
    required this.rate,
    required this.amount,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.total,
    required this.sn,
    required this.inWords,
    required this.authorized,
    required this.amountPaid,
    required this.remainingDue,
  });

  final String title;
  final String billNo;
  final String date;
  final String customer;
  final String name;
  final String address;
  final String item;
  final String qty;
  final String rate;
  final String amount;
  final String subtotal;
  final String discount;
  final String grandTotal;
  final String total;
  final String sn;
  final String inWords;
  final String authorized;
  final String amountPaid;
  final String remainingDue;
}
