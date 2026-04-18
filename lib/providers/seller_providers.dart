import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

final activeSellersProvider = StreamProvider<List<Seller>>((ref) {
  return ref.watch(databaseProvider).watchActiveSellers();
});
