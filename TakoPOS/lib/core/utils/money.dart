import 'package:equatable/equatable.dart';

/// Value object representing monetary amounts.
/// Stores values as cents (integer) to avoid floating-point precision issues.
class Money extends Equatable {
  final int cents;

  const Money._(this.cents);

  /// Create a Money instance with zero value.
  const Money.zero() : cents = 0;

  /// Create from cents (integer).
  factory Money.fromCents(int cents) => Money._(cents);

  /// Create from a decimal amount (e.g., 10.50 for $10.50).
  factory Money.fromDouble(double amount) => Money._((amount * 100).round());

  /// Convert to decimal representation.
  double toDouble() => cents / 100;

  /// Addition
  Money operator +(Money other) => Money._(cents + other.cents);

  /// Subtraction
  Money operator -(Money other) => Money._(cents - other.cents);

  /// Multiplication by a scalar (for quantity calculations)
  Money operator *(num factor) => Money._((cents * factor).round());

  /// Division by a scalar
  Money operator /(num divisor) => Money._((cents / divisor).round());

  /// Unary minus (negation)
  Money operator -() => Money._(-cents);

  /// Comparison operators
  bool operator <(Money other) => cents < other.cents;
  bool operator <=(Money other) => cents <= other.cents;
  bool operator >(Money other) => cents > other.cents;
  bool operator >=(Money other) => cents >= other.cents;

  /// Check if this money is positive (> 0)
  bool get isPositive => cents > 0;

  /// Check if this money is negative (< 0)
  bool get isNegative => cents < 0;

  /// Check if this money is zero
  bool get isZero => cents == 0;

  /// Get absolute value
  Money get abs => Money._(cents.abs());

  /// Calculate percentage of this amount
  Money percentage(double percent) => Money._((cents * percent / 100).round());

  /// Format as currency string with symbol (default: $)
  String format({String symbol = '\$', bool showCents = true}) {
    final isNeg = cents < 0;
    final absCents = cents.abs();
    final dollars = absCents ~/ 100;
    final remainder = absCents % 100;

    final dollarsStr = dollars.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    if (showCents) {
      final centsStr = remainder.toString().padLeft(2, '0');
      return '${isNeg ? '-' : ''}$symbol$dollarsStr.$centsStr';
    } else {
      return '${isNeg ? '-' : ''}$symbol$dollarsStr';
    }
  }

  /// Format without symbol (for input fields)
  String formatWithoutSymbol({bool showCents = true}) {
    return format(symbol: '', showCents: showCents);
  }

  /// Parse from a string (e.g., "10.50" or "1,234.56")
  static Money? tryParse(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      if (cleaned.isEmpty) return null;
      final amount = double.parse(cleaned);
      return Money.fromDouble(amount);
    } catch (_) {
      return null;
    }
  }

  /// Parse from string or throw
  static Money parse(String value) {
    final result = tryParse(value);
    if (result == null) {
      throw FormatException('Invalid money format: $value');
    }
    return result;
  }

  @override
  List<Object?> get props => [cents];

  @override
  String toString() => format();
}

/// Extension for easier Money creation from numbers
extension MoneyExtension on num {
  /// Convert number to Money (treats as dollars)
  Money get dollars => Money.fromDouble(toDouble());

  /// Convert number to Money (treats as cents)
  Money get cents => Money.fromCents(toInt());
}
