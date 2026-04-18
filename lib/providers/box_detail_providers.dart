import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';

final activeAssignmentForBoxProvider = FutureProvider.family((
  ref,
  String boxId,
) {
  ref.watch(refreshTickProvider);
  return ref.watch(databaseProvider).activeAssignmentForBox(boxId);
});

final assignmentEntriesProvider = StreamProvider.family((
  ref,
  String assignmentId,
) {
  return ref.watch(databaseProvider).watchEntriesForAssignment(assignmentId);
});

final assignmentTotalProvider = StreamProvider.family((
  ref,
  String assignmentId,
) {
  return ref.watch(databaseProvider).watchAssignmentTotal(assignmentId);
});
