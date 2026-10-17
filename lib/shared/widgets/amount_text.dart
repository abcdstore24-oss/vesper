import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';

/// How an amount is coloured.
enum AmountTone { neutral, positive, negative }

/// A money amount on ONE line, shrunk to fit and never truncated.
///
/// - The text is always `Money.format(paise)`: exactly 2 decimals, Indian
///   grouping, never rounded or trimmed.
/// - It is wrapped in a `FittedBox(fit: scaleDown)`, so a long amount gets
///   smaller instead of wrapping, clipping or showing an ellipsis.
/// - If `Money.format` throws [ArgumentError] (|paise| > Money.maxPaise,
///   possible for a SUM of accounts) it shows [tooLargeText]. It never
///   crashes.
/// - Colours: neutral = onSurface; negative = danger; positive = success.
///   ColorScheme has no success slot, so success/danger come from
///   [AppColors] by brightness (no ThemeExtension added).
/// - [style] should be a Fraunces theme style (headline/title). It
///   defaults to `textTheme.titleMedium`.
///
/// Registered in COMPONENTS.md.
class AmountText extends StatelessWidget {
  const AmountText(
    this.paise, {
    super.key,
    this.style,
    this.tone = AmountTone.neutral,
    this.alignment = AlignmentDirectional.centerStart,
  });

  /// Shown instead of an amount that is too large to format.
  static const String tooLargeText = 'Amount too large';

  final int paise;
  final TextStyle? style;
  final AmountTone tone;

  /// Where the text sits when it does not need to shrink (e.g.
  /// `Alignment.centerRight` for a trailing amount).
  final AlignmentGeometry alignment;

  /// The text this widget shows for [paise].
  static String textFor(int paise) {
    try {
      return Money.format(paise);
    } on ArgumentError {
      return tooLargeText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final color = switch (tone) {
      AmountTone.neutral => theme.colorScheme.onSurface,
      AmountTone.positive => palette.success,
      AmountTone.negative => palette.danger,
    };
    final base = style ?? theme.textTheme.titleMedium ?? const TextStyle();

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        textFor(paise),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: base.copyWith(color: color),
      ),
    );
  }
}
