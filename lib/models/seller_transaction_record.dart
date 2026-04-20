enum SellerTransactionKind {
  sale,
  cashOut,
  manualDeduction;

  static SellerTransactionKind fromDatabaseValue(String value) {
    return switch (value) {
      'sale' => SellerTransactionKind.sale,
      'cashOut' => SellerTransactionKind.cashOut,
      'manualDeduction' => SellerTransactionKind.manualDeduction,
      _ => SellerTransactionKind.manualDeduction,
    };
  }
}

class SellerTransactionRecord {
  const SellerTransactionRecord({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.amount,
    required this.createdAt,
    this.boxNumber,
  });

  final String id;
  final SellerTransactionKind kind;
  final String title;
  final String? detail;
  final String? boxNumber;
  final double amount;
  final DateTime createdAt;
}
