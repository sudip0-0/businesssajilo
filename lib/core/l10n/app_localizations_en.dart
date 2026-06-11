// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BusinessSajilo';

  @override
  String get tagline => 'Your business, the easy way.';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get password => 'Password';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get products => 'Products';

  @override
  String get inventory => 'Inventory';

  @override
  String get orders => 'Orders';

  @override
  String get quotes => 'Quotes';

  @override
  String get billing => 'Billing';

  @override
  String get bills => 'Bills';

  @override
  String get newBill => 'New Bill';

  @override
  String get customers => 'Customers';

  @override
  String get payments => 'Payments';

  @override
  String get ledger => 'Ledger';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get stockIn => 'Stock In';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get dues => 'Dues';

  @override
  String get totalDues => 'Total Dues';

  @override
  String get todaysSales => 'Today\'s Sales';

  @override
  String get pendingOrders => 'Pending Orders';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get myOrders => 'My Orders';

  @override
  String get myDues => 'My Dues';

  @override
  String get catalog => 'Catalog';

  @override
  String get quantity => 'Quantity';

  @override
  String get rate => 'Rate';

  @override
  String get discount => 'Discount';

  @override
  String get total => 'Total';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get paid => 'Paid';

  @override
  String get partial => 'Partial';

  @override
  String get due => 'Due';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get search => 'Search';

  @override
  String get synced => 'Synced';

  @override
  String get offline => 'Offline';

  @override
  String pendingSync(int count) {
    return '$count pending';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get retrySync => 'Retry';

  @override
  String get pendingSyncItems => 'Pending sync';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get provisionalBillNo => 'Provisional bill number';

  @override
  String get statusPlaced => 'Placed';

  @override
  String get statusQuoted => 'Quoted';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusPacked => 'Packed';

  @override
  String get statusDispatched => 'Dispatched';

  @override
  String get statusBilled => 'Billed';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get emptyNoProducts => 'No products yet';

  @override
  String get emptyAddFirstProduct => 'Add your first product';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get nepali => 'Nepali';

  @override
  String get email => 'Email';

  @override
  String get createAccount => 'Create account';

  @override
  String get registerBusiness => 'Register your business';

  @override
  String get businessName => 'Business name';

  @override
  String get businessNameNp => 'Business name (Nepali)';

  @override
  String get displayName => 'Your name';

  @override
  String get address => 'Address';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get hasAccount => 'Already have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get signIn => 'Sign in';

  @override
  String get staff => 'Staff';

  @override
  String get staffManagement => 'Staff management';

  @override
  String get addMember => 'Add member';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get deactivateConfirm =>
      'Deactivate this member? They will no longer be able to log in.';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleSales => 'Sales';

  @override
  String get roleWarehouse => 'Warehouse';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get shopName => 'Shop name';

  @override
  String get contactName => 'Contact name';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get logoutConfirm => 'Log out of BusinessSajilo?';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String get fulfillment => 'Fulfillment';

  @override
  String get stock => 'Stock';

  @override
  String get addProduct => 'Add product';

  @override
  String get editProduct => 'Edit product';

  @override
  String get productName => 'Product name';

  @override
  String get productNameNp => 'Product name (Nepali)';

  @override
  String get sku => 'SKU';

  @override
  String get unit => 'Unit';

  @override
  String get costPrice => 'Cost price';

  @override
  String get referencePrice => 'Reference price';

  @override
  String get lowStockThreshold => 'Low stock alert at';

  @override
  String get inStock => 'In stock';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get stockLevel => 'Stock level';

  @override
  String get movementHistory => 'Movement history';

  @override
  String get adjustmentReason => 'Adjustment reason';

  @override
  String get reasonRequired => 'Reason is required for adjustments';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categories => 'Categories';

  @override
  String get deleteProduct => 'Delete product';

  @override
  String get deactivateProduct => 'Deactivate product';

  @override
  String get deactivateProductConfirm =>
      'Deactivate this product? It will be hidden from sales.';

  @override
  String get imageOptional => 'Product image (optional)';

  @override
  String get pickImage => 'Pick image';

  @override
  String get piece => 'Piece';

  @override
  String get stockAdjust => 'Adjust stock';

  @override
  String get qtyChange => 'Quantity change';

  @override
  String get allCategories => 'All categories';

  @override
  String get noMovements => 'No stock movements yet';

  @override
  String get stockInQty => 'Quantity to add';

  @override
  String get movementTypeStockIn => 'Stock in';

  @override
  String get movementTypeAdjust => 'Adjustment';

  @override
  String get movementTypeDispatch => 'Dispatch';

  @override
  String get filterProducts => 'Search products';

  @override
  String get addCustomer => 'Add customer';

  @override
  String get editCustomer => 'Edit customer';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get recordPayment => 'Record payment';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get paymentRef => 'Reference note';

  @override
  String get paymentAmount => 'Payment amount';

  @override
  String get allocateToAccount => 'Account payment';

  @override
  String get allocateToBill => 'Allocate to bill';

  @override
  String get ledgerDebit => 'Debit';

  @override
  String get ledgerCredit => 'Credit';

  @override
  String get runningBalance => 'Balance';

  @override
  String get noCustomers => 'No customers yet';

  @override
  String get noPayments => 'No payments yet';

  @override
  String get noLedgerEntries => 'No ledger entries yet';

  @override
  String get filterCustomers => 'Search customers';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodCheque => 'Cheque';

  @override
  String get paymentMethodWallet => 'Wallet';

  @override
  String get paymentMethodBank => 'Bank transfer';

  @override
  String get amountRequired => 'Amount is required';

  @override
  String get amountMustBePositive => 'Amount must be greater than zero';

  @override
  String get selectCustomer => 'Select customer';

  @override
  String get entryOpeningBalance => 'Opening balance';

  @override
  String get entryPayment => 'Payment';

  @override
  String get billNo => 'Bill no.';

  @override
  String get walkIn => 'Walk-in';

  @override
  String get lineTotal => 'Line total';

  @override
  String get billDiscount => 'Bill discount';

  @override
  String get saveBill => 'Save bill';

  @override
  String get billSaved => 'Bill saved';

  @override
  String get noBills => 'No bills yet';

  @override
  String get filterBills => 'Search bills';

  @override
  String get entryBill => 'Bill';

  @override
  String get billDetail => 'Bill detail';

  @override
  String get selectPaymentStatus => 'Payment status';

  @override
  String get amountPaid => 'Amount paid';

  @override
  String get customerOptional => 'Customer (optional)';

  @override
  String get addToBill => 'Add to bill';

  @override
  String get billLines => 'Bill lines';

  @override
  String get noBillLines => 'Add products to the bill';

  @override
  String get lineDiscount => 'Line discount';

  @override
  String get reviewAndSave => 'Review & save';

  @override
  String get todaysBills => 'Today\'s bills';

  @override
  String get cart => 'Cart';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get orderNote => 'Order note';

  @override
  String get sendQuote => 'Send quote';

  @override
  String quoteVersion(int version) {
    return 'Version $version';
  }

  @override
  String get rejectComment => 'Reason for rejection';

  @override
  String get confirmOrder => 'Confirm order';

  @override
  String get markPacked => 'Mark packed';

  @override
  String get markDispatched => 'Mark dispatched';

  @override
  String get generateBill => 'Generate bill';

  @override
  String get orderChat => 'Order chat';

  @override
  String get typeMessage => 'Type a message';

  @override
  String get billHistory => 'Bill history';

  @override
  String get orderDetail => 'Order detail';

  @override
  String get noOrders => 'No orders yet';

  @override
  String get viewQuote => 'View quote';

  @override
  String get requote => 'Send new quote';

  @override
  String get openChat => 'Chat';

  @override
  String get emptyCatalog => 'No products in catalog';

  @override
  String get orderItems => 'Order items';

  @override
  String get quoteDetail => 'Quote detail';

  @override
  String get quoteSent => 'Quote sent';

  @override
  String get quoteAccepted => 'Quote accepted';

  @override
  String get quoteRejected => 'Quote rejected';

  @override
  String get orderQueue => 'Order queue';

  @override
  String get fulfillmentQueue => 'Orders to fulfill';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get attachImage => 'Attach image';

  @override
  String get customerNote => 'Customer note';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get notifOrderPlaced => 'New order placed';

  @override
  String get notifQuoteReceived => 'New quote received';

  @override
  String get notifQuoteAccepted => 'Quote accepted';

  @override
  String get notifQuoteRejected => 'Quote rejected';

  @override
  String get notifOrderStatus => 'Order status updated';

  @override
  String get notifChatMessage => 'New chat message';

  @override
  String get notifPaymentRecorded => 'Payment recorded';

  @override
  String get notifLowStock => 'Low stock alert';

  @override
  String get salesSummary => 'Sales summary';

  @override
  String get duesAging => 'Dues aging';

  @override
  String get stockValuation => 'Stock valuation';

  @override
  String get topProducts => 'Top products';

  @override
  String get topCustomers => 'Top customers';

  @override
  String get aging0to30 => '0–30 days';

  @override
  String get aging31to60 => '31–60 days';

  @override
  String get aging60plus => '60+ days';

  @override
  String get totalValuation => 'Total valuation';

  @override
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get viewReport => 'Reports';

  @override
  String get totalSales => 'Total sales';

  @override
  String get noSalesInPeriod => 'No sales in this period';

  @override
  String get last7DaysSales => 'Last 7 days sales';

  @override
  String get ageDays => 'days';

  @override
  String get noDues => 'No outstanding dues';

  @override
  String get selectItem => 'Select an item';
}
