import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Currency and price formatting utilities
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _currencyFormatDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format as "₹50"
  static String format(double amount) => _currencyFormat.format(amount);

  /// Format as "₹50.00"
  static String formatDecimal(double amount) => _currencyFormatDecimal.format(amount);

  /// Format as "₹50/day"
  static String perDay(double amount) => '${format(amount)}/day';

  /// Calculate total cost: days × price/day
  static double totalCost(double pricePerDay, int days) => pricePerDay * days;

  /// Format total cost display: "₹150 (3 days × ₹50/day)"
  static String costBreakdown(double pricePerDay, int days) {
    final total = totalCost(pricePerDay, days);
    return '${format(total)} ($days days × ${perDay(pricePerDay)})';
  }

  /// Format earnings estimate: "You could earn ₹400/month"
  static String earningsEstimate(double pricePerDay) {
    final estimate = pricePerDay * AppConstants.avgRentalDaysPerMonth;
    return 'You could earn ${format(estimate)}/month';
  }
}
