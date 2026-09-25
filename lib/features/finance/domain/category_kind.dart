/// income/expense per DATABASE.md's `categories.kind`.
enum CategoryKind {
  income,
  expense;

  String get label => switch (this) {
    CategoryKind.income => 'Income',
    CategoryKind.expense => 'Expense',
  };
}