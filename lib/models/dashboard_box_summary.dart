class DashboardBoxSummary {
  const DashboardBoxSummary({
    required this.boxId,
    required this.boxNumber,
    required this.isVacant,
    required this.total,
    this.assignmentId,
    this.sellerId,
    this.sellerName,
  });

  final String boxId;
  final String boxNumber;
  final String? assignmentId;
  final String? sellerId;
  final String? sellerName;
  final bool isVacant;
  final double total;
}
