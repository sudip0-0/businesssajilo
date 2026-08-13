/// Converts a paisa amount to English rupee words for invoice print.
///
/// Uses Indian grouping (lakh / crore). Paisa is dropped so the wording
/// matches [formatNpr] with `showPaisa: false`.
String rupeesInWords(int amountPaisa) {
  final isNegative = amountPaisa < 0;
  final rupees = amountPaisa.abs() ~/ 100;
  final unit = rupees == 1 ? 'rupee' : 'rupees';
  final raw = isNegative ? 'minus ${_inEnglish(rupees)}' : _inEnglish(rupees);
  return '${_capitalize(raw)} $unit.';
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _inEnglish(int n) {
  if (n == 0) return 'zero';

  final parts = <String>[];
  final crore = n ~/ 10000000;
  n %= 10000000;
  final lakh = n ~/ 100000;
  n %= 100000;
  final thousand = n ~/ 1000;
  n %= 1000;

  if (crore > 0) parts.add('${_below1000(crore)} crore');
  if (lakh > 0) parts.add('${_below1000(lakh)} lakh');
  if (thousand > 0) parts.add('${_below1000(thousand)} thousand');
  if (n > 0) parts.add(_below1000(n));
  return parts.join(' ');
}

String _below1000(int n) {
  final hundred = n ~/ 100;
  final rest = n % 100;
  final bits = <String>[];
  if (hundred > 0) bits.add('${_ones[hundred]} hundred');
  if (rest > 0) bits.add(_below100(rest));
  return bits.join(' ');
}

String _below100(int n) {
  if (n < 10) return _ones[n];
  if (n < 20) return _teens[n - 10];
  final ten = n ~/ 10;
  final one = n % 10;
  if (one == 0) return _tens[ten];
  return '${_tens[ten]}-${_ones[one]}';
}

const _ones = [
  '',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
];

const _teens = [
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
];

const _tens = [
  '',
  '',
  'twenty',
  'thirty',
  'forty',
  'fifty',
  'sixty',
  'seventy',
  'eighty',
  'ninety',
];
