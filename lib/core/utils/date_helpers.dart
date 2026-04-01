import 'package:intl/intl.dart';

/// Date formatting utilities
class DateHelpers {
  DateHelpers._();

  static final _dayMonth = DateFormat('dd MMM');
  static final _dayMonthYear = DateFormat('dd MMM yyyy');
  static final _fullDate = DateFormat('EEEE, dd MMM yyyy');
  static final _timeOnly = DateFormat('hh:mm a');

  /// Format as "12 Mar"
  static String shortDate(DateTime date) => _dayMonth.format(date);

  /// Format as "12 Mar 2026"
  static String mediumDate(DateTime date) => _dayMonthYear.format(date);

  /// Format as "Wednesday, 12 Mar 2026"
  static String fullDate(DateTime date) => _fullDate.format(date);

  /// Format as "02:30 PM"
  static String time(DateTime date) => _timeOnly.format(date);

  /// Calculate days between two dates
  static int daysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  /// Relative time (e.g., "2 hours ago", "just now")
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return shortDate(date);
  }

  /// Format rental period: "12 Mar – 15 Mar"
  static String rentalPeriod(DateTime start, DateTime end) {
    return '${shortDate(start)} – ${shortDate(end)}';
  }
}
