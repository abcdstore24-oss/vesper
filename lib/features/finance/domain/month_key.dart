const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// 'YYYY-MM', e.g. '2026-09' — the TEXT format budgets.month is
/// stored in, per DATABASE.md locked decision 3.
String monthKeyFor(int year, int month) =>
    '$year-${month.toString().padLeft(2, '0')}';

String currentMonthKey() {
  final now = DateTime.now();
  return monthKeyFor(now.year, now.month);
}

/// Parses 'YYYY-MM' back into (year, month).
(int year, int month) parseMonthKey(String key) {
  final parts = key.split('-');
  return (int.parse(parts[0]), int.parse(parts[1]));
}

/// One month before [key] — January rolls back to December of the
/// previous year. Computed by hand here (not via DateTime's
/// auto-normalize trick used in MonthSummary) since the input/output
/// are both string keys, not DateTime values.
String previousMonthKey(String key) {
  final (year, month) = parseMonthKey(key);
  return month == 1 ? monthKeyFor(year - 1, 12) : monthKeyFor(year, month - 1);
}

/// One month after [key] — December rolls forward to January of the
/// next year.
String nextMonthKey(String key) {
  final (year, month) = parseMonthKey(key);
  return month == 12 ? monthKeyFor(year + 1, 1) : monthKeyFor(year, month + 1);
}

/// Display label, e.g. 'September 2026'.
String monthKeyLabel(String key) {
  final (year, month) = parseMonthKey(key);
  return '${_monthNames[month - 1]} $year';
}