import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final activeAssignmentCountProvider = StreamProvider<int>((ref) {
  return ref.watch(databaseProvider).watchActiveAssignmentCount();
});

final hasAnyLedgerDataProvider = StreamProvider<bool>((ref) {
  return ref.watch(databaseProvider).watchHasAnyLedgerData();
});

final refreshTickProvider = StateProvider<int>((ref) => 0);
