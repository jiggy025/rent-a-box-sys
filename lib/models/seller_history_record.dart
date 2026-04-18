class SellerHistoryRecord {
  const SellerHistoryRecord({
    required this.assignmentId,
    required this.boxNumber,
    required this.startedAt,
    required this.endedAt,
    required this.total,
    required this.isActive,
  });

  final String assignmentId;
  final String boxNumber;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double total;
  final bool isActive;
}
