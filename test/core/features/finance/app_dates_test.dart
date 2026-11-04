import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/utils/app_dates.dart';

void main() {
  final now = DateTime(2026, 10, 17, 15, 30);

  group('AppDates.format', () {
    test('Today, whatever the time of day', () {
      expect(AppDates.format(DateTime(2026, 10, 17, 0, 5), now: now), 'Today');
      expect(AppDates.format(now, now: now), 'Today');
      expect(
        AppDates.format(DateTime(2026, 10, 17, 23, 59, 59), now: now),
        'Today',
      );
    });

    test('Yesterday, including across month and year boundaries', () {
      expect(
        AppDates.format(DateTime(2026, 10, 16, 23, 59), now: now),
        'Yesterday',
      );
      expect(
        AppDates.format(
          DateTime(2026, 2, 28, 8),
          now: DateTime(2026, 3, 1, 9),
        ),
        'Yesterday',
      );
      expect(
        AppDates.format(
          DateTime(2025, 12, 31, 20),
          now: DateTime(2026, 1, 1, 7),
        ),
        'Yesterday',
      );
    });

    test('same year: day and month', () {
      expect(AppDates.format(DateTime(2026, 10, 5), now: now), '5 Oct');
      expect(AppDates.format(DateTime(2026, 10, 15), now: now), '15 Oct');
      expect(AppDates.format(DateTime(2026, 1, 1), now: now), '1 Jan');
    });

    test('other year: day, month and year', () {
      expect(AppDates.format(DateTime(2025, 10, 5), now: now), '5 Oct 2025');
      expect(AppDates.format(DateTime(2025, 12, 31), now: now), '31 Dec 2025');
      expect(AppDates.format(DateTime(2024, 2, 29), now: now), '29 Feb 2024');
    });

    test('all twelve month names', () {
      const names = [
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
      final december = DateTime(2026, 12, 31);
      for (var month = 1; month <= 12; month++) {
        expect(
          AppDates.format(DateTime(2026, month, 5), now: december),
          '5 ${names[month - 1]}',
        );
      }
    });

    test('defaults to the real clock when now is omitted', () {
      expect(AppDates.format(DateTime.now()), 'Today');
    });
  });

  group('AppDates.occurredAtFor', () {
    test('today keeps the current time', () {
      final picked = DateTime(2026, 10, 17);
      expect(AppDates.occurredAtFor(picked, now), now);
      expect(identical(AppDates.occurredAtFor(picked, now), now), isTrue);
    });

    test('any other day is stored at 12:00 local', () {
      expect(
        AppDates.occurredAtFor(DateTime(2026, 10, 16), now),
        DateTime(2026, 10, 16, 12),
      );
      expect(
        AppDates.occurredAtFor(DateTime(2025, 1, 3), now),
        DateTime(2025, 1, 3, 12),
      );
    });

    test('the time part of the picked date is ignored', () {
      expect(
        AppDates.occurredAtFor(DateTime(2026, 10, 16, 23, 59), now),
        DateTime(2026, 10, 16, 12),
      );
      expect(AppDates.occurredAtFor(DateTime(2026, 10, 17, 1), now), now);
    });
  });
}
