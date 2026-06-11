// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'बिजनेससजिलो';

  @override
  String get tagline => 'तपाईंको व्यवसाय, सजिलो तरिकाले।';

  @override
  String get login => 'लगइन';

  @override
  String get logout => 'लगआउट';

  @override
  String get phoneNumber => 'फोन नम्बर';

  @override
  String get password => 'पासवर्ड';

  @override
  String get dashboard => 'ड्यासबोर्ड';

  @override
  String get products => 'उत्पादनहरू';

  @override
  String get inventory => 'स्टक';

  @override
  String get orders => 'अर्डरहरू';

  @override
  String get quotes => 'कोटेशनहरू';

  @override
  String get billing => 'बिलिङ';

  @override
  String get bills => 'बिलहरू';

  @override
  String get newBill => 'नयाँ बिल';

  @override
  String get customers => 'ग्राहकहरू';

  @override
  String get payments => 'भुक्तानीहरू';

  @override
  String get ledger => 'खाता';

  @override
  String get reports => 'रिपोर्टहरू';

  @override
  String get settings => 'सेटिङहरू';

  @override
  String get stockIn => 'स्टक भित्र्याउने';

  @override
  String get lowStock => 'कम स्टक';

  @override
  String get dues => 'बाँकी';

  @override
  String get totalDues => 'जम्मा बाँकी';

  @override
  String get todaysSales => 'आजको बिक्री';

  @override
  String get pendingOrders => 'बाँकी अर्डरहरू';

  @override
  String get placeOrder => 'अर्डर गर्नुहोस्';

  @override
  String get myOrders => 'मेरा अर्डरहरू';

  @override
  String get myDues => 'मेरो बाँकी';

  @override
  String get catalog => 'सूची';

  @override
  String get quantity => 'परिमाण';

  @override
  String get rate => 'दर';

  @override
  String get discount => 'छुट';

  @override
  String get total => 'जम्मा';

  @override
  String get grandTotal => 'कुल जम्मा';

  @override
  String get paid => 'भुक्तानी भयो';

  @override
  String get partial => 'आंशिक';

  @override
  String get due => 'बाँकी';

  @override
  String get accept => 'स्वीकार';

  @override
  String get reject => 'अस्वीकार';

  @override
  String get cancel => 'रद्द';

  @override
  String get save => 'सेभ गर्नुहोस्';

  @override
  String get search => 'खोज्नुहोस्';

  @override
  String get synced => 'सिंक भयो';

  @override
  String get offline => 'अफलाइन';

  @override
  String pendingSync(int count) {
    return '$count बाँकी';
  }

  @override
  String get statusPlaced => 'अर्डर गरियो';

  @override
  String get statusQuoted => 'कोटेशन पठाइयो';

  @override
  String get statusAccepted => 'स्वीकृत';

  @override
  String get statusRejected => 'अस्वीकृत';

  @override
  String get statusConfirmed => 'पक्का भयो';

  @override
  String get statusPacked => 'प्याक भयो';

  @override
  String get statusDispatched => 'पठाइयो';

  @override
  String get statusBilled => 'बिल बन्यो';

  @override
  String get statusClosed => 'सकियो';

  @override
  String get statusCancelled => 'रद्द भयो';

  @override
  String get emptyNoProducts => 'अहिलेसम्म कुनै उत्पादन छैन';

  @override
  String get emptyAddFirstProduct => 'पहिलो उत्पादन थप्नुहोस्';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'English';

  @override
  String get nepali => 'नेपाली';

  @override
  String get email => 'इमेल';

  @override
  String get createAccount => 'खाता बनाउनुहोस्';

  @override
  String get registerBusiness => 'आफ्नो व्यवसाय दर्ता गर्नुहोस्';

  @override
  String get businessName => 'व्यवसायको नाम';

  @override
  String get businessNameNp => 'व्यवसायको नाम (नेपाली)';

  @override
  String get displayName => 'तपाईंको नाम';

  @override
  String get address => 'ठेगाना';

  @override
  String get noAccount => 'खाता छैन?';

  @override
  String get hasAccount => 'पहिले नै खाता छ?';

  @override
  String get signUp => 'साइन अप';

  @override
  String get signIn => 'साइन इन';

  @override
  String get staff => 'कर्मचारी';

  @override
  String get staffManagement => 'कर्मचारी व्यवस्थापन';

  @override
  String get addMember => 'सदस्य थप्नुहोस्';

  @override
  String get deactivate => 'निष्क्रिय गर्नुहोस्';

  @override
  String get deactivateConfirm =>
      'यो सदस्यलाई निष्क्रिय गर्ने? उनीहरू अब लगइन गर्न सक्ने छैनन्।';

  @override
  String get active => 'सक्रिय';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get roleOwner => 'मालिक';

  @override
  String get roleSales => 'बिक्री';

  @override
  String get roleWarehouse => 'गोदाम';

  @override
  String get roleCustomer => 'ग्राहक';

  @override
  String get shopName => 'पसलको नाम';

  @override
  String get contactName => 'सम्पर्क नाम';

  @override
  String get fieldRequired => 'यो फिल्ड आवश्यक छ';

  @override
  String get logoutConfirm => 'BusinessSajilo बाट लगआउट गर्ने?';

  @override
  String welcomeUser(String name) {
    return 'स्वागत छ, $name';
  }

  @override
  String get fulfillment => 'पूर्ति';

  @override
  String get stock => 'स्टक';

  @override
  String get addProduct => 'उत्पादन थप्नुहोस्';

  @override
  String get editProduct => 'उत्पादन सम्पादन';

  @override
  String get productName => 'उत्पादनको नाम';

  @override
  String get productNameNp => 'उत्पादनको नाम (नेपाली)';

  @override
  String get sku => 'SKU';

  @override
  String get unit => 'इकाई';

  @override
  String get costPrice => 'लागत मूल्य';

  @override
  String get referencePrice => 'सन्दर्भ मूल्य';

  @override
  String get lowStockThreshold => 'कम स्टक चेतावनी';

  @override
  String get inStock => 'स्टकमा छ';

  @override
  String get outOfStock => 'स्टक सकियो';

  @override
  String get stockLevel => 'स्टक स्तर';

  @override
  String get movementHistory => 'स्टक इतिहास';

  @override
  String get adjustmentReason => 'समायोजनको कारण';

  @override
  String get reasonRequired => 'समायोजनको लागि कारण आवश्यक छ';

  @override
  String get addCategory => 'श्रेणी थप्नुहोस्';

  @override
  String get editCategory => 'श्रेणी सम्पादन';

  @override
  String get categories => 'श्रेणीहरू';

  @override
  String get deleteProduct => 'उत्पादन मेटाउनुहोस्';

  @override
  String get deactivateProduct => 'उत्पादन निष्क्रिय';

  @override
  String get deactivateProductConfirm =>
      'यो उत्पादन निष्क्रिय गर्ने? बिक्रीबाट लुकाइनेछ।';

  @override
  String get imageOptional => 'उत्पादन तस्बिर (वैकल्पिक)';

  @override
  String get pickImage => 'तस्बिर छान्नुहोस्';

  @override
  String get piece => 'पिस';

  @override
  String get stockAdjust => 'स्टक समायोजन';

  @override
  String get qtyChange => 'परिमाण परिवर्तन';

  @override
  String get allCategories => 'सबै श्रेणी';

  @override
  String get noMovements => 'अहिलेसम्म कुनै स्टक चाल छैन';

  @override
  String get stockInQty => 'थप्ने परिमाण';

  @override
  String get movementTypeStockIn => 'स्टक भित्र';

  @override
  String get movementTypeAdjust => 'समायोजन';

  @override
  String get movementTypeDispatch => 'पठाइयो';

  @override
  String get filterProducts => 'उत्पादन खोज्नुहोस्';

  @override
  String get addCustomer => 'ग्राहक थप्नुहोस्';

  @override
  String get editCustomer => 'ग्राहक सम्पादन';

  @override
  String get openingBalance => 'सुरुवाती बाँकी';

  @override
  String get currentBalance => 'हालको बाँकी';

  @override
  String get recordPayment => 'भुक्तानी रेकर्ड';

  @override
  String get paymentMethod => 'भुक्तानी विधि';

  @override
  String get paymentRef => 'सन्दर्भ नोट';

  @override
  String get paymentAmount => 'भुक्तानी रकम';

  @override
  String get allocateToAccount => 'खाता भुक्तानी';

  @override
  String get allocateToBill => 'बिलमा जोड्नुहोस्';

  @override
  String get ledgerDebit => 'डेबिट';

  @override
  String get ledgerCredit => 'क्रेडिट';

  @override
  String get runningBalance => 'बाँकी';

  @override
  String get noCustomers => 'अहिलेसम्म कुनै ग्राहक छैन';

  @override
  String get noPayments => 'अहिलेसम्म कुनै भुक्तानी छैन';

  @override
  String get noLedgerEntries => 'अहिलेसम्म कुनै खाता प्रविष्टि छैन';

  @override
  String get filterCustomers => 'ग्राहक खोज्नुहोस्';

  @override
  String get paymentMethodCash => 'नगद';

  @override
  String get paymentMethodCheque => 'चेक';

  @override
  String get paymentMethodWallet => 'वालेट';

  @override
  String get paymentMethodBank => 'बैंक ट्रान्सफर';

  @override
  String get amountRequired => 'रकम आवश्यक छ';

  @override
  String get amountMustBePositive => 'रकम शून्य भन्दा ठूलो हुनुपर्छ';

  @override
  String get selectCustomer => 'ग्राहक छान्नुहोस्';

  @override
  String get entryOpeningBalance => 'सुरुवाती बाँकी';

  @override
  String get entryPayment => 'भुक्तानी';
}
