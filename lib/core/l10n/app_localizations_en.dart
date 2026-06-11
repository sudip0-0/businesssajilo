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
}
