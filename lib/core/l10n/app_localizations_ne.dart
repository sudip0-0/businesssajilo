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
  String get syncNow => 'अहिले सिंक गर्नुहोस्';

  @override
  String get retrySync => 'पुनः प्रयास';

  @override
  String get pendingSyncItems => 'बाँकी सिंक';

  @override
  String get syncFailed => 'सिंक असफल';

  @override
  String get provisionalBillNo => 'अस्थायी बिल नम्बर';

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
  String get productName => 'सामानको नाम';

  @override
  String get productNameNp => 'उत्पादनको नाम (नेपाली)';

  @override
  String get sku => 'SKU';

  @override
  String get unit => 'एकाइ';

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
  String get movementTypeReturn => 'फिर्ता';

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
  String get ledgerDate => 'मिति';

  @override
  String get ledgerDescription => 'विवरण';

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

  @override
  String get billNo => 'बिल नं.';

  @override
  String get walkIn => 'वाक-इन';

  @override
  String get lineTotal => 'लाइन जम्मा';

  @override
  String get billDiscount => 'बिल छुट';

  @override
  String get saveBill => 'बिल सेभ';

  @override
  String get billSaved => 'बिल सेभ भयो';

  @override
  String get noBills => 'अहिलेसम्म कुनै बिल छैन';

  @override
  String get filterBills => 'बिल खोज्नुहोस्';

  @override
  String get entryBill => 'बिल';

  @override
  String get billDetail => 'बिल विवरण';

  @override
  String get selectPaymentStatus => 'भुक्तानी स्थिति';

  @override
  String get amountPaid => 'भुक्तानी रकम';

  @override
  String get customerOptional => 'ग्राहक (वैकल्पिक)';

  @override
  String get addToBill => 'बिलमा थप्नुहोस्';

  @override
  String get billLines => 'बिल लाइनहरू';

  @override
  String get noBillLines => 'बिलमा उत्पादन थप्नुहोस्';

  @override
  String get lineDiscount => 'लाइन छुट';

  @override
  String get reviewAndSave => 'समीक्षा र सेभ';

  @override
  String get todaysBills => 'आजका बिल';

  @override
  String get cart => 'कार्ट';

  @override
  String get addToCart => 'कार्टमा थप्नुहोस्';

  @override
  String get orderNote => 'अर्डर नोट';

  @override
  String get sendQuote => 'कोटेशन पठाउनुहोस्';

  @override
  String quoteVersion(int version) {
    return 'संस्करण $version';
  }

  @override
  String get rejectComment => 'अस्वीकारको कारण';

  @override
  String get confirmOrder => 'अर्डर पुष्टि गर्नुहोस्';

  @override
  String get markPacked => 'प्याक गरियो';

  @override
  String get markDispatched => 'पठाइयो';

  @override
  String get generateBill => 'बिल बनाउनुहोस्';

  @override
  String get orderChat => 'अर्डर च्याट';

  @override
  String get typeMessage => 'सन्देश टाइप गर्नुहोस्';

  @override
  String get billHistory => 'बिल इतिहास';

  @override
  String get orderDetail => 'अर्डर विवरण';

  @override
  String get noOrders => 'अहिलेसम्म कुनै अर्डर छैन';

  @override
  String get viewQuote => 'कोटेशन हेर्नुहोस्';

  @override
  String get requote => 'नयाँ कोटेशन पठाउनुहोस्';

  @override
  String get openChat => 'च्याट';

  @override
  String get emptyCatalog => 'सूचीमा उत्पादन छैन';

  @override
  String get orderItems => 'अर्डर वस्तुहरू';

  @override
  String get quoteDetail => 'कोटेशन विवरण';

  @override
  String get quoteSent => 'कोटेशन पठाइयो';

  @override
  String get quoteAccepted => 'कोटेशन स्वीकार';

  @override
  String get quoteRejected => 'कोटेशन अस्वीकार';

  @override
  String get orderQueue => 'अर्डर क्यू';

  @override
  String get fulfillmentQueue => 'पूर्ति गर्न बाँकी अर्डर';

  @override
  String get noMessages => 'अहिलेसम्म कुनै सन्देश छैन';

  @override
  String get attachImage => 'फोटो संलग्न';

  @override
  String get customerNote => 'ग्राहक नोट';

  @override
  String get notifications => 'सूचनाहरू';

  @override
  String get markAllRead => 'सबै पढिएको';

  @override
  String get noNotifications => 'अहिलेसम्म कुनै सूचना छैन';

  @override
  String get notifOrderPlaced => 'नयाँ अर्डर आयो';

  @override
  String get notifQuoteReceived => 'नयाँ कोटेशन प्राप्त';

  @override
  String get notifQuoteAccepted => 'कोटेशन स्वीकार भयो';

  @override
  String get notifQuoteRejected => 'कोटेशन अस्वीकार भयो';

  @override
  String get notifOrderStatus => 'अर्डर स्थिति अद्यावधिक';

  @override
  String get notifChatMessage => 'नयाँ च्याट सन्देश';

  @override
  String get notifPaymentRecorded => 'भुक्तानी रेकर्ड भयो';

  @override
  String get notifLowStock => 'कम स्टक चेतावनी';

  @override
  String get salesSummary => 'बिक्री सारांश';

  @override
  String get duesAging => 'बाँकी उमेर';

  @override
  String get stockValuation => 'स्टक मूल्यांकन';

  @override
  String get topProducts => 'शीर्ष सामान';

  @override
  String get topCustomers => 'शीर्ष ग्राहक';

  @override
  String get aging0to30 => '०–३० दिन';

  @override
  String get aging31to60 => '३१–६० दिन';

  @override
  String get aging60plus => '६०+ दिन';

  @override
  String get totalValuation => 'कुल मूल्यांकन';

  @override
  String get periodToday => 'आज';

  @override
  String get periodWeek => 'हप्ता';

  @override
  String get periodMonth => 'महिना';

  @override
  String get viewReport => 'रिपोर्टहरू';

  @override
  String get totalSales => 'कुल बिक्री';

  @override
  String get noSalesInPeriod => 'यो अवधिमा बिक्री छैन';

  @override
  String get last7DaysSales => 'पछिल्लो ७ दिनको बिक्री';

  @override
  String get ageDays => 'दिन';

  @override
  String get noDues => 'कुनै बाँकी छैन';

  @override
  String get selectItem => 'एउटा वस्तु छान्नुहोस्';

  @override
  String get somethingWentWrong => 'केही गडबड भयो';

  @override
  String get tryAgain => 'फेरि प्रयास गर्नुहोस्';

  @override
  String get loadingFailed => 'डाटा लोड गर्न सकिएन';

  @override
  String get aboutApp => 'बारेमा';

  @override
  String appVersion(String version) {
    return 'संस्करण $version';
  }

  @override
  String get name => 'नाम';

  @override
  String get revenue => 'आम्दानी';

  @override
  String get syncEntityBill => 'बिल';

  @override
  String get syncEntityPayment => 'भुक्तानी';

  @override
  String get syncEntityStockMovement => 'स्टक सार्ने';

  @override
  String get syncEntityCustomer => 'ग्राहक';

  @override
  String get syncEntityProduct => 'सामान';

  @override
  String get syncStatusPending => 'पर्खाइमा';

  @override
  String get syncStatusFailed => 'असफल';

  @override
  String get syncStatusSynced => 'सिंक भयो';

  @override
  String get loadDemoData => 'नमूना डाटा लोड गर्नुहोस्';

  @override
  String get loadDemoDataConfirm => 'सुरु गर्न नमूना सामान र ग्राहक थप्ने?';

  @override
  String get demoDataLoaded => 'नमूना डाटा थपियो';

  @override
  String get demoDataSkipped => 'नमूना डाटा पहिले नै छ';

  @override
  String get onboardingWelcome => 'BusinessSajilo मा स्वागत छ';

  @override
  String get onboardingKpis =>
      'ड्यासबोर्डमा आजको बिक्री, बाँकी, स्टक र अर्डर देखिन्छ।';

  @override
  String get onboardingProducts =>
      'बिलिङ सुरु गर्न इन्भेन्टरीमा सामान थप्नुहोस्।';

  @override
  String get onboardingCustomers => 'उधारो ट्र्याक गर्न ग्राहक थप्नुहोस्।';

  @override
  String get onboardingBills => 'बिलिङ ट्याबबाट बिल बनाउनुहोस्।';

  @override
  String get onboardingNext => 'अर्को';

  @override
  String get onboardingDone => 'सुरु गर्नुहोस्';

  @override
  String get onboardingSkip => 'टुर छोड्नुहोस्';

  @override
  String get accountDeactivated =>
      'यो खाता निष्क्रिय गरिएको छ। आफ्नो व्यवसाय मालिकलाई सम्पर्क गर्नुहोस्।';

  @override
  String get configError =>
      'एप कन्फिगर गरिएको छैन। SUPABASE_URL / SUPABASE_ANON_KEY छैन।';

  @override
  String get pageNotFound => 'पृष्ठ फेला परेन';

  @override
  String get goHome => 'गृहपृष्ठमा जानुहोस्';

  @override
  String failedSyncItems(int count) {
    return '$count असफल';
  }

  @override
  String get invalidCredentials => 'इमेल वा पासवर्ड गलत छ';

  @override
  String get emailAlreadyRegistered => 'यो इमेल पहिले नै दर्ता छ';

  @override
  String get weakPassword => 'पासवर्ड कमजोर छ';

  @override
  String get networkError => 'नेटवर्क समस्या — जडान जाँच गर्नुहोस्';

  @override
  String get loadMore => 'थप लोड गर्नुहोस्';

  @override
  String get noStaff => 'अहिलेसम्म कुनै कर्मचारी छैन';

  @override
  String get noCategories => 'अहिलेसम्म कुनै श्रेणी छैन';

  @override
  String get selectCustomerForCredit =>
      'उधारो वा आंशिक बिलका लागि ग्राहक छान्नुहोस्';

  @override
  String get amountExceedsTotal => 'रकम कुल जम्माभन्दा बढी हुन सक्दैन';

  @override
  String get discountExceedsLine => 'छुट लाइन रकमभन्दा बढी हुन सक्दैन';

  @override
  String get discountExceedsItems => 'छुट सामानको जम्माभन्दा बढी हुन सक्दैन';

  @override
  String get noAcceptedQuote => 'यो अर्डरका लागि स्वीकृत कोटेसन छैन';

  @override
  String get invalidStatusChange => 'यो स्थिति परिवर्तन अनुमति छैन';

  @override
  String get closeOrder => 'अर्डर बन्द गर्नुहोस्';

  @override
  String get areYouSure => 'के तपाईं निश्चित हुनुहुन्छ?';

  @override
  String get messageSendFailed => 'सन्देश पठाउन सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get openingBalanceLocked =>
      'सुरुवाती बाँकी ग्राहक बनाउँदा मात्र सेट गर्न सकिन्छ';

  @override
  String get overpaymentWarning =>
      'यो बाँकी रकमभन्दा बढी छ र क्रेडिट ब्यालेन्स बन्नेछ।';

  @override
  String get creditBalance => 'क्रेडिट';

  @override
  String get rateMissing => 'मूल्य छैन — दर सेट गर्नुहोस्';

  @override
  String placeOrderConfirm(int count) {
    return '$count वस्तुसहित अर्डर गर्ने?';
  }

  @override
  String get removedUnavailableItems => 'केही वस्तुहरू अब उपलब्ध नभएकाले हटाइए';

  @override
  String get orderPlaceFailed => 'अर्डर गर्न सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String quoteAcceptConfirm(String total) {
    return '$total को यो कोटेसन स्वीकार गर्ने?';
  }

  @override
  String get actionFailed => 'केही गडबड भयो। फेरि प्रयास गर्नुहोस्।';

  @override
  String get theme => 'थिम';

  @override
  String get themeSystem => 'प्रणाली';

  @override
  String get themeLight => 'उज्यालो';

  @override
  String get themeDark => 'अँध्यारो';

  @override
  String get more => 'थप';

  @override
  String get replayTour => 'टुर फेरि हेर्नुहोस्';

  @override
  String get replayTourDone => 'अर्को पटक ड्यासबोर्ड खोल्दा टुर देखिनेछ';

  @override
  String get confirmDeleteCategory =>
      'यो श्रेणी मेट्ने? यसका सामानहरू श्रेणीबिना नै रहनेछन्।';

  @override
  String get delete => 'मेटाउनुहोस्';

  @override
  String get edit => 'सम्पादन गर्नुहोस्';

  @override
  String get remove => 'हटाउनुहोस्';

  @override
  String get send => 'पठाउनुहोस्';

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get invalidEmail => 'मान्य इमेल लेख्नुहोस्';

  @override
  String get invalidNumber => 'मान्य संख्या लेख्नुहोस्';

  @override
  String get showPassword => 'पासवर्ड देखाउनुहोस्';

  @override
  String get hidePassword => 'पासवर्ड लुकाउनुहोस्';

  @override
  String get increaseQuantity => 'मात्रा बढाउनुहोस्';

  @override
  String get decreaseQuantity => 'मात्रा घटाउनुहोस्';

  @override
  String get onboardingOrders =>
      'अर्डर ट्याबबाट ग्राहकका अर्डर र कोटेशन हेर्नुहोस्।';

  @override
  String get onboardingReports =>
      'रिपोर्टमा बिक्री, बाँकी र स्टक रिपोर्ट हेर्नुहोस्।';

  @override
  String get syncStatus => 'सिंक स्थिति';

  @override
  String namasteGreeting(String name) {
    return 'नमस्ते, $name!';
  }

  @override
  String get dashboardTodaySummary => 'आज तपाईंको व्यवसायमा के भइरहेको छ।';

  @override
  String get salesPerformance => 'बिक्री प्रदर्शन';

  @override
  String get salesPerformanceSubtitle => '७-दिने राजस्व प्रवृत्ति विश्लेषण';

  @override
  String get salesPerformanceSubtitleMonthly =>
      '३०-दिने राजस्व प्रवृत्ति विश्लेषण';

  @override
  String get quickStockCheck => 'छिटो स्टक जाँच';

  @override
  String get recentActivity => 'हालैको गतिविधि';

  @override
  String get todaysTransactions => 'आजका कारोबार';

  @override
  String get addNewCustomer => 'नयाँ ग्राहक थप्नुहोस्';

  @override
  String get addCustomerSubtitle =>
      'क्रेडिट र बिक्री व्यवस्थापनका लागि नयाँ ग्राहक प्रोफाइल बनाउनुहोस्।';

  @override
  String get customerIdentity => 'ग्राहक पहिचान';

  @override
  String get customerIdentityHint =>
      'व्यवसायको आधारभूत र कानूनी जानकारी भर्नुहोस्।';

  @override
  String get contactAndLocation => 'सम्पर्क र स्थान';

  @override
  String get financialInformation => 'वित्तीय जानकारी';

  @override
  String get ownerName => 'मालिकको नाम';

  @override
  String get emailAddress => 'इमेल ठेगाना';

  @override
  String get city => 'शहर';

  @override
  String get district => 'जिल्ला';

  @override
  String get selectCity => 'शहर छान्नुहोस्';

  @override
  String get panVatNumber => 'PAN/VAT नम्बर';

  @override
  String get creditLimit => 'क्रेडिट सीमा (NPR)';

  @override
  String get saveCustomer => 'ग्राहक सुरक्षित गर्नुहोस्';

  @override
  String get createNewBill => 'नयाँ बिल बनाउनुहोस्';

  @override
  String get createBillSubtitle => 'नगद वा उधारो ग्राहकका लागि बिल बनाउनुहोस्।';

  @override
  String get saveAsDraft => 'ड्राफ्ट सुरक्षित गर्नुहोस्';

  @override
  String get printAndSave => 'प्रिन्ट र सुरक्षित';

  @override
  String get needsAttention => 'ध्यान चाहिन्छ';

  @override
  String get reorderSoon => 'चाँडै पुनः अर्डर';

  @override
  String get viewAllHistory => 'सबै कारोबार इतिहास हेर्नुहोस्';

  @override
  String get smeManagement => 'SME व्यवस्थापन';

  @override
  String get globalSearchHint => 'सामान, अर्डर, बिल खोज्नुहोस्...';

  @override
  String get export => 'निर्यात';

  @override
  String get filter => 'फिल्टर';

  @override
  String get weekly => 'साप्ताहिक';

  @override
  String get monthly => 'मासिक';

  @override
  String get reportOverview => 'व्यवसाय विश्लेषण अवलोकन';

  @override
  String get billNumber => 'बिल नम्बर';

  @override
  String get billDate => 'बिल मिति';

  @override
  String get customerName => 'ग्राहकको नाम';

  @override
  String get remarksTerms => 'कैफियत / सर्त';

  @override
  String get subtotal => 'उप-योग';

  @override
  String get taxableAmount => 'कर योग्य रकम';

  @override
  String get verificationTip =>
      'कर अनुपालनका लागi PAN/VAT नम्बर सधैं प्रमाणित गर्नुहोस्।';

  @override
  String get creditPolicyTip =>
      'कारोबार इतिहास अनुसार वास्तविक क्रेडिट सीमा तोक्नुहोस्।';

  @override
  String get privacyTip =>
      'सबै ग्राहक डाटा इन्क्रिप्टेड र सुरक्षित रूपमा भण्डारण गरिन्छ।';

  @override
  String newBillCreated(String billNo) {
    return 'नयाँ बिल #$billNo';
  }

  @override
  String lowStockAlert(String product) {
    return 'कम स्टक: $product';
  }

  @override
  String newCustomerAdded(String name) {
    return 'नयाँ ग्राहक: $name';
  }

  @override
  String get walkInCustomer => 'वाक-इन ग्राहक';

  @override
  String get storeOwner => 'स्टोर मालिक';

  @override
  String get portalAccess => 'पोर्टल पहुँच';

  @override
  String get portalAccessHint =>
      'ग्राहकले लग-इन गरी अर्डर हेर्नका लागि प्रमाणपत्र।';

  @override
  String get amountNpr => 'रकम (NPR)';

  @override
  String get time => 'समय';

  @override
  String get payment => 'भुक्तानी';

  @override
  String get status => 'स्थिति';

  @override
  String get sn => 'क्र.सं.';

  @override
  String get qty => 'मात्रा';

  @override
  String get amountRs => 'रकम (Rs.)';

  @override
  String get rateRs => 'दर (Rs.)';

  @override
  String get discountPercent => 'छुट (%)';

  @override
  String get madeForNepal => 'नेपाल SME इकोसिस्टमका लागि';

  @override
  String get shareViaWhatsApp => 'WhatsApp मार्फत पठाउनुहोस्';

  @override
  String get downloadPdf => 'PDF डाउनलोड';

  @override
  String get printInvoice => 'बिल प्रिन्ट';

  @override
  String get returnItems => 'सामान फिर्ता';

  @override
  String get creditNote => 'क्रेडिट नोट';

  @override
  String get qtyReturned => 'फिर्ता परिमाण';

  @override
  String get restockInventory => 'स्टकमा फिर्ता राख्नुहोस्';

  @override
  String get returnReason => 'फिर्ताको कारण';

  @override
  String get exportCsv => 'CSV निर्यात';

  @override
  String get provisionalBillNotice => 'अस्थायी बिल नम्बर — सिङ्क बाँकी';

  @override
  String get invoiceThankYou => 'व्यापार गर्नुभएकोमा धन्यवाद!';

  @override
  String get creditNoteSaved => 'क्रेडिट नोट सुरक्षित भयो';

  @override
  String get returnsOnlineOnly => 'फिर्ताका लागि इन्टरनेट आवश्यक छ';

  @override
  String get noReturnableQty => 'यस बिलमा फिर्ता गर्न बाँकी परिमाण छैन';

  @override
  String get returnQtyExceeds => 'फिर्ता परिमाण बाँकी भन्दा बढी छ';

  @override
  String get submitReturn => 'फिर्ता पेश गर्नुहोस्';

  @override
  String get emailOrPhone => 'इमेल वा फोन नम्बर';

  @override
  String get invalidEmailOrPhone => 'मान्य इमेल वा फोन नम्बर लेख्नुहोस्';

  @override
  String get forgotPassword => 'पासवर्ड बिर्सनुभयो?';

  @override
  String get forgotPasswordPhoneHint =>
      'फोन लगइनबाट इमेलमार्फत पासवर्ड रिसेट हुँदैन। आफ्नो व्यवसाय मालिकलाई पासवर्ड रिसेट गर्न भन्नुहोस्।';

  @override
  String get resetPasswordEmailHint =>
      'आफ्नो खाताको इमेल लेख्नुहोस्, हामी पासवर्ड रिसेट लिंक पठाउँछौं।';

  @override
  String get sendResetLink => 'रिसेट लिंक पठाउनुहोस्';

  @override
  String get resetEmailSent =>
      'पासवर्ड रिसेट इमेल पठाइयो। आफ्नो इनबक्स हेर्नुहोस्।';

  @override
  String get resetPassword => 'पासवर्ड रिसेट';

  @override
  String resetPasswordFor(String name) {
    return '$name को पासवर्ड रिसेट गर्नुहोस्';
  }

  @override
  String get temporaryPassword => 'अस्थायी पासवर्ड';

  @override
  String get temporaryPasswordHint =>
      'यो पासवर्ड सदस्यलाई दिनुहोस्। अर्को लगइनमा नयाँ पासवर्ड रोज्नुपर्छ।';

  @override
  String get passwordResetDone =>
      'पासवर्ड रिसेट भयो। पुराना सेसनहरू साइन आउट गरियो।';

  @override
  String get newPassword => 'नयाँ पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्ड पुष्टि गर्नुहोस्';

  @override
  String get passwordsDoNotMatch => 'पासवर्डहरू मिलेनन्';

  @override
  String get passwordTooShort => 'पासवर्ड कम्तीमा ८ अक्षरको हुनुपर्छ';

  @override
  String get changePassword => 'पासवर्ड परिवर्तन';

  @override
  String get passwordChanged => 'पासवर्ड अद्यावधिक भयो';

  @override
  String get setNewPasswordTitle => 'नयाँ पासवर्ड सेट गर्नुहोस्';

  @override
  String get setNewPasswordHint =>
      'व्यवसाय मालिकले तपाईंको पासवर्ड रिसेट गर्नुभयो। जारी राख्न नयाँ पासवर्ड रोज्नुहोस्।';

  @override
  String get account => 'खाता';

  @override
  String get deleteAccount => 'मेरो खाता मेटाउनुहोस्';

  @override
  String get deleteAccountWarning =>
      'यसले तपाईंको लगइन स्थायी रूपमा मेटाउँछ। अर्डर र भुक्तानी रेकर्ड व्यवसायसँग रहन्छ। यो फिर्ता गर्न सकिँदैन।';

  @override
  String get deleteBusiness => 'व्यवसाय मेटाउनुहोस्';

  @override
  String get deleteBusinessWarning =>
      'यसले व्यवसाय र सबै डाटा स्थायी रूपमा मेटाउँछ: उत्पादन, बिल, अर्डर, ग्राहक, र सबै लगइनहरू। यो फिर्ता गर्न सकिँदैन।';

  @override
  String typeToConfirm(String word) {
    return 'पुष्टि गर्न $word लेख्नुहोस्';
  }

  @override
  String get accountDeleted => 'खाता मेटाइयो';

  @override
  String get reorder => 'पुनः अर्डर';

  @override
  String get statement => 'विवरण';

  @override
  String get shareStatement => 'विवरण सेयर गर्नुहोस्';

  @override
  String get statementPeriod => 'अवधि';

  @override
  String get statementDate => 'मिति';

  @override
  String get statementDescription => 'विवरण';

  @override
  String get rangeLast30Days => 'पछिल्लो ३० दिन';

  @override
  String get rangeLast90Days => 'पछिल्लो ९० दिन';

  @override
  String get rangeAllTime => 'सबै समय';

  @override
  String get closingBalance => 'अन्तिम मौज्दात';

  @override
  String get shareAsImage => 'फोटोको रूपमा सेयर';

  @override
  String get shareAsPdf => 'PDF को रूपमा सेयर';

  @override
  String get enablePortalAccess => 'पोर्टल लगइन सक्षम गर्नुहोस्';

  @override
  String get moreDetails => 'थप विवरण';

  @override
  String get noSearchResults => 'कुनै मिल्दो परिणाम छैन';

  @override
  String get clearSearch => 'खोज हटाउनुहोस्';

  @override
  String get noRecentActivity => 'हालको गतिविधि छैन';

  @override
  String get emptyFulfillment => 'पूरा गर्नुपर्ने अर्डर छैन';

  @override
  String get syncErrorGeneric =>
      'सिंक गर्न सकिएन। इन्टरनेट जाँच गरी फेरि प्रयास गर्नुहोस्।';

  @override
  String get sidebarExpand => 'साइडबार फुकाउनुहोस्';

  @override
  String get sidebarCollapse => 'साइडबार सानो गर्नुहोस्';

  @override
  String get openMenu => 'मेनु खोल्नुहोस्';
}
