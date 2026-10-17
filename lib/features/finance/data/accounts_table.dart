import 'package:drift/drift.dart';

/// What kind of account this is. Stored by NAME (`'cash'`, `'bank'`,
/// `'wallet'`, `'creditCard'`, `'other'`) via `textEnum`, never by index,
/// and with no SQL CHECK constraint. Only ever APPEND values; never rename
/// one (the name is what is stored).
enum AccountType { cash, bank, wallet, creditCard, other }

/// DATABASE.md `accounts`: (id, user_id, name, type, currency,
/// starting_balance) plus the general created_at/updated_at columns
/// (rule 3) and `is_archived`.
///
/// - `user_id` is NOT NULL, like categories: every row is scoped to the
///   device-local user id.
/// - `name` is trimmed, 1-40 characters, and unique per user ignoring
///   case. Those are enforced in AccountsDao (a case-insensitive unique
///   constraint isn't expressible here without custom SQL).
/// - `currency` is always 'INR' for now; there is no currency UI.
/// - `starting_balance` is integer PAISE (rule 5) and may be negative
///   (credit cards). |value| <= Money.maxPaise is enforced in AccountsDao.
/// - The current balance is NEVER stored. See account_balance.dart.
@DataClassName('AccountRow')
@TableIndex(name: 'accounts_user_idx', columns: {#userId})
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<AccountType>()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  IntColumn get startingBalance => integer()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}
