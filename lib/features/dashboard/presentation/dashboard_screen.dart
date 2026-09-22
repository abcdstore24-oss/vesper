import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/dashboard_card.dart';
import '../data/user_profile_dao.dart';

/// Dashboard tab — CLAUDE.md Section 1, item 10.
///
/// Static layout: only the greeting card is wired to real data
/// (user_profile.birthdate, the one field that already exists). The
/// other 6 cards are honest empty states — their tables don't exist
/// until later TODO.md phases build them.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _greetingCard(profileAsync),
          const SizedBox(height: AppSpacing.lg),
          DashboardCard.emptyState(
            icon: PhosphorIconsRegular.checkSquare,
            title: "Today's Tasks",
            message:
                "No tasks yet — you'll be able to add some once Task "
                'management is built.',
          ),
          const SizedBox(height: AppSpacing.lg),
          DashboardCard.emptyState(
            icon: PhosphorIconsRegular.cake,
            title: 'Upcoming Birthdays',
            message:
                "No birthdays yet — you'll be able to add people once "
                'the Birthday & Event manager is built.',
          ),
          const SizedBox(height: AppSpacing.lg),
          DashboardCard.emptyState(
            icon: PhosphorIconsRegular.wallet,
            title: 'Financial Summary',
            message:
                'No financial data yet — this fills in once Finance '
                'accounts and transactions are built.',
          ),
          const SizedBox(height: AppSpacing.lg),
          DashboardCard.emptyState(
            icon: PhosphorIconsRegular.target,
            title: 'Goal Progress',
            message:
                "No goals yet — you'll be able to set some once Goal "
                'tracking is built.',
          ),
          const SizedBox(height: AppSpacing.lg),
          DashboardCard.emptyState(
            icon: PhosphorIconsRegular.fire,
            title: 'Habit Tracking',
            message:
                "No habits yet — you'll be able to track some once "
                'Healthy Lifestyle is built.',
          ),
          const SizedBox(height: AppSpacing.lg),
          DashboardCard.emptyState(
            icon: PhosphorIconsRegular.star,
            title: 'Wishlist Highlights',
            message:
                "No wishlist items yet — you'll be able to add some "
                'once the Purchase Planner is built.',
          ),
        ],
      ),
    );
  }

  Widget _greetingCard(AsyncValue<UserProfileRow?> profileAsync) {
    return profileAsync.when(
      data: (profile) {
        final birthdate = profile?.birthdate;
        if (birthdate == null) {
          return DashboardCard.emptyState(
            icon: PhosphorIconsRegular.moonStars,
            title: _greetingForNow(),
            message: 'Add your birthdate in Settings to see this.',
          );
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final bday = DateTime(
          birthdate.year,
          birthdate.month,
          birthdate.day,
        );
        final age = _calculateAge(bday, today);
        final daysUntil = _daysUntilNextBirthday(bday, today);
        final dayWord = daysUntil == 1 ? 'day' : 'days';
        final message = daysUntil == 0
            ? "It's your birthday today — happy $age! 🎉"
            : '$age years old · $daysUntil $dayWord until your next birthday';

        return DashboardCard.emptyState(
          icon: PhosphorIconsRegular.moonStars,
          title: _greetingForNow(),
          message: message,
        );
      },
      loading: () => DashboardCard.emptyState(
        icon: PhosphorIconsRegular.moonStars,
        title: _greetingForNow(),
        message: 'Loading…',
      ),
      error: (error, stackTrace) => DashboardCard.emptyState(
        icon: PhosphorIconsRegular.moonStars,
        title: _greetingForNow(),
        message: "Couldn't load your profile.",
      ),
    );
  }
}

/// Time-of-day greeting. Not a locked CLAUDE.md value — dynamic
/// morning/afternoon/evening greeting is the standard convention this
/// pattern implies. Flagged as an interpretation, not a spec.
String _greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

/// Age in whole years, as of [today]. Both [birthdate] and [today] must
/// already be date-only (no time component) — callers normalize before
/// calling this.
int _calculateAge(DateTime birthdate, DateTime today) {
  var age = today.year - birthdate.year;
  final hasHadBirthdayThisYear =
      today.month > birthdate.month ||
      (today.month == birthdate.month && today.day >= birthdate.day);
  if (!hasHadBirthdayThisYear) age -= 1;
  return age;
}

/// Days until the next occurrence of [birthdate]'s month/day, counting
/// from [today] (0 if today IS the birthday). Both must be date-only.
///
/// Leap-year note: for a Feb 29 birthdate, `DateTime(year, 2, 29)` in a
/// non-leap year overflows to March 1 (Dart's DateTime constructor
/// normalizes out-of-range days rather than throwing) — so a Feb 29
/// birthday is observed on March 1 in non-leap years. Deliberate,
/// flagged convention, not an accident — see task response.
int _daysUntilNextBirthday(DateTime birthdate, DateTime today) {
  var next = DateTime(today.year, birthdate.month, birthdate.day);
  if (next.isBefore(today)) {
    next = DateTime(today.year + 1, birthdate.month, birthdate.day);
  }
  return next.difference(today).inDays;
}
