class SellerLedgerSummary {
  const SellerLedgerSummary({
    required this.sellerId,
    required this.sellerName,
    required this.isActive,
    required this.activeBoxesCount,
    required this.activeBoxesTotal,
    required this.lifetimeSales,
    required this.availableBalance,
    this.inactiveAt,
  });

  final String sellerId;
  final String sellerName;
  final bool isActive;
  final int activeBoxesCount;
  final double activeBoxesTotal;
  final double lifetimeSales;
  final double availableBalance;
  final DateTime? inactiveAt;
}
