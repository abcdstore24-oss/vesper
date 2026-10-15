import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'categories_table.dart';

/// One built-in category. [color] is `0xFFRRGGBB`.
class DefaultCategory {
  const DefaultCategory({
    required this.seedKey,
    required this.name,
    required this.icon,
    required this.color,
    required this.kind,
  });

  final String seedKey;
  final String name;
  final String icon;
  final int color;
  final CategoryKind kind;
}

/// The built-in categories, exactly as specified. These colours are the
/// one deliberate multi-colour exception allowed by CLAUDE.md Section 3.
/// Never change a [seedKey] once shipped: it is the row's stable identity.
const List<DefaultCategory> defaultCategories = <DefaultCategory>[
  // Expense
  DefaultCategory(seedKey: 'exp_food', name: 'Food & Dining', icon: 'fork_knife', color: 0xFFC97B84, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_groceries', name: 'Groceries', icon: 'shopping_cart', color: 0xFF8FB38A, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_transport', name: 'Transport', icon: 'car', color: 0xFF6FA3A8, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_bills', name: 'Bills & Utilities', icon: 'receipt', color: 0xFFD9A066, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_rent', name: 'Rent', icon: 'house', color: 0xFFC7826B, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_shopping', name: 'Shopping', icon: 'shopping_bag', color: 0xFFC98BB0, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_health', name: 'Health', icon: 'heartbeat', color: 0xFF7FA6C9, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_education', name: 'Education', icon: 'graduation_cap', color: 0xFF7B8FC7, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_entertainment', name: 'Entertainment', icon: 'film_slate', color: 0xFFA68BC7, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_travel', name: 'Travel', icon: 'airplane', color: 0xFF8C9A7E, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_subscriptions', name: 'Subscriptions', icon: 'repeat', color: 0xFFB5A06A, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_personal_care', name: 'Personal Care', icon: 'sparkle', color: 0xFFC98BB0, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_gifts', name: 'Gifts & Donations', icon: 'gift', color: 0xFFC97B84, kind: CategoryKind.expense),
  DefaultCategory(seedKey: 'exp_other', name: 'Other', icon: 'dots_three', color: 0xFF9C95A8, kind: CategoryKind.expense),
  // Income
  DefaultCategory(seedKey: 'inc_salary', name: 'Salary', icon: 'briefcase', color: 0xFF8FB38A, kind: CategoryKind.income),
  DefaultCategory(seedKey: 'inc_business', name: 'Business', icon: 'storefront', color: 0xFF6FA3A8, kind: CategoryKind.income),
  DefaultCategory(seedKey: 'inc_interest', name: 'Interest & Dividends', icon: 'piggy_bank', color: 0xFF7FA6C9, kind: CategoryKind.income),
  DefaultCategory(seedKey: 'inc_gifts', name: 'Gifts', icon: 'gift', color: 0xFFC98BB0, kind: CategoryKind.income),
  DefaultCategory(seedKey: 'inc_refunds', name: 'Refunds', icon: 'arrow_u_up_left', color: 0xFFB5A06A, kind: CategoryKind.income),
  DefaultCategory(seedKey: 'inc_other', name: 'Other income', icon: 'dots_three', color: 0xFF9C95A8, kind: CategoryKind.income),
  // System (loan / investment movements; never user-pickable, never
  // counted as income or expense). Grey because they never appear in charts.
  DefaultCategory(seedKey: 'sys_loan_given', name: 'Loan given', icon: 'arrow_up_right', color: 0xFF9C95A8, kind: CategoryKind.system),
  DefaultCategory(seedKey: 'sys_loan_repayment_received', name: 'Repayment received', icon: 'arrow_down_left', color: 0xFF9C95A8, kind: CategoryKind.system),
  DefaultCategory(seedKey: 'sys_loan_taken', name: 'Loan taken', icon: 'hand_coins', color: 0xFF9C95A8, kind: CategoryKind.system),
  DefaultCategory(seedKey: 'sys_loan_repayment_made', name: 'Loan repayment made', icon: 'handshake', color: 0xFF9C95A8, kind: CategoryKind.system),
  DefaultCategory(seedKey: 'sys_investment_buy', name: 'Investment purchase', icon: 'trend_up', color: 0xFF9C95A8, kind: CategoryKind.system),
  DefaultCategory(seedKey: 'sys_investment_sell', name: 'Investment sale', icon: 'trend_down', color: 0xFF9C95A8, kind: CategoryKind.system),
];

/// Baseline seeder for default categories. Safe to run on every start.
///
/// One read finds which seed keys already exist for [userId]; only the
/// missing ones are inserted (insert-or-ignore, keyed by the
/// (user_id, seed_key) unique constraint). Because rows are never
/// deleted, a renamed or archived built-in is found and left alone,
/// never recreated or reset. When nothing is missing there are no
/// writes at all. Because only MISSING keys are inserted, an existing
/// install gains newly added defaults (e.g. the system categories) on
/// its next start with no migration, and its existing rows are untouched.
///
/// Call inside the bootstrap transaction (see db_bootstrap.dart).
Future<void> seedDefaultCategories(AppDatabase db, String userId) async {
  final existingRows =
      await (db.select(db.categories)..where(
            (t) => t.userId.equals(userId) & t.seedKey.isNotNull(),
          ))
          .get();
  final existingKeys = existingRows.map((r) => r.seedKey).toSet();

  final missing = defaultCategories
      .where((c) => !existingKeys.contains(c.seedKey))
      .toList();
  if (missing.isEmpty) return;

  await db.batch((batch) {
    batch.insertAll(
      db.categories,
      [
        for (final c in missing)
          CategoriesCompanion.insert(
            id: generateId(),
            userId: userId,
            name: c.name,
            icon: c.icon,
            color: c.color,
            kind: c.kind,
            seedKey: Value(c.seedKey),
          ),
      ],
      mode: InsertMode.insertOrIgnore,
    );
  });
}