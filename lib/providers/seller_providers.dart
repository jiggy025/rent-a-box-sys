import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/seller_active_box_record.dart';
import '../models/seller_history_record.dart';
import '../models/seller_ledger_summary.dart';
import '../models/seller_transaction_record.dart';
import 'database_provider.dart';

final sellerSearchProvider = StateProvider<String>((ref) => '');

final sellerLedgerSummariesProvider =
    StreamProvider<List<SellerLedgerSummary>>((ref) {
      return ref.watch(databaseProvider).watchSellerLedgerSummaries();
    });

final filteredSellerLedgerSummariesProvider =
    Provider<AsyncValue<List<SellerLedgerSummary>>>((ref) {
      final query = ref.watch(sellerSearchProvider).trim().toLowerCase();
      final sellersAsync = ref.watch(sellerLedgerSummariesProvider);

      return sellersAsync.whenData((rows) {
        if (query.isEmpty) {
          return rows;
        }

        return rows
            .where((row) => row.sellerName.toLowerCase().contains(query))
            .toList(growable: false);
      });
    });

final sellerLedgerSummaryProvider =
    StreamProvider.family<SellerLedgerSummary?, String>((ref, sellerId) {
      return ref.watch(databaseProvider).watchSellerLedgerSummary(sellerId);
    });

final sellerActiveBoxesProvider =
    StreamProvider.family<List<SellerActiveBoxRecord>, String>((
      ref,
      sellerId,
    ) {
      return ref.watch(databaseProvider).watchActiveBoxesForSeller(sellerId);
    });

final sellerTransactionHistoryProvider =
    StreamProvider.family<List<SellerTransactionRecord>, String>((
      ref,
      sellerId,
    ) {
      return ref.watch(databaseProvider).watchSellerTransactionHistory(sellerId);
    });

final sellerHistoryProvider =
    FutureProvider.family<List<SellerHistoryRecord>, String>((ref, sellerId) {
      ref.watch(refreshTickProvider);
      return ref.watch(databaseProvider).sellerHistory(sellerId);
    });

final activeSellersProvider = StreamProvider<List<Seller>>((ref) {
  return ref.watch(databaseProvider).watchActiveSellers();
});

final allSellersProvider = StreamProvider<List<Seller>>((ref) {
  return ref.watch(databaseProvider).watchAllSellers();
});
