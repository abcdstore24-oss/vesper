import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart'; // NEW this task — see note above.
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/budgets_dao.dart';
import '../data/categories_dao.dart';
import '../data/investment_snapshots_dao.dart'; // NEW — allInvestmentSnapshotsProvider
import '../data/transactions_dao.dart';
import '../domain/category_kind.dart'; // NEW — CategoryKind.income, for transaction signing
import '../domain/category_style.dart';
import '../domain/month_key.dart';
import '../domain/month_summary.dart';
import '../data/accounts_dao.dart';

const _shortMonthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// 6 groups x 2 bars = 12 bars: legible on a phone width without
/// cramping; 12 months would compress each bar too far to read.
const _monthsShown = 6;

/// Last [_monthsShown] calendar months INCLUDING the current one,
/// oldest first (left to right on the chart). Shared by the trend and
/// net worth sections.
List<(int, int)> _lastMonths() {
  final now = DateTime.now();
  var year = now.year;
  var month = now.month;
  final result = <(int, int)>[];
  for (var i = 0; i < _monthsShown; i++) {
    result.add((year, month));
    if (month == 1) {
      month = 12;
      year -= 1;
    } else {
      month -= 1;
    }
  }
  return result.reversed.toList();
}

/// Charts tab: a thin scrolling shell over three independent sections.
/// Each section owns its own loading/error/empty states, so none of
/// them can hide the others.
class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        _TrendSection(),
        SizedBox(height: AppSpacing.xl),
        _SpendingByCategorySection(),
        SizedBox(height: AppSpacing.xl),
        _NetWorthSection(),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Income vs expense trend
// ---------------------------------------------------------------------

class _ChartPoint {
  const _ChartPoint({
    required this.year,
    required this.month,
    required this.summary,
    required this.incomeDollars,
    required this.expenseDollars,
  });

  factory _ChartPoint.fromSummary((int, int) key, MonthSummary summary) {
    return _ChartPoint(
      year: key.$1,
      month: key.$2,
      summary: summary,
      incomeDollars: summary.totalIncomeCents / 100,
      expenseDollars: summary.totalExpenseCents / 100,
    );
  }

  final int year;
  final int month;
  final MonthSummary summary;
  final double incomeDollars;
  final double expenseDollars;

  String get shortLabel => _shortMonthNames[month - 1];
}

class _TrendSection extends ConsumerStatefulWidget {
  const _TrendSection();

  @override
  ConsumerState<_TrendSection> createState() => _TrendSectionState();
}

class _TrendSectionState extends ConsumerState<_TrendSection> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColors.dark.success : AppColors.light.success;
    final dangerColor = isDark ? AppColors.dark.danger : AppColors.light.danger;

    final months = _lastMonths();
    final asyncs = [for (final m in months) ref.watch(monthSummaryProvider(m))];

    final failed = asyncs.where((a) => a.hasError).firstOrNull;
    if (failed != null) {
      return _InlineMessage("Couldn't load chart data: ${failed.error}");
    }
    if (asyncs.any((a) => !a.hasValue)) {
      return const _InlineSpinner();
    }

    final summaries = [for (final a in asyncs) a.requireValue];

    if (summaries.every((s) => s.isEmpty)) {
      return const _InlineMessage('Not enough transaction history yet');
    }

    final points = [
      for (var i = 0; i < months.length; i++) _ChartPoint.fromSummary(months[i], summaries[i]),
    ];

    final maxDollars = points.fold<double>(
      0,
      (m, p) => math.max(m, math.max(p.incomeDollars, p.expenseDollars)),
    );
    final (interval, axisMax) = _axisScale(maxDollars * 1.05);

    final labelColor = theme.colorScheme.onSurfaceVariant;
    final gridColor = theme.colorScheme.outline;
    final highlightColor = theme.colorScheme.surfaceContainerHighest;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(color: labelColor);

    final selected = _selectedIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _rangeLabel(points),
          style: theme.textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: successColor, label: 'Income'),
            const SizedBox(width: AppSpacing.lg),
            _LegendItem(color: dangerColor, label: 'Expense'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
            child: SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  minY: 0,
                  maxY: axisMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(color: gridColor, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: interval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(_formatAxisAmount(value), style: labelStyle),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= points.length) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              points[i].shortLabel,
                              style: labelStyle?.copyWith(
                                fontWeight: i == selected ? FontWeight.w700 : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    handleBuiltInTouches: false,
                    allowTouchBarBackDraw: true,
                    touchExtraThreshold: const EdgeInsets.symmetric(horizontal: 4),
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final index = response?.spot?.touchedBarGroupIndex;
                      if (index == null) return;
                      setState(() => _selectedIndex = _selectedIndex == index ? null : index);
                    },
                  ),
                  barGroups: [
                    for (var i = 0; i < points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 4,
                        barRods: [
                          _rod(points[i].incomeDollars, successColor, i == selected, axisMax, highlightColor),
                          _rod(points[i].expenseDollars, dangerColor, i == selected, axisMax, highlightColor),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Current month is month-to-date.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (selected == null)
          Text(
            'Tap a month for exact figures.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          )
        else
          _MonthDetailCard(
            point: points[selected],
            successColor: successColor,
            dangerColor: dangerColor,
          ),
      ],
    );
  }

  BarChartRodData _rod(
    double toY,
    Color color,
    bool isSelected,
    double axisMax,
    Color highlightColor,
  ) {
    return BarChartRodData(
      toY: toY,
      color: color,
      width: 12,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: axisMax,
        color: isSelected ? highlightColor : Colors.transparent,
      ),
    );
  }

  String _rangeLabel(List<_ChartPoint> points) {
    final first = points.first;
    final last = points.last;
    if (first.year == last.year) {
      return '${first.shortLabel} – ${last.shortLabel} ${last.year}';
    }
    return '${first.shortLabel} ${first.year} – ${last.shortLabel} ${last.year}';
  }
}

/// Interval-first axis scaling. Shared by the trend section and (this
/// task) net worth — already file-scope, so no extraction was needed.
(double interval, double axisMax) _axisScale(double target) {
  if (target <= 0) return (1.0, 1.0);

  final startExponent = (math.log(target) / math.ln10).floor() - 1;
  for (var e = startExponent; ; e++) {
    final magnitude = math.pow(10, e).toDouble();
    for (final mult in const [1.0, 2.0, 5.0]) {
      final interval = mult * magnitude;
      final steps = (target / interval - 1e-9).ceil();
      if (steps <= 6) {
        final count = steps < 1 ? 1 : steps;
        return (interval, interval * count);
      }
    }
  }
}

String _formatAxisAmount(double v) {
  final abs = v.abs();
  if (abs >= 1000000) return '${_trimOneDecimal(v / 1000000)}M';
  if (abs >= 1000) return '${_trimOneDecimal(v / 1000)}k';
  return _trimOneDecimal(v);
}

String _trimOneDecimal(double x) {
  final s = x.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _MonthDetailCard extends StatelessWidget {
  const _MonthDetailCard({
    required this.point,
    required this.successColor,
    required this.dangerColor,
  });

  final _ChartPoint point;
  final Color successColor;
  final Color dangerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = point.summary;
    final net = summary.netCents;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(monthKeyLabel(monthKeyFor(point.year, point.month)), style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _FigureCell(
                    label: 'Income',
                    cents: summary.totalIncomeCents,
                    color: successColor,
                    signPrefix: '+',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FigureCell(
                    label: 'Expense',
                    cents: summary.totalExpenseCents,
                    color: dangerColor,
                    signPrefix: '-',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FigureCell(
                    label: 'Net',
                    cents: net,
                    color: net >= 0 ? successColor : dangerColor,
                    signPrefix: net >= 0 ? '+' : '-',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FigureCell extends StatelessWidget {
  const _FigureCell({
    required this.label,
    required this.cents,
    required this.color,
    required this.signPrefix,
  });

  final String label;
  final int cents;
  final Color color;
  final String signPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decimal = (cents.abs() / 100).toStringAsFixed(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$signPrefix$decimal',
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Spending by category
// ---------------------------------------------------------------------

class _SpendingSlice {
  const _SpendingSlice({required this.name, required this.color, required this.cents});

  final String name;
  final Color color;
  final int cents;
}

class _SpendingByCategorySection extends ConsumerStatefulWidget {
  const _SpendingByCategorySection();

  @override
  ConsumerState<_SpendingByCategorySection> createState() => _SpendingByCategorySectionState();
}

class _SpendingByCategorySectionState extends ConsumerState<_SpendingByCategorySection> {
  late String _monthKey;

  @override
  void initState() {
    super.initState();
    _monthKey = currentMonthKey();
  }

  void _goPrevMonth() => setState(() => _monthKey = previousMonthKey(_monthKey));
  void _goNextMonth() => setState(() => _monthKey = nextMonthKey(_monthKey));

  @override
  Widget build(BuildContext context) {
    ref.watch(categoriesSeedProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final spentAsync = ref.watch(categorySpentProvider(_monthKey));
    final categoriesAsync = ref.watch(categoriesProvider);

    final Widget body;
    if (spentAsync.hasError || categoriesAsync.hasError) {
      body = _InlineMessage("Couldn't load spending: ${spentAsync.error ?? categoriesAsync.error}");
    } else if (!spentAsync.hasValue || !categoriesAsync.hasValue) {
      body = const _InlineSpinner();
    } else {
      final spent = spentAsync.requireValue;
      final categoriesById = {for (final c in categoriesAsync.requireValue) c.id: c};

      final slices = <_SpendingSlice>[];
      for (final entry in spent.entries) {
        if (entry.value <= 0) continue;
        final category = categoriesById[entry.key];
        final Color color;
        final String name;
        if (category == null) {
          color = theme.colorScheme.onSurfaceVariant;
          name = 'Category';
        } else {
          final hex = isDark ? CategoryPalette.darkHexFor(category.color) : category.color;
          color = CategoryPalette.colorFromHex(hex);
          name = category.name;
        }
        slices.add(_SpendingSlice(name: name, color: color, cents: entry.value));
      }
      slices.sort((a, b) {
        final byAmount = b.cents.compareTo(a.cents);
        return byAmount != 0 ? byAmount : a.name.compareTo(b.name);
      });

      body = slices.isEmpty
          ? _InlineMessage('No spending in ${monthKeyLabel(_monthKey)}')
          : _SpendingBreakdown(slices: slices);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Spending by category', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _goPrevMonth, icon: const Icon(Icons.chevron_left)),
                Text(monthKeyLabel(_monthKey), style: theme.textTheme.titleMedium),
                IconButton(onPressed: _goNextMonth, icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            body,
          ],
        ),
      ),
    );
  }
}

class _SpendingBreakdown extends StatelessWidget {
  const _SpendingBreakdown({required this.slices});

  final List<_SpendingSlice> slices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCents = slices.fold<int>(0, (sum, s) => sum + s.cents);
    final totalDecimal = (totalCents / 100).toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: slices.length == 1 ? 0 : 2,
                    centerSpaceRadius: 60,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(enabled: false),
                    sections: [
                      for (final s in slices)
                        PieChartSectionData(
                          value: s.cents.toDouble(),
                          color: s.color,
                          radius: 28,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 88,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Spent',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(totalDecimal, style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final s in slices) _SpendingLegendRow(slice: s, totalCents: totalCents),
      ],
    );
  }
}

class _SpendingLegendRow extends StatelessWidget {
  const _SpendingLegendRow({required this.slice, required this.totalCents});

  final _SpendingSlice slice;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decimal = (slice.cents / 100).toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              slice.name,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(decimal, style: theme.textTheme.bodyMedium),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              _percentLabel(slice.cents, totalCents),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

String _percentLabel(int cents, int totalCents) {
  if (cents * 100 < totalCents) return '<1%';
  return '${(cents * 100 + totalCents ~/ 2) ~/ totalCents}%';
}

// ---------------------------------------------------------------------
// Net worth (NEW this task)
// ---------------------------------------------------------------------

class _NetWorthPoint {
  const _NetWorthPoint({required this.year, required this.month, required this.netWorthCents});

  final int year;
  final int month;
  final int netWorthCents;

  String get shortLabel => _shortMonthNames[month - 1];
  double get dollars => netWorthCents / 100;
}

class _NetWorthSection extends ConsumerStatefulWidget {
  const _NetWorthSection();

  @override
  ConsumerState<_NetWorthSection> createState() => _NetWorthSectionState();
}

class _NetWorthSectionState extends ConsumerState<_NetWorthSection> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Not income/expense-coded, so success/danger's usual "which of
    // two opposing things" meaning doesn't directly apply. Using
    // success as the line's base color — net worth trending reads
    // positively by convention in most finance apps, and this stays
    // within the locked token set rather than reaching for accent
    // (reserved for CTAs/active states, not decorative chart lines —
    // the one carved-out exception in CLAUDE.md Section 3 is
    // specifically for category colors, not this).
    final lineColor = isDark ? AppColors.dark.success : AppColors.light.success;
    final dangerColor = isDark ? AppColors.dark.danger : AppColors.light.danger;
    final successColor = lineColor;

    // Confirmed: investmentsProvider is NOT watched here — dollar
    // figures come entirely from snapshots, and loading/error/empty
    // states are fully covered by these three providers alone.
    final accountsAsync = ref.watch(accountsProvider);
    final transactionsAsync = ref.watch(transactionsProvider(null));
    final snapshotsAsync = ref.watch(allInvestmentSnapshotsProvider);

    if (accountsAsync.hasError) {
      return _InlineMessage("Couldn't load net worth: ${accountsAsync.error}");
    }
    if (transactionsAsync.hasError) {
      return _InlineMessage("Couldn't load net worth: ${transactionsAsync.error}");
    }
    if (snapshotsAsync.hasError) {
      return _InlineMessage("Couldn't load net worth: ${snapshotsAsync.error}");
    }
    if (!accountsAsync.hasValue || !transactionsAsync.hasValue || !snapshotsAsync.hasValue) {
      return const _InlineSpinner();
    }

    final accountList = accountsAsync.requireValue;
    final allTxns = transactionsAsync.requireValue;
    final allSnapshots = snapshotsAsync.requireValue;

    // Equivalent to "every month has zero accounts AND zero
    // investments-with-snapshots" (task response): if there are no
    // accounts and no snapshot rows exist anywhere, no month can
    // possibly have a contributing account or a qualifying
    // investment, so checking this once covers all 6 months.
    if (accountList.isEmpty && allSnapshots.isEmpty) {
      return const _InlineMessage('Not enough data yet for a net worth chart');
    }

    final points = _computeNetWorthPoints(accountList, allTxns, allSnapshots);

    final maxAbs = points.fold<double>(0, (m, p) => math.max(m, p.dollars.abs()));
    final (interval, axisBound) = _axisScale(maxAbs * 1.05);
    final hasNegative = points.any((p) => p.dollars < 0);
    final minY = hasNegative ? -axisBound : 0.0;
    final maxY = axisBound;

    final labelColor = theme.colorScheme.onSurfaceVariant;
    final gridColor = theme.colorScheme.outline;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(color: labelColor);
    final selected = _selectedIndex;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Net worth', style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(color: gridColor, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: interval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(_formatAxisAmount(value), style: labelStyle),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= points.length) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              points[i].shortLabel,
                              style: labelStyle?.copyWith(
                                fontWeight: i == selected ? FontWeight.w700 : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: false,
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final spots = response?.lineBarSpots;
                      if (spots == null || spots.isEmpty) return;
                      final index = spots.first.spotIndex;
                      setState(() => _selectedIndex = _selectedIndex == index ? null : index);
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].dollars)],
                      isCurved: false,
                      color: lineColor,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: index == selected ? 5 : 3,
                          color: lineColor,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Two disclosed limitations, both required, neither swept
            // under the rug.
            Text(
              'Investments only count once they have a recorded value — '
              'earlier months may read lower if fewer investments were tracked yet, '
              'not because net worth dropped.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Deleting an investment removes its history from past months shown here too.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (selected == null)
              Text(
                'Tap a month for the exact figure.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              )
            else
              _NetWorthDetailCard(
                point: points[selected],
                successColor: successColor,
                dangerColor: dangerColor,
              ),
          ],
        ),
      ),
    );
  }

  /// The as-of-date fold — the core of this task. See the class-level
  /// comment below for the exact cutoff rule.
  List<_NetWorthPoint> _computeNetWorthPoints(
    List<AccountRow> accountList,
    List<TransactionRow> allTxns,
    List<InvestmentValueSnapshotRow> allSnapshots,
  ) {
    // Captured exactly once, before the loop — used for every month's
    // cutoff, not re-evaluated per iteration.
    final now = DateTime.now();
    final nowInclusive = now.add(const Duration(seconds: 1));

    final txnsByAccount = <String, List<TransactionRow>>{};
    for (final t in allTxns) {
      txnsByAccount.putIfAbsent(t.accountId, () => []).add(t);
    }

    final snapshotsByInvestment = <String, List<InvestmentValueSnapshotRow>>{};
    for (final s in allSnapshots) {
      snapshotsByInvestment.putIfAbsent(s.investmentId, () => []).add(s);
    }
    for (final list in snapshotsByInvestment.values) {
      list.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    }

    final months = _lastMonths();
    final points = <_NetWorthPoint>[];

    for (final (year, month) in months) {
      // "Month end" cutoff: the earlier of (start of the following
      // calendar month) and (now). For any of the 5 fully-elapsed
      // months, start-of-next-month is always before now, so that's
      // picked — the whole month counts. For the current,
      // still-in-progress month, now is picked instead — this
      // correctly excludes anything dated later this month but after
      // the actual current moment (both the transaction form and the
      // investment funding date pickers allow future dates, so this
      // is a real case, not hypothetical). An entry counts toward
      // this month iff its date is STRICTLY BEFORE this cutoff.
      final startOfNextMonth = DateTime(year, month + 1, 1);
      final cutoffExclusive = startOfNextMonth.isBefore(nowInclusive) ? startOfNextMonth : nowInclusive;

      var accountsCents = 0;
      for (final a in accountList) {
        var balance = a.startingBalanceCents;
        final txns = txnsByAccount[a.id];
        if (txns != null) {
          for (final t in txns) {
            if (t.occurredAt.isBefore(cutoffExclusive)) {
              final signed = t.type == CategoryKind.income.name ? t.amountCents : -t.amountCents;
              balance += signed;
            }
          }
        }
        accountsCents += balance;
      }

      var investmentsCents = 0;
      for (final entry in snapshotsByInvestment.entries) {
        // Sorted ascending — the last one still before the cutoff is
        // the most recent qualifying snapshot. If none qualify, this
        // investment contributes NOTHING to this month (not zero) —
        // it's simply excluded from the sum, per the locked rule.
        InvestmentValueSnapshotRow? latestQualifying;
        for (final s in entry.value) {
          if (s.recordedAt.isBefore(cutoffExclusive)) {
            latestQualifying = s;
          } else {
            break;
          }
        }
        if (latestQualifying != null) {
          investmentsCents += latestQualifying.valueCents;
        }
      }

      points.add(_NetWorthPoint(year: year, month: month, netWorthCents: accountsCents + investmentsCents));
    }

    return points;
  }
}

class _NetWorthDetailCard extends StatelessWidget {
  const _NetWorthDetailCard({
    required this.point,
    required this.successColor,
    required this.dangerColor,
  });

  final _NetWorthPoint point;
  final Color successColor;
  final Color dangerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = point.netWorthCents >= 0;
    final decimal = (point.netWorthCents.abs() / 100).toStringAsFixed(2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(monthKeyLabel(monthKeyFor(point.year, point.month)), style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${isPositive ? '' : '-'}$decimal',
                style: theme.textTheme.titleLarge?.copyWith(color: isPositive ? successColor : dangerColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Shared inline states
// ---------------------------------------------------------------------

class _InlineMessage extends StatelessWidget {
  const _InlineMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _InlineSpinner extends StatelessWidget {
  const _InlineSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}