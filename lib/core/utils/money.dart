import 'package:intl/intl.dart';

/// All currency amounts are stored as integer paisa (1 NPR = 100 paisa).
/// Never use doubles for money math (see Agent.md).
extension type const Paisa(int value) {
  Paisa operator +(Paisa other) => Paisa(value + other.value);
  Paisa operator -(Paisa other) => Paisa(value - other.value);
  bool get isNegative => value < 0;

  static Paisa fromRupees(num rupees) => Paisa((rupees * 100).round());
  double get rupees => value / 100;
}

/// Formats paisa as NPR with Nepali-style digit grouping (रू 1,23,456.50).
String formatNpr(
  Paisa amount, {
  bool showSymbol = true,
  bool showPaisa = true,
}) {
  final isNegative = amount.isNegative;
  final abs = amount.value.abs();
  final rupees = abs ~/ 100;
  final paisa = abs % 100;

  final grouped = _groupNepali(rupees.toString());
  final paisaPart = showPaisa ? '.${paisa.toString().padLeft(2, '0')}' : '';
  final sign = isNegative ? '-' : '';
  final symbol = showSymbol ? 'रू ' : '';
  return '$sign$symbol$grouped$paisaPart';
}

/// Nepali/Indian grouping: last 3 digits, then groups of 2 (12,34,567).
String _groupNepali(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}

/// Parses user input like "1,23,456.50" into paisa. Returns null if invalid.
Paisa? parseNpr(String input) {
  final cleaned = input.replaceAll(',', '').replaceAll('रू', '').trim();
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null) return null;
  return Paisa.fromRupees(value);
}

final qtyFormat = NumberFormat('#,##0.###');
