import 'loan_activity_type.dart';

enum LoanDirection {
  lent,
  borrowed;

  /// "They owe you" / "You owe them" — Part 1, unchanged.
  String get label => switch (this) {
    LoanDirection.lent => 'They owe you',
    LoanDirection.borrowed => 'You owe them',
  };

  /// NEW this task. The default category name for a given activity
  /// on a loan of this direction — mirrors InvestmentType's
  /// established pattern of attaching cross-cutting lookup logic to
  /// the relevant enum rather than a separate file (task response).
  String preferredCategoryNameFor(LoanActivityType type) => switch ((this, type)) {
    (LoanDirection.lent, LoanActivityType.increase) => 'Loan Given',
    (LoanDirection.lent, LoanActivityType.repayment) => 'Loan Repayment Received',
    (LoanDirection.borrowed, LoanActivityType.increase) => 'Loan Taken',
    (LoanDirection.borrowed, LoanActivityType.repayment) => 'Loan Repayment Paid',
  };
}