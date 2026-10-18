import 'package:drift/drift.dart';

/// What a transaction does to account balances. Stored by NAME
/// (`'income'`, `'expense'`, `'transfer'`) via `textEnum`, never by index,
/// and with no SQL CHECK constraint. Only ever APPEND values.
///
/// - income:   +amount to `account_id`
/// - expense:  -amount from `account_id`
/// - transfer: -amount from `account_id` AND +amount to `to_account_id`
///   (ONE row, not two)
enum TransactionType { income, expense, transfer }

/// What created a transaction automatically. Stored by NAME. A row with a
/// source was made by a loan payment or an investment trade: it moves
/// balances like any other row, but is excluded from monthly summaries,
/// budgets and charts (later tasks).
enum TransactionSource { loan, investment }

/// DATABASE.md `transactions`. Every money movement is one row here;
/// account balances are COMPUTED from these rows (account_balance.dart) and
/// never stored.
///
/// - `amount` is integer PAISE and always > 0; the direction comes from
///   `type`. 1..Money.maxPaise is enforced in TransactionsDao.
/// - `account_id` is the account money leaves or enters; for a transfer it
///   is the FROM account. `to_account_id` is set for transfers only.
/// - `category_id` is null for transfers.
/// - `note` is trimmed, empty becomes null, at most 100 characters
///   (TransactionsDao).
/// - `source_type` and `source_id` are both null or both set (TransactionsDao).
/// - No foreign keys and no CHECK constraints: every rule lives in
///   TransactionsDao, which validates and writes inside one database
///   transaction.
/// - DateTime columns are stored as whole seconds.
@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_user_date_idx', columns: {#userId, #occurredAt})
@TableIndex(name: 'transactions_account_idx', columns: {#accountId})
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get accountId => text()();
  TextColumn get toAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get sourceType => textEnum<TransactionSource>().nullable()();
  TextColumn get sourceId => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}
