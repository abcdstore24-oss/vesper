import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Fixed enum for accounts.type (task response: enum over free text,
/// to drive consistent icon/label rendering and avoid casing drift
/// like "Bank" vs "bank").
enum AccountType {
  cash,
  bank,
  card,
  other;

  String get label => switch (this) {
    AccountType.cash => 'Cash',
    AccountType.bank => 'Bank',
    AccountType.card => 'Card',
    AccountType.other => 'Other',
  };

  IconData get icon => switch (this) {
    AccountType.cash => PhosphorIconsRegular.money,
    AccountType.bank => PhosphorIconsRegular.bank,
    AccountType.card => PhosphorIconsRegular.creditCard,
    AccountType.other => PhosphorIconsRegular.wallet,
  };
}