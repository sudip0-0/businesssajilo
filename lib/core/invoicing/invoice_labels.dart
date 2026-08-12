/// Localized column / field labels for bill and credit-note PDFs.
class InvoiceLabels {
  const InvoiceLabels({
    required this.title,
    required this.billNo,
    required this.date,
    required this.customer,
    required this.item,
    required this.qty,
    required this.rate,
    required this.amount,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.sn,
  });

  final String title;
  final String billNo;
  final String date;
  final String customer;
  final String item;
  final String qty;
  final String rate;
  final String amount;
  final String subtotal;
  final String discount;
  final String grandTotal;
  final String sn;
}
