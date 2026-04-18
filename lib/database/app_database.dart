import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/dashboard_box_summary.dart';
import '../models/seller_history_record.dart';

part 'app_database.g.dart';

class Sellers extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get contactInfo => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
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

@DriftDatabase(tables: [Sellers, Boxes, RentalAssignments, LogEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            '''
            CREATE UNIQUE INDEX rental_assignments_active_box_unique_idx
            ON rental_assignments (box_id)
            WHERE ended_at IS NULL
            ''',
          );
          await customStatement(
            '''
            CREATE TRIGGER log_entries_active_assignment_only
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
            ''',
          );
        },
      );

  Future<String> createSeller({
    required String name,
    String? contactInfo,
  }) async {
    final row = await into(sellers).insertReturning(
      SellersCompanion.insert(
        name: name,
        contactInfo: Value(contactInfo),
      ),
    );

    return row.id;
  }

  Future<String> createBox({required String boxNumber}) async {
    final row = await into(boxes).insertReturning(
      BoxesCompanion.insert(boxNumber: boxNumber),
    );

    return row.id;
  }

  Future<String> createRentalAssignment({
    required String sellerId,
    required String boxId,
  }) async {
    final active = await activeAssignmentForBox(boxId);
    if (active != null) {
      throw StateError('Box already has an active assignment.');
    }

    final row = await into(rentalAssignments).insertReturning(
      RentalAssignmentsCompanion.insert(
        sellerId: sellerId,
        boxId: boxId,
      ),
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
        await (update(rentalAssignments)..where((tbl) => tbl.id.equals(active.id)))
            .write(
          RentalAssignmentsCompanion(
            endedAt: Value(DateTime.now()),
          ),
        );
      }

      await createRentalAssignment(sellerId: nextSellerId, boxId: boxId);
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

  Future<List<RentalAssignment>> activeAssignmentsForSeller(String sellerId) {
    return (select(rentalAssignments)..where(
          (tbl) => tbl.sellerId.equals(sellerId) & tbl.endedAt.isNull(),
        ))
        .get();
  }

  Future<RentalAssignment?> activeAssignmentForBox(String boxId) {
    return (select(rentalAssignments)..where(
          (tbl) => tbl.boxId.equals(boxId) & tbl.endedAt.isNull(),
        ))
        .getSingleOrNull();
  }

  Future<RentalAssignment?> assignmentById(String assignmentId) {
    return (select(rentalAssignments)
          ..where((tbl) => tbl.id.equals(assignmentId)))
        .getSingleOrNull();
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'rent_a_box_ledger.sqlite'));
    return NativeDatabase(file);
  });
}
