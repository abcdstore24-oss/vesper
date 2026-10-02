import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/nav_index_provider.dart';
import '../../../core/db/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/dashboard_card.dart';
import '../../finance/data/accounts_dao.dart'; // NEW — cross-feature import, first instance in this project (see task response)
import '../../finance/data/investments_dao.dart'; // NEW
import '../../finance/data/transactions_dao.dart'; // NEW
import '../../settings/presentation/settings_screen.dart';
import '../data/user_profile_dao.dart';

/// Dashboard tab — CLAUDE.md Section 1, item 10.
///
/// Static layout: only the greeting card and (as of this task) the
/// Financial Summary card are wired to real data. The remaining 5
/// cards are honest empty states — their tables don't exist until
/// later TODO.md phases build them.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIconsRegular.gearSix),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
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
          // CHANGED this task — was a static DashboardCard.emptyState
          // ("No financial data yet..."). Now wired to real data via
          // the existing Finance providers (accountsProvider,
          // accountBalancesProvider, investmentsProvider,
          // monthSummaryProvider) — no new provider, no duplicated
          // sum logic. Tapping switches to the Finance tab via the
          // same navIndexProvider the bottom NavigationBar itself
          // uses.
          const _FinancialSummaryCard(),
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

/// NEW this task. Reuses accountsProvider, accountBalancesProvider,
/// investmentsProvider (lib/features/finance/data/accounts_dao.dart,
/// investments_dao.dart) and monthSummaryProvider
/// (lib/features/finance/data/transactions_dao.dart) directly — same
/// live net-worth formula as Finance home's Net Worth glance card,
/// same current-month formula as its Month glance card. No new
/// provider, no recomputation of the sums elsewhere.
class _FinancialSummaryCard extends ConsumerWidget {
  const _FinancialSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColors.dark.success : AppColors.light.success;
    final dangerColor = isDark ? AppColors.dark.danger : AppColors.light.danger;

    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final investmentsAsync = ref.watch(investmentsProvider);
    final now = DateTime.now();
    final summaryAsync = ref.watch(monthSummaryProvider((now.year, now.month)));

    Widget body;
    if (accountsAsync.hasError ||
        balancesAsync.hasError ||
        investmentsAsync.hasError ||
        summaryAsync.hasError) {
      body = Text(
        "Couldn't load financial data",
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    } else if (!accountsAsync.hasValue ||
        !balancesAsync.hasValue ||
        !investmentsAsync.hasValue ||
        !summaryAsync.hasValue) {
      // No zero-fallback while loading — same discipline as every
      // other screen in this project.
      body = const SizedBox(
        height: 32,
        child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    } else {
      final accounts = accountsAsync.requireValue;
      final balances = balancesAsync.requireValue;
      final investments = investmentsAsync.requireValue;
      final summary = summaryAsync.requireValue;

      var netWorthCents = 0;
      for (final a in accounts) {
        netWorthCents += a.startingBalanceCents + (balances[a.id] ?? 0);
      }
      for (final inv in investments) {
        netWorthCents += inv.currentValueCents;
      }

      final netWorthDecimal = (netWorthCents.abs() / 100).toStringAsFixed(2);
      final monthNet = summary.netCents;
      final monthNetDecimal = (monthNet.abs() / 100).toStringAsFixed(2);

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Net worth',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${netWorthCents < 0 ? '-' : ''}$netWorthDecimal',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'This month',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${monthNet >= 0 ? '+' : '-'}$monthNetDecimal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: monthNet >= 0 ? successColor : dangerColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Inc ${(summary.totalIncomeCents / 100).toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Exp ${(summary.totalExpenseCents / 100).toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return InkWell(
      // Same existing mechanism the bottom NavigationBar itself uses
      // — not a new navigation pattern (task response).
      onTap: () => ref.read(navIndexProvider.notifier).setIndex(1),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: DashboardCard(
        icon: PhosphorIconsRegular.wallet,
        title: 'Financial Summary',
        child: body,
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