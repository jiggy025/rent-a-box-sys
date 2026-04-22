import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

final databaseResetProvider = StateProvider<int>((ref) => 0);

final databaseProvider = Provider<AppDatabase>((ref) {
  ref.watch(databaseResetProvider);
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
