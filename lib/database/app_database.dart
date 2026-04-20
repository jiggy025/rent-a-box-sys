import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/dashboard_box_summary.dart';
import '../models/dashboard_guide_state.dart';
import '../models/seller_active_box_record.dart';
import '../models/seller_adjustment_type.dart';
import '../models/seller_history_record.dart';
import '../models/seller_ledger_summary.dart';
import '../models/seller_transaction_record.dart';

part 'app_database.g.dart';

class Sellers extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get contactInfo => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get inactiveAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class Boxes extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get boxNumber => text().withLength(min: 1, max: 20)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {boxNumber},
  ];
}

class RentalAssignments extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get sellerId => text().references(Sellers, #id)();
  TextColumn get boxId => text().references(Boxes, #id)();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class LogEntries extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get rentalAssignmentId =>
      text().references(RentalAssignments, #id)();
  TextColumn get itemName => text().withLength(min: 1, max: 120)();
  RealColumn get price => real()();
  TextColumn get claimerName => text().withLength(min: 1, max: 80)();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class SellerAdjustments extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get sellerId => text().references(Sellers, #id)();
  TextColumn get type => text().withLength(min: 1, max: 40)();
  RealColumn get amount => real()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DriftDatabase(
  tables: [Sellers, Boxes, RentalAssignments, LogEntries, SellerAdjustments],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _ensureSchemaProtections();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(sellers, sellers.inactiveAt);
        await m.createTable(sellerAdjustments);
      }
      await _ensureSchemaProtections();
    },
    beforeOpen: (details) async {
      await _ensureSchemaProtections();
    },
  );

  Future<String> createSeller({
    required String name,
    String? contactInfo,
  }) async {
    final row = await into(sellers).insertReturning(
      SellersCompanion.insert(name: name, contactInfo: Value(contactInfo)),
    );

    return row.id;
  }

  Future<String> createBox({required String boxNumber}) async {
    final row = await into(
      boxes,
    ).insertReturning(BoxesCompanion.insert(boxNumber: boxNumber));

    return row.id;
  }

  Future<Boxe?> boxByNumber(String boxNumber) {
    return (select(boxes)..where(
          (tbl) => tbl.boxNumber.equals(boxNumber) & tbl.isActive.equals(true),
        ))
        .getSingleOrNull();
  }

  Future<String> createRentalAssignment({
    required String sellerId,
    required String boxId,
  }) async {
    final active = await activeAssignmentForBox(boxId);
    if (active != null) {
      throw StateError('Box already has an active assignment.');
    }

    await _reactivateSeller(sellerId);
    final row = await into(rentalAssignments).insertReturning(
      RentalAssignmentsCompanion.insert(sellerId: sellerId, boxId: boxId),
    );

    return row.id;
  }

  Future<void> addLogEntry({
    required String rentalAssignmentId,
    required String itemName,
    required double price,
    required String claimerName,
  }) async {
    final assignment = await assignmentById(rentalAssignmentId);
    if (assignment == null) {
      throw StateError('Rental assignment does not exist.');
    }
    if (assignment.endedAt != null) {
      throw StateError('Cannot add log entry to a closed assignment.');
    }

    await into(logEntries).insert(
      LogEntriesCompanion.insert(
        rentalAssignmentId: rentalAssignmentId,
        itemName: itemName,
        price: price,
        claimerName: claimerName,
      ),
    );
  }

  Future<void> reassignBox({
    required String boxId,
    required String nextSellerId,
  }) async {
    await transaction(() async {
      final active = await activeAssignmentForBox(boxId);
      if (active != null) {
        await (update(rentalAssignments)
              ..where((tbl) => tbl.id.equals(active.id)))
            .write(RentalAssignmentsCompanion(endedAt: Value(DateTime.now())));
      }

      await createRentalAssignment(sellerId: nextSellerId, boxId: boxId);
    });
  }

  Future<String> createSellerAdjustment({
    required String sellerId,
    required SellerAdjustmentType type,
    required double amount,
    String? reason,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Adjustment amount must be greater than zero.',
      );
    }

    final normalizedReason = reason?.trim();
    if (type == SellerAdjustmentType.manualDeduction &&
        (normalizedReason == null || normalizedReason.isEmpty)) {
      throw StateError('Manual deductions require a reason.');
    }

    final summary = await sellerLedgerSummary(sellerId);
    if (summary == null) {
      throw StateError('Seller does not exist.');
    }
    if (amount > summary.availableBalance) {
      throw StateError('Amount exceeds the seller available balance.');
    }

    final row = await into(sellerAdjustments).insertReturning(
      SellerAdjustmentsCompanion.insert(
        sellerId: sellerId,
        type: type.databaseValue,
        amount: amount,
        reason: Value(
          normalizedReason == null || normalizedReason.isEmpty
              ? null
              : normalizedReason,
        ),
      ),
    );

    return row.id;
  }

  Future<void> markSellerInactive(String sellerId) async {
    final now = DateTime.now();
    await transaction(() async {
      await (update(sellers)..where((tbl) => tbl.id.equals(sellerId))).write(
        SellersCompanion(
          isActive: const Value(false),
          inactiveAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await (update(rentalAssignments)..where(
            (tbl) => tbl.sellerId.equals(sellerId) & tbl.endedAt.isNull(),
          ))
          .write(RentalAssignmentsCompanion(endedAt: Value(now)));
    });
  }

  Future<int> activeAssignmentCount() async {
    final countExpression = rentalAssignments.id.count();
    final query = selectOnly(rentalAssignments)
      ..addColumns([countExpression])
      ..where(rentalAssignments.endedAt.isNull());
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Stream<int> watchActiveAssignmentCount() {
    final countExpression = rentalAssignments.id.count();
    final query = selectOnly(rentalAssignments)
      ..addColumns([countExpression])
      ..where(rentalAssignments.endedAt.isNull());

    return query.watchSingle().map((row) => row.read(countExpression) ?? 0);
  }

  Future<bool> hasAnyLedgerData() async {
    final row = await customSelect(
      '''
      SELECT CASE
        WHEN EXISTS (SELECT 1 FROM sellers)
          OR EXISTS (SELECT 1 FROM boxes)
        THEN 1 ELSE 0
      END AS has_data
      ''',
      readsFrom: {sellers, boxes},
    ).getSingle();

    return row.read<int>('has_data') == 1;
  }

  Stream<bool> watchHasAnyLedgerData() {
    return customSelect(
      '''
      SELECT CASE
        WHEN EXISTS (SELECT 1 FROM sellers)
          OR EXISTS (SELECT 1 FROM boxes)
        THEN 1 ELSE 0
      END AS has_data
      ''',
      readsFrom: {sellers, boxes},
    ).watchSingle().map((row) => row.read<int>('has_data') == 1);
  }

  Future<List<RentalAssignment>> activeAssignmentsForSeller(String sellerId) {
    return (select(
          rentalAssignments,
        )..where((tbl) => tbl.sellerId.equals(sellerId) & tbl.endedAt.isNull()))
        .get();
  }

  Stream<List<Seller>> watchActiveSellers() {
    return (select(sellers)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }

  Stream<List<Seller>> watchAllSellers() {
    return (select(sellers)..orderBy([
          (tbl) => OrderingTerm.desc(tbl.isActive),
          (tbl) => OrderingTerm.asc(tbl.name),
        ]))
        .watch();
  }

  Future<RentalAssignment?> activeAssignmentForBox(String boxId) {
    return (select(rentalAssignments)
          ..where((tbl) => tbl.boxId.equals(boxId) & tbl.endedAt.isNull()))
        .getSingleOrNull();
  }

  Future<RentalAssignment?> assignmentById(String assignmentId) {
    return (select(
      rentalAssignments,
    )..where((tbl) => tbl.id.equals(assignmentId))).getSingleOrNull();
  }

  Future<double> currentBoxTotal(String boxId) async {
    final active = await activeAssignmentForBox(boxId);
    if (active == null) {
      return 0;
    }

    final totalExpression = logEntries.price.sum();
    final query = selectOnly(logEntries)
      ..addColumns([totalExpression])
      ..where(logEntries.rentalAssignmentId.equals(active.id));
    final row = await query.getSingle();
    return row.read(totalExpression) ?? 0;
  }

  Future<List<DashboardBoxSummary>> dashboardBoxSummaries() async {
    final rows = await customSelect(
      '''
      SELECT
        b.id AS box_id,
        b.box_number,
        ra.id AS assignment_id,
        s.id AS seller_id,
        s.name AS seller_name,
        CASE WHEN ra.id IS NULL THEN 1 ELSE 0 END AS is_vacant,
        COALESCE(SUM(le.price), 0) AS total
      FROM boxes AS b
      LEFT JOIN rental_assignments AS ra
        ON ra.box_id = b.id
       AND ra.ended_at IS NULL
      LEFT JOIN sellers AS s
        ON s.id = ra.seller_id
      LEFT JOIN log_entries AS le
        ON le.rental_assignment_id = ra.id
      WHERE b.is_active = 1
      GROUP BY b.id, b.box_number, ra.id, s.id, s.name
      ORDER BY b.box_number ASC
      ''',
      readsFrom: {boxes, rentalAssignments, sellers, logEntries},
    ).get();

    return rows
        .map(
          (row) => DashboardBoxSummary(
            boxId: row.read<String>('box_id'),
            boxNumber: row.read<String>('box_number'),
            assignmentId: row.read<String?>('assignment_id'),
            sellerId: row.read<String?>('seller_id'),
            sellerName: row.read<String?>('seller_name'),
            isVacant: row.read<int>('is_vacant') == 1,
            total: row.read<double>('total'),
          ),
        )
        .toList(growable: false);
  }

  Stream<List<DashboardBoxSummary>> watchDashboardBoxes() {
    return customSelect(
      '''
      SELECT
        b.id AS box_id,
        b.box_number,
        ra.id AS assignment_id,
        s.id AS seller_id,
        s.name AS seller_name,
        CASE WHEN ra.id IS NULL THEN 1 ELSE 0 END AS is_vacant,
        COALESCE(
          (
            SELECT SUM(le.price)
            FROM log_entries le
            WHERE le.rental_assignment_id = ra.id
          ),
          0
        ) AS total
      FROM boxes b
      LEFT JOIN rental_assignments ra
        ON ra.box_id = b.id
       AND ra.ended_at IS NULL
      LEFT JOIN sellers s
        ON s.id = ra.seller_id
      ORDER BY b.box_number
      ''',
      readsFrom: {boxes, rentalAssignments, sellers, logEntries},
    ).watch().map(
      (rows) => rows
          .map(
            (row) => DashboardBoxSummary(
              boxId: row.read<String>('box_id'),
              boxNumber: row.read<String>('box_number'),
              assignmentId: row.read<String?>('assignment_id'),
              sellerId: row.read<String?>('seller_id'),
              sellerName: row.read<String?>('seller_name'),
              isVacant: row.read<int>('is_vacant') == 1,
              total: row.read<double>('total'),
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<DashboardGuideState> watchDashboardGuideState() {
    return customSelect(
      '''
      SELECT
        COALESCE(
          (
            SELECT COUNT(*)
            FROM sellers AS s
            WHERE s.is_active = 1
          ),
          0
        ) AS seller_count,
        COALESCE(
          (
            SELECT COUNT(*)
            FROM boxes AS b
            WHERE b.is_active = 1
          ),
          0
        ) AS active_box_count,
        COALESCE(
          (
            SELECT COUNT(*)
            FROM rental_assignments AS ra
            WHERE ra.ended_at IS NULL
          ),
          0
        ) AS active_assignment_count,
        COALESCE(
          (
            SELECT COUNT(*)
            FROM log_entries AS le
          ),
          0
        ) AS log_entry_count,
        COALESCE(
          (
            SELECT COUNT(*)
            FROM seller_adjustments AS sa
          ),
          0
        ) AS seller_adjustment_count,
        CASE
          WHEN EXISTS (
            SELECT 1
            FROM rental_assignments AS ra
          ) THEN 1
          ELSE 0
        END AS has_completed_initial_setup
      ''',
      readsFrom: {
        sellers,
        boxes,
        rentalAssignments,
        logEntries,
        sellerAdjustments,
      },
    ).watchSingle().map(
      (row) => DashboardGuideState(
        sellerCount: row.read<int>('seller_count'),
        activeBoxCount: row.read<int>('active_box_count'),
        activeAssignmentCount: row.read<int>('active_assignment_count'),
        logEntryCount: row.read<int>('log_entry_count'),
        sellerAdjustmentCount: row.read<int>('seller_adjustment_count'),
        hasCompletedInitialSetup:
            row.read<int>('has_completed_initial_setup') == 1,
      ),
    );
  }

  Stream<List<LogEntry>> watchEntriesForAssignment(String assignmentId) {
    return (select(logEntries)
          ..where((tbl) => tbl.rentalAssignmentId.equals(assignmentId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }

  Stream<double> watchAssignmentTotal(String assignmentId) {
    final totalExpression = logEntries.price.sum();
    final query = selectOnly(logEntries)
      ..addColumns([totalExpression])
      ..where(logEntries.rentalAssignmentId.equals(assignmentId));

    return query.watchSingle().map((row) => row.read(totalExpression) ?? 0);
  }

  Future<SellerLedgerSummary?> sellerLedgerSummary(String sellerId) async {
    final rows = await _sellerLedgerSummarySelect(sellerId: sellerId).get();
    if (rows.isEmpty) {
      return null;
    }
    return _mapSellerLedgerSummary(rows.single);
  }

  Stream<SellerLedgerSummary?> watchSellerLedgerSummary(String sellerId) {
    return _sellerLedgerSummarySelect(
      sellerId: sellerId,
    ).watchSingleOrNull().map((row) {
      if (row == null) {
        return null;
      }
      return _mapSellerLedgerSummary(row);
    });
  }

  Future<List<SellerLedgerSummary>> sellerLedgerSummaries() async {
    final rows = await _sellerLedgerSummarySelect().get();
    return rows.map(_mapSellerLedgerSummary).toList(growable: false);
  }

  Stream<List<SellerLedgerSummary>> watchSellerLedgerSummaries() {
    return _sellerLedgerSummarySelect().watch().map(
      (rows) => rows.map(_mapSellerLedgerSummary).toList(growable: false),
    );
  }

  Stream<List<SellerActiveBoxRecord>> watchActiveBoxesForSeller(
    String sellerId,
  ) {
    return customSelect(
      '''
      SELECT
        b.id AS box_id,
        b.box_number,
        ra.id AS assignment_id,
        COALESCE(SUM(le.price), 0) AS total
      FROM rental_assignments AS ra
      INNER JOIN boxes AS b
        ON b.id = ra.box_id
      LEFT JOIN log_entries AS le
        ON le.rental_assignment_id = ra.id
      WHERE ra.seller_id = ?
        AND ra.ended_at IS NULL
      GROUP BY b.id, b.box_number, ra.id
      ORDER BY b.box_number ASC
      ''',
      variables: [Variable<String>(sellerId)],
      readsFrom: {rentalAssignments, boxes, logEntries},
    ).watch().map(
      (rows) => rows
          .map(
            (row) => SellerActiveBoxRecord(
              boxId: row.read<String>('box_id'),
              assignmentId: row.read<String>('assignment_id'),
              boxNumber: row.read<String>('box_number'),
              total: row.read<double>('total'),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<List<SellerTransactionRecord>> sellerTransactionHistory(
    String sellerId,
  ) async {
    final rows = await _sellerTransactionHistorySelect(sellerId).get();
    return rows.map(_mapSellerTransactionRecord).toList(growable: false);
  }

  Stream<List<SellerTransactionRecord>> watchSellerTransactionHistory(
    String sellerId,
  ) {
    return _sellerTransactionHistorySelect(sellerId).watch().map(
      (rows) => rows.map(_mapSellerTransactionRecord).toList(growable: false),
    );
  }

  Future<List<SellerHistoryRecord>> sellerHistory(String sellerId) async {
    final rows = await customSelect(
      '''
      SELECT
        ra.id AS assignment_id,
        b.box_number,
        ra.started_at,
        ra.ended_at,
        COALESCE(SUM(le.price), 0) AS total,
        CASE WHEN ra.ended_at IS NULL THEN 1 ELSE 0 END AS is_active
      FROM rental_assignments AS ra
      INNER JOIN boxes AS b
        ON b.id = ra.box_id
      LEFT JOIN log_entries AS le
        ON le.rental_assignment_id = ra.id
      WHERE ra.seller_id = ?
      GROUP BY ra.id, b.box_number, ra.started_at, ra.ended_at
      ORDER BY ra.started_at DESC
      ''',
      variables: [Variable<String>(sellerId)],
      readsFrom: {rentalAssignments, boxes, logEntries},
    ).get();

    return rows
        .map(
          (row) => SellerHistoryRecord(
            assignmentId: row.read<String>('assignment_id'),
            boxNumber: row.read<String>('box_number'),
            startedAt: row.read<DateTime>('started_at'),
            endedAt: row.read<DateTime?>('ended_at'),
            total: row.read<double>('total'),
            isActive: row.read<int>('is_active') == 1,
          ),
        )
        .toList(growable: false);
  }

  Selectable<QueryRow> _sellerLedgerSummarySelect({String? sellerId}) {
    final variables = <Variable<Object>>[];
    final whereClause = sellerId == null ? '' : 'WHERE s.id = ?';
    if (sellerId != null) {
      variables.add(Variable<String>(sellerId));
    }

    return customSelect(
      '''
      SELECT
        s.id AS seller_id,
        s.name AS seller_name,
        s.is_active,
        s.inactive_at,
        COALESCE(
          (
            SELECT COUNT(*)
            FROM rental_assignments AS ra
            WHERE ra.seller_id = s.id
              AND ra.ended_at IS NULL
          ),
          0
        ) AS active_boxes_count,
        COALESCE(
          (
            SELECT SUM(le.price)
            FROM rental_assignments AS ra
            LEFT JOIN log_entries AS le
              ON le.rental_assignment_id = ra.id
            WHERE ra.seller_id = s.id
              AND ra.ended_at IS NULL
          ),
          0
        ) AS active_boxes_total,
        COALESCE(
          (
            SELECT SUM(le.price)
            FROM rental_assignments AS ra
            LEFT JOIN log_entries AS le
              ON le.rental_assignment_id = ra.id
            WHERE ra.seller_id = s.id
          ),
          0
        ) AS lifetime_sales,
        COALESCE(
          (
            SELECT SUM(sa.amount)
            FROM seller_adjustments AS sa
            WHERE sa.seller_id = s.id
          ),
          0
        ) AS total_adjustments
      FROM sellers AS s
      $whereClause
      ORDER BY s.is_active DESC, s.name ASC
      ''',
      variables: variables,
      readsFrom: {sellers, rentalAssignments, logEntries, sellerAdjustments},
    );
  }

  SellerLedgerSummary _mapSellerLedgerSummary(QueryRow row) {
    final lifetimeSales = row.read<double>('lifetime_sales');
    final totalAdjustments = row.read<double>('total_adjustments');

    return SellerLedgerSummary(
      sellerId: row.read<String>('seller_id'),
      sellerName: row.read<String>('seller_name'),
      isActive: row.read<bool>('is_active'),
      inactiveAt: row.read<DateTime?>('inactive_at'),
      activeBoxesCount: row.read<int>('active_boxes_count'),
      activeBoxesTotal: row.read<double>('active_boxes_total'),
      lifetimeSales: lifetimeSales,
      availableBalance: lifetimeSales - totalAdjustments,
    );
  }

  Selectable<QueryRow> _sellerTransactionHistorySelect(String sellerId) {
    return customSelect(
      '''
      SELECT
        le.id AS transaction_id,
        'sale' AS kind,
        le.item_name AS title,
        le.claimer_name AS detail,
        b.box_number,
        le.price AS amount,
        le.timestamp AS created_at
      FROM log_entries AS le
      INNER JOIN rental_assignments AS ra
        ON ra.id = le.rental_assignment_id
      INNER JOIN boxes AS b
        ON b.id = ra.box_id
      WHERE ra.seller_id = ?

      UNION ALL

      SELECT
        sa.id AS transaction_id,
        sa.type AS kind,
        CASE
          WHEN sa.type = 'cashOut' THEN 'Cash Out'
          ELSE 'Manual Deduction'
        END AS title,
        sa.reason AS detail,
        NULL AS box_number,
        -sa.amount AS amount,
        sa.created_at AS created_at
      FROM seller_adjustments AS sa
      WHERE sa.seller_id = ?
      ORDER BY created_at DESC, transaction_id DESC
      ''',
      variables: [Variable<String>(sellerId), Variable<String>(sellerId)],
      readsFrom: {logEntries, rentalAssignments, boxes, sellerAdjustments},
    );
  }

  SellerTransactionRecord _mapSellerTransactionRecord(QueryRow row) {
    return SellerTransactionRecord(
      id: row.read<String>('transaction_id'),
      kind: SellerTransactionKind.fromDatabaseValue(row.read<String>('kind')),
      title: row.read<String>('title'),
      detail: row.read<String?>('detail'),
      boxNumber: row.read<String?>('box_number'),
      amount: row.read<double>('amount'),
      createdAt: row.read<DateTime>('created_at'),
    );
  }

  Future<void> _reactivateSeller(String sellerId) async {
    await (update(sellers)..where((tbl) => tbl.id.equals(sellerId))).write(
      SellersCompanion(
        isActive: const Value(true),
        inactiveAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _ensureSchemaProtections() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS rental_assignments_active_box_unique_idx
      ON rental_assignments (box_id)
      WHERE ended_at IS NULL
      ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS log_entries_active_assignment_only
      BEFORE INSERT ON log_entries
      FOR EACH ROW
      BEGIN
        SELECT CASE
          WHEN (
            SELECT ended_at
            FROM rental_assignments
            WHERE id = NEW.rental_assignment_id
          ) IS NOT NULL
          THEN RAISE(ABORT, 'Cannot add log entry to a closed assignment.')
        END;
      END;
      ''');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'rent_a_box_ledger.sqlite'));
    return NativeDatabase(file);
  });
}
