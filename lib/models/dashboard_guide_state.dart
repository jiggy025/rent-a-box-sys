class DashboardGuideState {
  const DashboardGuideState({
    this.sellerCount = 0,
    this.activeBoxCount = 0,
    this.activeAssignmentCount = 0,
    this.logEntryCount = 0,
    this.sellerAdjustmentCount = 0,
    this.hasCompletedInitialSetup = false,
  });

  final int sellerCount;
  final int activeBoxCount;
  final int activeAssignmentCount;
  final int logEntryCount;
  final int sellerAdjustmentCount;
  final bool hasCompletedInitialSetup;

  bool get hasSeller => sellerCount > 0;
  bool get hasActiveBox => activeBoxCount > 0;
  bool get hasActiveAssignment => activeAssignmentCount > 0;
  bool get isSetupComplete =>
      hasCompletedInitialSetup ||
      (hasSeller && hasActiveBox && hasActiveAssignment);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DashboardGuideState &&
            other.sellerCount == sellerCount &&
            other.activeBoxCount == activeBoxCount &&
            other.activeAssignmentCount == activeAssignmentCount &&
            other.logEntryCount == logEntryCount &&
            other.sellerAdjustmentCount == sellerAdjustmentCount &&
            other.hasCompletedInitialSetup == hasCompletedInitialSetup);
  }

  @override
  int get hashCode => Object.hash(
    sellerCount,
    activeBoxCount,
    activeAssignmentCount,
    logEntryCount,
    sellerAdjustmentCount,
    hasCompletedInitialSetup,
  );
}
