import 'package:intl/intl.dart';

/// All currency amounts are stored as integer paisa (1 NPR = 100 paisa).
/// Never use doubles for money math (see Agent.md).
extension type const Paisa(int value) {
  Paisa operator +(Paisa other) => Paisa(value + other.value);
  Paisa operator -(Paisa other) => Paisa(value - other.value);
  bool get isNegative => value < 0;

  /// Legacy numeric API, retaining its rounding behavior for compatibility.
  /// User-entered currency must use [parseNpr], not a double conversion.
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

/// Largest exact integer shared by native Dart and JavaScript builds.
const maxExactPaisa = 9007199254740991;

/// Parses user input like "1,23,456.50" into paisa. Returns null if invalid.
/// Accepts Nepali/Western grouping and Devanagari digits, but never rounds:
/// at most two fractional digits are allowed. Scientific/nonfinite notation
/// and values outside the portable exact-integer range are rejected.
Paisa? parseNpr(String input) {
  if (input.length > 256) return null;
  final normalized = input.trim().replaceAllMapped(
    RegExp('[०-९]'),
    (match) => (match[0]!.codeUnitAt(0) - 0x0966).toString(),
  );
  final match = RegExp(
    r'^([+-]?)(?:रू\s*|NPR\s*)?([+-]?)([0-9][0-9,]*|)(?:\.([0-9]{1,2}))?$',
  ).firstMatch(normalized);
  if (match == null) return null;
  final signBefore = match[1]!;
  final signAfter = match[2]!;
  if (signBefore.isNotEmpty && signAfter.isNotEmpty) return null;
  final whole = match[3]!;
  final fraction = match[4];
  if (whole.isEmpty && fraction == null) return null;
  if (whole.contains(',') &&
      !RegExp(r'^[0-9]{1,3}(?:,[0-9]{3})+$').hasMatch(whole) &&
      !RegExp(r'^[0-9]{1,2}(?:,[0-9]{2})*,[0-9]{3}$').hasMatch(whole)) {
    return null;
  }
  final digits = whole.isEmpty ? '0' : whole.replaceAll(',', '');
  final magnitude =
      BigInt.parse(digits) * BigInt.from(100) +
      BigInt.parse((fraction ?? '').padRight(2, '0'));
  if (magnitude > BigInt.from(maxExactPaisa)) return null;
  final value = magnitude.toInt();
  return Paisa(signBefore == '-' || signAfter == '-' ? -value : value);
}

final qtyFormat = NumberFormat('#,##0.###');
