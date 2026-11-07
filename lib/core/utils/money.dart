/// The single place Vesper parses and displays money.
///
/// Money is an `int` count of paise (1 rupee = 100 paise). INR only.
/// Every calculation here is integer arithmetic. Display is always exactly
/// two decimals, never trimmed and never rounded. Input with more than two
/// decimals is rejected, not rounded.
abstract final class Money {
  /// The rupee sign (U+20B9). The only place to change it.
  static const String rupeeSymbol = '\u20B9';

  /// Largest absolute amount accepted: 10^14 paise, i.e. 10^12 rupees
  /// (10,00,00,00,00,000.00 in Indian grouping).
  static const int maxPaise = 100000000000000;

  // maxPaise ~/ 100 is 10^12 rupees, which has 13 digits.
  static const int _maxRupeeDigits = 13;

  // The only comma layouts parse() accepts in the whole-number part, checked
  // on the raw text BEFORE the commas are removed. Western: 1,250  100,000
  // 1,234,567. Indian: 1,250  12,34,567  1,00,00,000. Anything else (for
  // example "12,50", read as 1250 rupees) is a likely typo and is rejected.
  static final RegExp _westernGrouping = RegExp(r'^\d{1,3}(,\d{3})+$');
  static final RegExp _indianGrouping = RegExp(r'^\d{1,2}(,\d{2})*,\d{3}$');

  /// Formats [paise] as Indian-grouped rupees with exactly 2 decimals.
  ///
  /// Throws [ArgumentError] if [paise] is outside -maxPaise..maxPaise.
  static String format(
    int paise, {
    bool symbol = true,
    bool alwaysShowSign = false,
  }) {
    // Range check instead of paise.abs() > maxPaise: same meaning, but safe
    // even for the most negative int, whose abs() overflows.
    if (paise > maxPaise || paise < -maxPaise) {
      throw ArgumentError.value(
        paise,
        'paise',
        'must be within +/- Money.maxPaise ($maxPaise)',
      );
    }

    final bool negative = paise < 0;
    final int absPaise = paise.abs();
    final int rupees = absPaise ~/ 100;
    final int fraction = absPaise % 100;

    final String fractionText = fraction < 10 ? '0$fraction' : '$fraction';
    final String sign = negative
        ? '-'
        : (alwaysShowSign && paise != 0 ? '+' : '');
    final String prefix = symbol ? rupeeSymbol : '';

    return '$sign$prefix${_groupIndian(rupees.toString())}.$fractionText';
  }

  /// Parses user input into paise, or returns null if it is invalid.
  ///
  /// Accepts, in this order: optional "-" (only when [allowNegative]),
  /// optional rupee sign, optional spaces, then digits, at most one ".", and
  /// 0-2 digits after it. If the whole-number part contains ANY comma, it must
  /// be valid Western grouping (1,250  100,000  1,234,567) or valid Indian
  /// grouping (1,250  12,34,567  1,00,00,000); otherwise the result is null.
  /// Commas after the "." are never allowed. Anything else returns null,
  /// including 3+ decimals and any amount beyond [maxPaise].
  static int? parse(String input, {bool allowNegative = false}) {
    String s = input.trim();

    bool negative = false;
    if (s.startsWith('-')) {
      if (!allowNegative) return null;
      negative = true;
      s = s.substring(1);
    }

    if (s.startsWith(rupeeSymbol)) {
      s = s.substring(rupeeSymbol.length).trimLeft();
    }

    if (s.isEmpty) return null;

    final StringBuffer wholeBuf = StringBuffer();
    // The whole-number text exactly as typed (digits AND commas), so the
    // comma layout can be checked.
    final StringBuffer wholeRaw = StringBuffer();
    final StringBuffer fracBuf = StringBuffer();
    bool seenDot = false;
    bool seenComma = false;

    for (final int c in s.codeUnits) {
      if (c >= 0x30 && c <= 0x39) {
        // ASCII digit 0-9 only.
        if (seenDot) {
          if (fracBuf.length >= 2) return null; // 3rd decimal: reject.
          fracBuf.writeCharCode(c);
        } else {
          wholeBuf.writeCharCode(c);
          wholeRaw.writeCharCode(c);
        }
      } else if (c == 0x2C) {
        // Comma: allowed in the whole-number part only.
        if (seenDot) return null;
        seenComma = true;
        wholeRaw.writeCharCode(c);
      } else if (c == 0x2E) {
        // Dot: at most one.
        if (seenDot) return null;
        seenDot = true;
      } else {
        // Letters, spaces inside the number, "-", symbols, non-ASCII digits.
        return null;
      }
    }

    // Need at least one digit somewhere.
    if (wholeBuf.isEmpty && fracBuf.isEmpty) return null;

    // Any comma must form valid Western or Indian grouping. This also
    // rejects a leading/trailing comma and commas with no digits.
    if (seenComma) {
      final String raw = wholeRaw.toString();
      if (!_westernGrouping.hasMatch(raw) && !_indianGrouping.hasMatch(raw)) {
        return null;
      }
    }

    // Drop leading zeros so the length check below is exact.
    String whole = wholeBuf.toString();
    int start = 0;
    while (start < whole.length && whole.codeUnitAt(start) == 0x30) {
      start++;
    }
    whole = whole.substring(start);
    if (whole.isEmpty) whole = '0';

    // Too many digits to ever be within maxPaise; also keeps int.parse safe.
    if (whole.length > _maxRupeeDigits) return null;

    // ".5" -> "50", "5." -> "00", "" -> "00".
    final String frac = fracBuf.toString().padRight(2, '0');

    // Digits-only string, validated above: whole rupees followed by paise.
    final int paise = int.parse('$whole$frac');
    if (paise > maxPaise) return null;

    return negative ? -paise : paise;
  }

  /// Indian grouping: last 3 digits, then groups of 2. [digits] is digits only.
  static String _groupIndian(String digits) {
    if (digits.length <= 3) return digits;

    final String lastThree = digits.substring(digits.length - 3);
    final String rest = digits.substring(0, digits.length - 3);

    final List<String> groups = <String>[];
    int end = rest.length;
    while (end > 0) {
      final int start = end >= 2 ? end - 2 : 0;
      groups.insert(0, rest.substring(start, end));
      end = start;
    }
    return '${groups.join(',')},$lastThree';
  }
}
