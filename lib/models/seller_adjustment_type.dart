enum SellerAdjustmentType {
  cashOut('cashOut'),
  manualDeduction('manualDeduction');

  const SellerAdjustmentType(this.databaseValue);

  final String databaseValue;

  static SellerAdjustmentType fromDatabaseValue(String value) {
    return SellerAdjustmentType.values.firstWhere(
      (type) => type.databaseValue == value,
      orElse: () => SellerAdjustmentType.manualDeduction,
    );
  }
}
