import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BusinessSajilo'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your business, the easy way.'**
  String get tagline;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @quotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get quotes;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// No description provided for @newBill.
  ///
  /// In en, this message translates to:
  /// **'New Bill'**
  String get newBill;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @stockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock In'**
  String get stockIn;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @dues.
  ///
  /// In en, this message translates to:
  /// **'Dues'**
  String get dues;

  /// No description provided for @totalDues.
  ///
  /// In en, this message translates to:
  /// **'Total Dues'**
  String get totalDues;

  /// No description provided for @todaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get todaysSales;

  /// No description provided for @pendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrders;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @myDues.
  ///
  /// In en, this message translates to:
  /// **'My Dues'**
  String get myDues;

  /// No description provided for @catalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingSync(int count);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @retrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retrySync;

  /// No description provided for @pendingSyncItems.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get pendingSyncItems;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @provisionalBillNo.
  ///
  /// In en, this message translates to:
  /// **'Provisional bill number'**
  String get provisionalBillNo;

  /// No description provided for @statusPlaced.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get statusPlaced;

  /// No description provided for @statusQuoted.
  ///
  /// In en, this message translates to:
  /// **'Quoted'**
  String get statusQuoted;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get statusPacked;

  /// No description provided for @statusDispatched.
  ///
  /// In en, this message translates to:
  /// **'Dispatched'**
  String get statusDispatched;

  /// No description provided for @statusBilled.
  ///
  /// In en, this message translates to:
  /// **'Billed'**
  String get statusBilled;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @emptyNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get emptyNoProducts;

  /// No description provided for @emptyAddFirstProduct.
  ///
  /// In en, this message translates to:
  /// **'Add your first product'**
  String get emptyAddFirstProduct;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @nepali.
  ///
  /// In en, this message translates to:
  /// **'Nepali'**
  String get nepali;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @registerBusiness.
  ///
  /// In en, this message translates to:
  /// **'Register your business'**
  String get registerBusiness;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @businessNameNp.
  ///
  /// In en, this message translates to:
  /// **'Business name (Nepali)'**
  String get businessNameNp;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get displayName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get hasAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @staffManagement.
  ///
  /// In en, this message translates to:
  /// **'Staff management'**
  String get staffManagement;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @deactivateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deactivate this member? They will no longer be able to log in.'**
  String get deactivateConfirm;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get roleSales;

  /// No description provided for @roleWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get roleWarehouse;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomer;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopName;

  /// No description provided for @contactName.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get contactName;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out of BusinessSajilo?'**
  String get logoutConfirm;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeUser(String name);

  /// No description provided for @fulfillment.
  ///
  /// In en, this message translates to:
  /// **'Fulfillment'**
  String get fulfillment;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @productNameNp.
  ///
  /// In en, this message translates to:
  /// **'Product name (Nepali)'**
  String get productNameNp;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost price'**
  String get costPrice;

  /// No description provided for @referencePrice.
  ///
  /// In en, this message translates to:
  /// **'Reference price'**
  String get referencePrice;

  /// No description provided for @lowStockThreshold.
  ///
  /// In en, this message translates to:
  /// **'Low stock alert at'**
  String get lowStockThreshold;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @stockLevel.
  ///
  /// In en, this message translates to:
  /// **'Stock level'**
  String get stockLevel;

  /// No description provided for @movementHistory.
  ///
  /// In en, this message translates to:
  /// **'Movement history'**
  String get movementHistory;

  /// No description provided for @adjustmentReason.
  ///
  /// In en, this message translates to:
  /// **'Adjustment reason'**
  String get adjustmentReason;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason is required for adjustments'**
  String get reasonRequired;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete product'**
  String get deleteProduct;

  /// No description provided for @deactivateProduct.
  ///
  /// In en, this message translates to:
  /// **'Deactivate product'**
  String get deactivateProduct;

  /// No description provided for @deactivateProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deactivate this product? It will be hidden from sales.'**
  String get deactivateProductConfirm;

  /// No description provided for @imageOptional.
  ///
  /// In en, this message translates to:
  /// **'Product image (optional)'**
  String get imageOptional;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick image'**
  String get pickImage;

  /// No description provided for @piece.
  ///
  /// In en, this message translates to:
  /// **'Piece'**
  String get piece;

  /// No description provided for @stockAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get stockAdjust;

  /// No description provided for @qtyChange.
  ///
  /// In en, this message translates to:
  /// **'Quantity change'**
  String get qtyChange;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @noMovements.
  ///
  /// In en, this message translates to:
  /// **'No stock movements yet'**
  String get noMovements;

  /// No description provided for @stockInQty.
  ///
  /// In en, this message translates to:
  /// **'Quantity to add'**
  String get stockInQty;

  /// No description provided for @movementTypeStockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in'**
  String get movementTypeStockIn;

  /// No description provided for @movementTypeAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get movementTypeAdjust;

  /// No description provided for @movementTypeDispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get movementTypeDispatch;

  /// No description provided for @filterProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get filterProducts;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomer;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @paymentRef.
  ///
  /// In en, this message translates to:
  /// **'Reference note'**
  String get paymentRef;

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment amount'**
  String get paymentAmount;

  /// No description provided for @allocateToAccount.
  ///
  /// In en, this message translates to:
  /// **'Account payment'**
  String get allocateToAccount;

  /// No description provided for @allocateToBill.
  ///
  /// In en, this message translates to:
  /// **'Allocate to bill'**
  String get allocateToBill;

  /// No description provided for @ledgerDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get ledgerDebit;

  /// No description provided for @ledgerCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get ledgerCredit;

  /// No description provided for @runningBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get runningBalance;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomers;

  /// No description provided for @noPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get noPayments;

  /// No description provided for @noLedgerEntries.
  ///
  /// In en, this message translates to:
  /// **'No ledger entries yet'**
  String get noLedgerEntries;

  /// No description provided for @filterCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers'**
  String get filterCustomers;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get paymentMethodCheque;

  /// No description provided for @paymentMethodWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get paymentMethodWallet;

  /// No description provided for @paymentMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get paymentMethodBank;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @amountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get amountMustBePositive;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get selectCustomer;

  /// No description provided for @entryOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get entryOpeningBalance;

  /// No description provided for @entryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get entryPayment;

  /// No description provided for @billNo.
  ///
  /// In en, this message translates to:
  /// **'Bill no.'**
  String get billNo;

  /// No description provided for @walkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get walkIn;

  /// No description provided for @lineTotal.
  ///
  /// In en, this message translates to:
  /// **'Line total'**
  String get lineTotal;

  /// No description provided for @billDiscount.
  ///
  /// In en, this message translates to:
  /// **'Bill discount'**
  String get billDiscount;

  /// No description provided for @saveBill.
  ///
  /// In en, this message translates to:
  /// **'Save bill'**
  String get saveBill;

  /// No description provided for @billSaved.
  ///
  /// In en, this message translates to:
  /// **'Bill saved'**
  String get billSaved;

  /// No description provided for @noBills.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get noBills;

  /// No description provided for @filterBills.
  ///
  /// In en, this message translates to:
  /// **'Search bills'**
  String get filterBills;

  /// No description provided for @entryBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get entryBill;

  /// No description provided for @billDetail.
  ///
  /// In en, this message translates to:
  /// **'Bill detail'**
  String get billDetail;

  /// No description provided for @selectPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get selectPaymentStatus;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get amountPaid;

  /// No description provided for @customerOptional.
  ///
  /// In en, this message translates to:
  /// **'Customer (optional)'**
  String get customerOptional;

  /// No description provided for @addToBill.
  ///
  /// In en, this message translates to:
  /// **'Add to bill'**
  String get addToBill;

  /// No description provided for @billLines.
  ///
  /// In en, this message translates to:
  /// **'Bill lines'**
  String get billLines;

  /// No description provided for @noBillLines.
  ///
  /// In en, this message translates to:
  /// **'Add products to the bill'**
  String get noBillLines;

  /// No description provided for @lineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Line discount'**
  String get lineDiscount;

  /// No description provided for @reviewAndSave.
  ///
  /// In en, this message translates to:
  /// **'Review & save'**
  String get reviewAndSave;

  /// No description provided for @todaysBills.
  ///
  /// In en, this message translates to:
  /// **'Today\'s bills'**
  String get todaysBills;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// No description provided for @orderNote.
  ///
  /// In en, this message translates to:
  /// **'Order note'**
  String get orderNote;

  /// No description provided for @sendQuote.
  ///
  /// In en, this message translates to:
  /// **'Send quote'**
  String get sendQuote;

  /// No description provided for @quoteVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String quoteVersion(int version);

  /// No description provided for @rejectComment.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get rejectComment;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm order'**
  String get confirmOrder;

  /// No description provided for @markPacked.
  ///
  /// In en, this message translates to:
  /// **'Mark packed'**
  String get markPacked;

  /// No description provided for @markDispatched.
  ///
  /// In en, this message translates to:
  /// **'Mark dispatched'**
  String get markDispatched;

  /// No description provided for @generateBill.
  ///
  /// In en, this message translates to:
  /// **'Generate bill'**
  String get generateBill;

  /// No description provided for @orderChat.
  ///
  /// In en, this message translates to:
  /// **'Order chat'**
  String get orderChat;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeMessage;

  /// No description provided for @billHistory.
  ///
  /// In en, this message translates to:
  /// **'Bill history'**
  String get billHistory;

  /// No description provided for @orderDetail.
  ///
  /// In en, this message translates to:
  /// **'Order detail'**
  String get orderDetail;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrders;

  /// No description provided for @viewQuote.
  ///
  /// In en, this message translates to:
  /// **'View quote'**
  String get viewQuote;

  /// No description provided for @requote.
  ///
  /// In en, this message translates to:
  /// **'Send new quote'**
  String get requote;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get openChat;

  /// No description provided for @emptyCatalog.
  ///
  /// In en, this message translates to:
  /// **'No products in catalog'**
  String get emptyCatalog;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Order items'**
  String get orderItems;

  /// No description provided for @quoteDetail.
  ///
  /// In en, this message translates to:
  /// **'Quote detail'**
  String get quoteDetail;

  /// No description provided for @quoteSent.
  ///
  /// In en, this message translates to:
  /// **'Quote sent'**
  String get quoteSent;

  /// No description provided for @quoteAccepted.
  ///
  /// In en, this message translates to:
  /// **'Quote accepted'**
  String get quoteAccepted;

  /// No description provided for @quoteRejected.
  ///
  /// In en, this message translates to:
  /// **'Quote rejected'**
  String get quoteRejected;

  /// No description provided for @orderQueue.
  ///
  /// In en, this message translates to:
  /// **'Order queue'**
  String get orderQueue;

  /// No description provided for @fulfillmentQueue.
  ///
  /// In en, this message translates to:
  /// **'Orders to fulfill'**
  String get fulfillmentQueue;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @attachImage.
  ///
  /// In en, this message translates to:
  /// **'Attach image'**
  String get attachImage;

  /// No description provided for @customerNote.
  ///
  /// In en, this message translates to:
  /// **'Customer note'**
  String get customerNote;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @notifOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'New order placed'**
  String get notifOrderPlaced;

  /// No description provided for @notifQuoteReceived.
  ///
  /// In en, this message translates to:
  /// **'New quote received'**
  String get notifQuoteReceived;

  /// No description provided for @notifQuoteAccepted.
  ///
  /// In en, this message translates to:
  /// **'Quote accepted'**
  String get notifQuoteAccepted;

  /// No description provided for @notifQuoteRejected.
  ///
  /// In en, this message translates to:
  /// **'Quote rejected'**
  String get notifQuoteRejected;

  /// No description provided for @notifOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order status updated'**
  String get notifOrderStatus;

  /// No description provided for @notifChatMessage.
  ///
  /// In en, this message translates to:
  /// **'New chat message'**
  String get notifChatMessage;

  /// No description provided for @notifPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get notifPaymentRecorded;

  /// No description provided for @notifLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock alert'**
  String get notifLowStock;

  /// No description provided for @salesSummary.
  ///
  /// In en, this message translates to:
  /// **'Sales summary'**
  String get salesSummary;

  /// No description provided for @duesAging.
  ///
  /// In en, this message translates to:
  /// **'Dues aging'**
  String get duesAging;

  /// No description provided for @stockValuation.
  ///
  /// In en, this message translates to:
  /// **'Stock valuation'**
  String get stockValuation;

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get topProducts;

  /// No description provided for @topCustomers.
  ///
  /// In en, this message translates to:
  /// **'Top customers'**
  String get topCustomers;

  /// No description provided for @aging0to30.
  ///
  /// In en, this message translates to:
  /// **'0–30 days'**
  String get aging0to30;

  /// No description provided for @aging31to60.
  ///
  /// In en, this message translates to:
  /// **'31–60 days'**
  String get aging31to60;

  /// No description provided for @aging60plus.
  ///
  /// In en, this message translates to:
  /// **'60+ days'**
  String get aging60plus;

  /// No description provided for @totalValuation.
  ///
  /// In en, this message translates to:
  /// **'Total valuation'**
  String get totalValuation;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get viewReport;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total sales'**
  String get totalSales;

  /// No description provided for @noSalesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period'**
  String get noSalesInPeriod;

  /// No description provided for @last7DaysSales.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days sales'**
  String get last7DaysSales;

  /// No description provided for @ageDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get ageDays;

  /// No description provided for @noDues.
  ///
  /// In en, this message translates to:
  /// **'No outstanding dues'**
  String get noDues;

  /// No description provided for @selectItem.
  ///
  /// In en, this message translates to:
  /// **'Select an item'**
  String get selectItem;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @loadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get loadingFailed;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutApp;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @syncEntityBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get syncEntityBill;

  /// No description provided for @syncEntityPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get syncEntityPayment;

  /// No description provided for @syncEntityStockMovement.
  ///
  /// In en, this message translates to:
  /// **'Stock movement'**
  String get syncEntityStockMovement;

  /// No description provided for @syncEntityCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get syncEntityCustomer;

  /// No description provided for @syncEntityProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get syncEntityProduct;

  /// No description provided for @syncStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get syncStatusPending;

  /// No description provided for @syncStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get syncStatusFailed;

  /// No description provided for @syncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// No description provided for @loadDemoData.
  ///
  /// In en, this message translates to:
  /// **'Load sample data'**
  String get loadDemoData;

  /// No description provided for @loadDemoDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add sample products and a customer to get started?'**
  String get loadDemoDataConfirm;

  /// No description provided for @demoDataLoaded.
  ///
  /// In en, this message translates to:
  /// **'Sample data added'**
  String get demoDataLoaded;

  /// No description provided for @demoDataSkipped.
  ///
  /// In en, this message translates to:
  /// **'Sample data already exists'**
  String get demoDataSkipped;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BusinessSajilo'**
  String get onboardingWelcome;

  /// No description provided for @onboardingKpis.
  ///
  /// In en, this message translates to:
  /// **'Your dashboard shows today\'s sales, dues, stock alerts, and orders.'**
  String get onboardingKpis;

  /// No description provided for @onboardingProducts.
  ///
  /// In en, this message translates to:
  /// **'Add products in Inventory to start billing.'**
  String get onboardingProducts;

  /// No description provided for @onboardingCustomers.
  ///
  /// In en, this message translates to:
  /// **'Add customers to track udharo and payments.'**
  String get onboardingCustomers;

  /// No description provided for @onboardingBills.
  ///
  /// In en, this message translates to:
  /// **'Create bills from the Billing tab.'**
  String get onboardingBills;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingDone.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingDone;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip tour'**
  String get onboardingSkip;

  /// No description provided for @accountDeactivated.
  ///
  /// In en, this message translates to:
  /// **'This account has been deactivated. Contact your business owner.'**
  String get accountDeactivated;

  /// No description provided for @configError.
  ///
  /// In en, this message translates to:
  /// **'App is not configured. Missing SUPABASE_URL / SUPABASE_ANON_KEY.'**
  String get configError;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get goHome;

  /// No description provided for @failedSyncItems.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String failedSyncItems(int count);

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentials;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get emailAlreadyRegistered;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get weakPassword;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error — check your connection'**
  String get networkError;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @noStaff.
  ///
  /// In en, this message translates to:
  /// **'No staff members yet'**
  String get noStaff;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategories;

  /// No description provided for @selectCustomerForCredit.
  ///
  /// In en, this message translates to:
  /// **'Select a customer for credit or partial bills'**
  String get selectCustomerForCredit;

  /// No description provided for @amountExceedsTotal.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed the grand total'**
  String get amountExceedsTotal;

  /// No description provided for @discountExceedsLine.
  ///
  /// In en, this message translates to:
  /// **'Discount cannot exceed the line amount'**
  String get discountExceedsLine;

  /// No description provided for @discountExceedsItems.
  ///
  /// In en, this message translates to:
  /// **'Discount cannot exceed the items total'**
  String get discountExceedsItems;

  /// No description provided for @noAcceptedQuote.
  ///
  /// In en, this message translates to:
  /// **'No accepted quote for this order yet'**
  String get noAcceptedQuote;

  /// No description provided for @invalidStatusChange.
  ///
  /// In en, this message translates to:
  /// **'This status change is not allowed'**
  String get invalidStatusChange;

  /// No description provided for @closeOrder.
  ///
  /// In en, this message translates to:
  /// **'Close order'**
  String get closeOrder;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @messageSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Message could not be sent. Try again.'**
  String get messageSendFailed;

  /// No description provided for @openingBalanceLocked.
  ///
  /// In en, this message translates to:
  /// **'Opening balance can only be set when the customer is created'**
  String get openingBalanceLocked;

  /// No description provided for @overpaymentWarning.
  ///
  /// In en, this message translates to:
  /// **'This exceeds the due amount and will create a credit balance.'**
  String get overpaymentWarning;

  /// No description provided for @creditBalance.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get creditBalance;

  /// No description provided for @rateMissing.
  ///
  /// In en, this message translates to:
  /// **'Price missing — set the rate'**
  String get rateMissing;

  /// No description provided for @placeOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Place order with {count} items?'**
  String placeOrderConfirm(int count);

  /// No description provided for @removedUnavailableItems.
  ///
  /// In en, this message translates to:
  /// **'Some items were removed because they are no longer available'**
  String get removedUnavailableItems;

  /// No description provided for @orderPlaceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not place the order. Try again.'**
  String get orderPlaceFailed;

  /// No description provided for @quoteAcceptConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accept this quote for {total}?'**
  String quoteAcceptConfirm(String total);

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get actionFailed;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @replayTour.
  ///
  /// In en, this message translates to:
  /// **'Replay tour'**
  String get replayTour;

  /// No description provided for @replayTourDone.
  ///
  /// In en, this message translates to:
  /// **'Tour will show on the next dashboard visit'**
  String get replayTourDone;

  /// No description provided for @confirmDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete this category? Products in it will keep working without a category.'**
  String get confirmDeleteCategory;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidNumber;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @increaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get increaseQuantity;

  /// No description provided for @decreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get decreaseQuantity;

  /// No description provided for @onboardingOrders.
  ///
  /// In en, this message translates to:
  /// **'Track customer orders and quotes from the Orders tab.'**
  String get onboardingOrders;

  /// No description provided for @onboardingReports.
  ///
  /// In en, this message translates to:
  /// **'See sales, dues, and stock reports in Reports.'**
  String get onboardingReports;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatus;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
