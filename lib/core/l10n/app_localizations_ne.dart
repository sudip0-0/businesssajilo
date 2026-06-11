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
}
