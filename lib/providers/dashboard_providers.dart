import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_box_summary.dart';
import '../models/dashboard_guide_state.dart';
import 'database_provider.dart';

final dashboardSearchProvider = StateProvider<String>((ref) => '');

final dashboardBoxesProvider = StreamProvider<List<DashboardBoxSummary>>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(databaseProvider).watchDashboardBoxes();
});

final dashboardGuideStateProvider = StreamProvider<DashboardGuideState>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(databaseProvider).watchDashboardGuideState();
});

final filteredDashboardBoxesProvider =
    Provider<AsyncValue<List<DashboardBoxSummary>>>((ref) {
      final query = ref.watch(dashboardSearchProvider).trim().toLowerCase();
      final boxes = ref.watch(dashboardBoxesProvider);

      return boxes.whenData((rows) {
        if (query.isEmpty) {
          return rows;
        }

        return rows
            .where((row) {
              return row.boxNumber.toLowerCase().contains(query) ||
                  (row.sellerName?.toLowerCase().contains(query) ?? false);
            })
            .toList(growable: false);
      });
    });
