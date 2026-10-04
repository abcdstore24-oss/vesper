import 'dart:math' as math;

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get label => switch (this) {
    RecurrenceFrequency.daily => 'Daily',
    RecurrenceFrequency.weekly => 'Weekly',
    RecurrenceFrequency.monthly => 'Monthly',
    RecurrenceFrequency.yearly => 'Yearly',
  };

  /// CHANGED this task (Bug 4, required fix, overruling the earlier
  /// "deliberate drift" approval): now takes [anchor] — the rule's
  /// startDate, fixed at creation, NEVER recalculated from a drifted
  /// date. Monthly/yearly clamp to the anchor's day (and month, for
  /// yearly) rather than overflowing past it, so no calendar month
  /// is ever silently skipped (the old DateTime(year, month+1, day)
  /// approach could land Aug 31 -> Oct 1, skipping September
  /// entirely — unacceptable for real bills/rent).
  ///
  /// Daily/weekly (Bug 5): switched from Duration addition to
  /// explicit DateTime(year, month, day + n) construction, for
  /// consistency with monthly/yearly and as defensive practice —
  /// functionally identical for date-only values, Dart's DateTime
  /// constructor normalizes an out-of-range day exactly like it
  /// normalizes an out-of-range month.
  DateTime nextAfter(DateTime date, DateTime anchor) => switch (this) {
    RecurrenceFrequency.daily => DateTime(date.year, date.month, date.day + 1),
    RecurrenceFrequency.weekly => DateTime(date.year, date.month, date.day + 7),
    RecurrenceFrequency.monthly => _clampedMonthlyNext(date, anchor.day),
    RecurrenceFrequency.yearly => _clampedYearlyNext(date, anchor.month, anchor.day),
  };
}

/// Worked sequence for a day-31 anchor, confirmed by hand in the task
/// response: Jan 31 -> Feb 28 -> Mar 31 -> Apr 30 -> May 31 -> ...
/// every month represented, anchor day restored whenever the target
/// month is long enough.
DateTime _clampedMonthlyNext(DateTime current, int anchorDay) {
  final nextMonthFirst = DateTime(current.year, current.month + 1, 1);
  // "Day 0 of the month after the target month" = last day of the
  // target month — the standard Dart trick, same one already used
  // elsewhere in this project (e.g. month-end cutoffs).
  final daysInTargetMonth = DateTime(nextMonthFirst.year, nextMonthFirst.month + 1, 0).day;
  final nextDay = math.min(anchorDay, daysInTargetMonth);
  return DateTime(nextMonthFirst.year, nextMonthFirst.month, nextDay);
}

/// Feb 29 anchor clamps to Feb 28 in a non-leap target year, and is
/// correctly restored to Feb 29 in a leap target year — confirmed by
/// hand in the task response, not rolled to Mar 1 the way the old
/// overflow behavior did.
DateTime _clampedYearlyNext(DateTime current, int anchorMonth, int anchorDay) {
  final targetYear = current.year + 1;
  final daysInTargetMonth = DateTime(targetYear, anchorMonth + 1, 0).day;
  final nextDay = math.min(anchorDay, daysInTargetMonth);
  return DateTime(targetYear, anchorMonth, nextDay);
}