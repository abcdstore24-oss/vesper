/// Date helpers for the UI. Month names are written out by hand (no intl).
///
/// Pure functions of their arguments; pass `now` in tests.
abstract final class AppDates {
  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "Today", "Yesterday", "5 Oct" (same year as [now]) or "5 Oct 2025".
  ///
  /// Calendar days in local time; the time of day is ignored. A date after
  /// today is shown as a plain date (the app does not allow future entries).
  static String format(DateTime date, {DateTime? now}) {
    final day = _local(date);
    final today = _local(now ?? DateTime.now());

    if (_sameDay(day, today)) return 'Today';
    if (_sameDay(day, DateTime(today.year, today.month, today.day - 1))) {
      return 'Yesterday';
    }

    final text = '${day.day} ${_months[day.month - 1]}';
    return day.year == today.year ? text : '$text ${day.year}';
  }

  /// The moment to store for a date picked in the form.
  ///
  /// Picking today keeps the current time, so entries made today sort in the
  /// order they were added. Any other (past) day is stored at 12:00 local.
  static DateTime occurredAtFor(DateTime pickedDate, DateTime now) {
    final picked = _local(pickedDate);
    final today = _local(now);
    if (_sameDay(picked, today)) return now;
    return DateTime(picked.year, picked.month, picked.day, 12);
  }

  static DateTime _local(DateTime d) => d.isUtc ? d.toLocal() : d;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
