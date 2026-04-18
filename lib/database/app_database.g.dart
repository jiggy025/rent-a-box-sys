// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SellersTable extends Sellers with TableInfo<$SellersTable, Seller> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SellersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactInfoMeta = const VerificationMeta(
    'contactInfo',
  );
  @override
  late final GeneratedColumn<String> contactInfo = GeneratedColumn<String>(
    'contact_info',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    contactInfo,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sellers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Seller> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('contact_info')) {
      context.handle(
        _contactInfoMeta,
        contactInfo.isAcceptableOrUnknown(
          data['contact_info']!,
          _contactInfoMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Seller map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Seller(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      contactInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_info'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SellersTable createAlias(String alias) {
    return $SellersTable(attachedDatabase, alias);
  }
}

class Seller extends DataClass implements Insertable<Seller> {
  final String id;
  final String name;
  final String? contactInfo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Seller({
    required this.id,
    required this.name,
    this.contactInfo,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || contactInfo != null) {
      map['contact_info'] = Variable<String>(contactInfo);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SellersCompanion toCompanion(bool nullToAbsent) {
    return SellersCompanion(
      id: Value(id),
      name: Value(name),
      contactInfo: contactInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(contactInfo),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Seller.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Seller(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      contactInfo: serializer.fromJson<String?>(json['contactInfo']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'contactInfo': serializer.toJson<String?>(contactInfo),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Seller copyWith({
    String? id,
    String? name,
    Value<String?> contactInfo = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Seller(
    id: id ?? this.id,
    name: name ?? this.name,
    contactInfo: contactInfo.present ? contactInfo.value : this.contactInfo,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Seller copyWithCompanion(SellersCompanion data) {
    return Seller(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      contactInfo: data.contactInfo.present
          ? data.contactInfo.value
          : this.contactInfo,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Seller(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contactInfo: $contactInfo, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, contactInfo, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Seller &&
          other.id == this.id &&
          other.name == this.name &&
          other.contactInfo == this.contactInfo &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SellersCompanion extends UpdateCompanion<Seller> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> contactInfo;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SellersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.contactInfo = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SellersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.contactInfo = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Seller> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? contactInfo,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (contactInfo != null) 'contact_info': contactInfo,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SellersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? contactInfo,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SellersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      contactInfo: contactInfo ?? this.contactInfo,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (contactInfo.present) {
      map['contact_info'] = Variable<String>(contactInfo.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SellersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contactInfo: $contactInfo, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoxesTable extends Boxes with TableInfo<$BoxesTable, Boxe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoxesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _boxNumberMeta = const VerificationMeta(
    'boxNumber',
  );
  @override
  late final GeneratedColumn<String> boxNumber = GeneratedColumn<String>(
    'box_number',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    boxNumber,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'boxes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Boxe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('box_number')) {
      context.handle(
        _boxNumberMeta,
        boxNumber.isAcceptableOrUnknown(data['box_number']!, _boxNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_boxNumberMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Boxe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Boxe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boxNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box_number'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BoxesTable createAlias(String alias) {
    return $BoxesTable(attachedDatabase, alias);
  }
}

class Boxe extends DataClass implements Insertable<Boxe> {
  final String id;
  final String boxNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Boxe({
    required this.id,
    required this.boxNumber,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['box_number'] = Variable<String>(boxNumber);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BoxesCompanion toCompanion(bool nullToAbsent) {
    return BoxesCompanion(
      id: Value(id),
      boxNumber: Value(boxNumber),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Boxe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Boxe(
      id: serializer.fromJson<String>(json['id']),
      boxNumber: serializer.fromJson<String>(json['boxNumber']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boxNumber': serializer.toJson<String>(boxNumber),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Boxe copyWith({
    String? id,
    String? boxNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Boxe(
    id: id ?? this.id,
    boxNumber: boxNumber ?? this.boxNumber,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Boxe copyWithCompanion(BoxesCompanion data) {
    return Boxe(
      id: data.id.present ? data.id.value : this.id,
      boxNumber: data.boxNumber.present ? data.boxNumber.value : this.boxNumber,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Boxe(')
          ..write('id: $id, ')
          ..write('boxNumber: $boxNumber, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, boxNumber, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Boxe &&
          other.id == this.id &&
          other.boxNumber == this.boxNumber &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BoxesCompanion extends UpdateCompanion<Boxe> {
  final Value<String> id;
  final Value<String> boxNumber;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BoxesCompanion({
    this.id = const Value.absent(),
    this.boxNumber = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoxesCompanion.insert({
    this.id = const Value.absent(),
    required String boxNumber,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : boxNumber = Value(boxNumber);
  static Insertable<Boxe> custom({
    Expression<String>? id,
    Expression<String>? boxNumber,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boxNumber != null) 'box_number': boxNumber,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoxesCompanion copyWith({
    Value<String>? id,
    Value<String>? boxNumber,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BoxesCompanion(
      id: id ?? this.id,
      boxNumber: boxNumber ?? this.boxNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boxNumber.present) {
      map['box_number'] = Variable<String>(boxNumber.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoxesCompanion(')
          ..write('id: $id, ')
          ..write('boxNumber: $boxNumber, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RentalAssignmentsTable extends RentalAssignments
    with TableInfo<$RentalAssignmentsTable, RentalAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RentalAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _sellerIdMeta = const VerificationMeta(
    'sellerId',
  );
  @override
  late final GeneratedColumn<String> sellerId = GeneratedColumn<String>(
    'seller_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sellers (id)',
    ),
  );
  static const VerificationMeta _boxIdMeta = const VerificationMeta('boxId');
  @override
  late final GeneratedColumn<String> boxId = GeneratedColumn<String>(
    'box_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boxes (id)',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sellerId,
    boxId,
    startedAt,
    endedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rental_assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<RentalAssignment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('seller_id')) {
      context.handle(
        _sellerIdMeta,
        sellerId.isAcceptableOrUnknown(data['seller_id']!, _sellerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sellerIdMeta);
    }
    if (data.containsKey('box_id')) {
      context.handle(
        _boxIdMeta,
        boxId.isAcceptableOrUnknown(data['box_id']!, _boxIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boxIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RentalAssignment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RentalAssignment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sellerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seller_id'],
      )!,
      boxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RentalAssignmentsTable createAlias(String alias) {
    return $RentalAssignmentsTable(attachedDatabase, alias);
  }
}

class RentalAssignment extends DataClass
    implements Insertable<RentalAssignment> {
  final String id;
  final String sellerId;
  final String boxId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  const RentalAssignment({
    required this.id,
    required this.sellerId,
    required this.boxId,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['seller_id'] = Variable<String>(sellerId);
    map['box_id'] = Variable<String>(boxId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RentalAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return RentalAssignmentsCompanion(
      id: Value(id),
      sellerId: Value(sellerId),
      boxId: Value(boxId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      createdAt: Value(createdAt),
    );
  }

  factory RentalAssignment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RentalAssignment(
      id: serializer.fromJson<String>(json['id']),
      sellerId: serializer.fromJson<String>(json['sellerId']),
      boxId: serializer.fromJson<String>(json['boxId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sellerId': serializer.toJson<String>(sellerId),
      'boxId': serializer.toJson<String>(boxId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RentalAssignment copyWith({
    String? id,
    String? sellerId,
    String? boxId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    DateTime? createdAt,
  }) => RentalAssignment(
    id: id ?? this.id,
    sellerId: sellerId ?? this.sellerId,
    boxId: boxId ?? this.boxId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  RentalAssignment copyWithCompanion(RentalAssignmentsCompanion data) {
    return RentalAssignment(
      id: data.id.present ? data.id.value : this.id,
      sellerId: data.sellerId.present ? data.sellerId.value : this.sellerId,
      boxId: data.boxId.present ? data.boxId.value : this.boxId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RentalAssignment(')
          ..write('id: $id, ')
          ..write('sellerId: $sellerId, ')
          ..write('boxId: $boxId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sellerId, boxId, startedAt, endedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RentalAssignment &&
          other.id == this.id &&
          other.sellerId == this.sellerId &&
          other.boxId == this.boxId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.createdAt == this.createdAt);
}

class RentalAssignmentsCompanion extends UpdateCompanion<RentalAssignment> {
  final Value<String> id;
  final Value<String> sellerId;
  final Value<String> boxId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RentalAssignmentsCompanion({
    this.id = const Value.absent(),
    this.sellerId = const Value.absent(),
    this.boxId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RentalAssignmentsCompanion.insert({
    this.id = const Value.absent(),
    required String sellerId,
    required String boxId,
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sellerId = Value(sellerId),
       boxId = Value(boxId);
  static Insertable<RentalAssignment> custom({
    Expression<String>? id,
    Expression<String>? sellerId,
    Expression<String>? boxId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sellerId != null) 'seller_id': sellerId,
      if (boxId != null) 'box_id': boxId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RentalAssignmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? sellerId,
    Value<String>? boxId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RentalAssignmentsCompanion(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      boxId: boxId ?? this.boxId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sellerId.present) {
      map['seller_id'] = Variable<String>(sellerId.value);
    }
    if (boxId.present) {
      map['box_id'] = Variable<String>(boxId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RentalAssignmentsCompanion(')
          ..write('id: $id, ')
          ..write('sellerId: $sellerId, ')
          ..write('boxId: $boxId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LogEntriesTable extends LogEntries
    with TableInfo<$LogEntriesTable, LogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _rentalAssignmentIdMeta =
      const VerificationMeta('rentalAssignmentId');
  @override
  late final GeneratedColumn<String> rentalAssignmentId =
      GeneratedColumn<String>(
        'rental_assignment_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES rental_assignments (id)',
        ),
      );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _claimerNameMeta = const VerificationMeta(
    'claimerName',
  );
  @override
  late final GeneratedColumn<String> claimerName = GeneratedColumn<String>(
    'claimer_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rentalAssignmentId,
    itemName,
    price,
    claimerName,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('rental_assignment_id')) {
      context.handle(
        _rentalAssignmentIdMeta,
        rentalAssignmentId.isAcceptableOrUnknown(
          data['rental_assignment_id']!,
          _rentalAssignmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rentalAssignmentIdMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('claimer_name')) {
      context.handle(
        _claimerNameMeta,
        claimerName.isAcceptableOrUnknown(
          data['claimer_name']!,
          _claimerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_claimerNameMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rentalAssignmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rental_assignment_id'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      claimerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claimer_name'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $LogEntriesTable createAlias(String alias) {
    return $LogEntriesTable(attachedDatabase, alias);
  }
}

class LogEntry extends DataClass implements Insertable<LogEntry> {
  final String id;
  final String rentalAssignmentId;
  final String itemName;
  final double price;
  final String claimerName;
  final DateTime timestamp;
  const LogEntry({
    required this.id,
    required this.rentalAssignmentId,
    required this.itemName,
    required this.price,
    required this.claimerName,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rental_assignment_id'] = Variable<String>(rentalAssignmentId);
    map['item_name'] = Variable<String>(itemName);
    map['price'] = Variable<double>(price);
    map['claimer_name'] = Variable<String>(claimerName);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  LogEntriesCompanion toCompanion(bool nullToAbsent) {
    return LogEntriesCompanion(
      id: Value(id),
      rentalAssignmentId: Value(rentalAssignmentId),
      itemName: Value(itemName),
      price: Value(price),
      claimerName: Value(claimerName),
      timestamp: Value(timestamp),
    );
  }

  factory LogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogEntry(
      id: serializer.fromJson<String>(json['id']),
      rentalAssignmentId: serializer.fromJson<String>(
        json['rentalAssignmentId'],
      ),
      itemName: serializer.fromJson<String>(json['itemName']),
      price: serializer.fromJson<double>(json['price']),
      claimerName: serializer.fromJson<String>(json['claimerName']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rentalAssignmentId': serializer.toJson<String>(rentalAssignmentId),
      'itemName': serializer.toJson<String>(itemName),
      'price': serializer.toJson<double>(price),
      'claimerName': serializer.toJson<String>(claimerName),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  LogEntry copyWith({
    String? id,
    String? rentalAssignmentId,
    String? itemName,
    double? price,
    String? claimerName,
    DateTime? timestamp,
  }) => LogEntry(
    id: id ?? this.id,
    rentalAssignmentId: rentalAssignmentId ?? this.rentalAssignmentId,
    itemName: itemName ?? this.itemName,
    price: price ?? this.price,
    claimerName: claimerName ?? this.claimerName,
    timestamp: timestamp ?? this.timestamp,
  );
  LogEntry copyWithCompanion(LogEntriesCompanion data) {
    return LogEntry(
      id: data.id.present ? data.id.value : this.id,
      rentalAssignmentId: data.rentalAssignmentId.present
          ? data.rentalAssignmentId.value
          : this.rentalAssignmentId,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      price: data.price.present ? data.price.value : this.price,
      claimerName: data.claimerName.present
          ? data.claimerName.value
          : this.claimerName,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogEntry(')
          ..write('id: $id, ')
          ..write('rentalAssignmentId: $rentalAssignmentId, ')
          ..write('itemName: $itemName, ')
          ..write('price: $price, ')
          ..write('claimerName: $claimerName, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rentalAssignmentId,
    itemName,
    price,
    claimerName,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogEntry &&
          other.id == this.id &&
          other.rentalAssignmentId == this.rentalAssignmentId &&
          other.itemName == this.itemName &&
          other.price == this.price &&
          other.claimerName == this.claimerName &&
          other.timestamp == this.timestamp);
}

class LogEntriesCompanion extends UpdateCompanion<LogEntry> {
  final Value<String> id;
  final Value<String> rentalAssignmentId;
  final Value<String> itemName;
  final Value<double> price;
  final Value<String> claimerName;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const LogEntriesCompanion({
    this.id = const Value.absent(),
    this.rentalAssignmentId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.price = const Value.absent(),
    this.claimerName = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LogEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String rentalAssignmentId,
    required String itemName,
    required double price,
    required String claimerName,
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : rentalAssignmentId = Value(rentalAssignmentId),
       itemName = Value(itemName),
       price = Value(price),
       claimerName = Value(claimerName);
  static Insertable<LogEntry> custom({
    Expression<String>? id,
    Expression<String>? rentalAssignmentId,
    Expression<String>? itemName,
    Expression<double>? price,
    Expression<String>? claimerName,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rentalAssignmentId != null)
        'rental_assignment_id': rentalAssignmentId,
      if (itemName != null) 'item_name': itemName,
      if (price != null) 'price': price,
      if (claimerName != null) 'claimer_name': claimerName,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LogEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? rentalAssignmentId,
    Value<String>? itemName,
    Value<double>? price,
    Value<String>? claimerName,
    Value<DateTime>? timestamp,
    Value<int>? rowid,
  }) {
    return LogEntriesCompanion(
      id: id ?? this.id,
      rentalAssignmentId: rentalAssignmentId ?? this.rentalAssignmentId,
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      claimerName: claimerName ?? this.claimerName,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rentalAssignmentId.present) {
      map['rental_assignment_id'] = Variable<String>(rentalAssignmentId.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (claimerName.present) {
      map['claimer_name'] = Variable<String>(claimerName.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('rentalAssignmentId: $rentalAssignmentId, ')
          ..write('itemName: $itemName, ')
          ..write('price: $price, ')
          ..write('claimerName: $claimerName, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SellersTable sellers = $SellersTable(this);
  late final $BoxesTable boxes = $BoxesTable(this);
  late final $RentalAssignmentsTable rentalAssignments =
      $RentalAssignmentsTable(this);
  late final $LogEntriesTable logEntries = $LogEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sellers,
    boxes,
    rentalAssignments,
    logEntries,
  ];
}

typedef $$SellersTableCreateCompanionBuilder =
    SellersCompanion Function({
      Value<String> id,
      required String name,
      Value<String?> contactInfo,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SellersTableUpdateCompanionBuilder =
    SellersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> contactInfo,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SellersTableReferences
    extends BaseReferences<_$AppDatabase, $SellersTable, Seller> {
  $$SellersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RentalAssignmentsTable, List<RentalAssignment>>
  _rentalAssignmentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rentalAssignments,
        aliasName: $_aliasNameGenerator(
          db.sellers.id,
          db.rentalAssignments.sellerId,
        ),
      );

  $$RentalAssignmentsTableProcessedTableManager get rentalAssignmentsRefs {
    final manager = $$RentalAssignmentsTableTableManager(
      $_db,
      $_db.rentalAssignments,
    ).filter((f) => f.sellerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _rentalAssignmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SellersTableFilterComposer
    extends Composer<_$AppDatabase, $SellersTable> {
  $$SellersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactInfo => $composableBuilder(
    column: $table.contactInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> rentalAssignmentsRefs(
    Expression<bool> Function($$RentalAssignmentsTableFilterComposer f) f,
  ) {
    final $$RentalAssignmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rentalAssignments,
      getReferencedColumn: (t) => t.sellerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RentalAssignmentsTableFilterComposer(
            $db: $db,
            $table: $db.rentalAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SellersTableOrderingComposer
    extends Composer<_$AppDatabase, $SellersTable> {
  $$SellersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactInfo => $composableBuilder(
    column: $table.contactInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SellersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SellersTable> {
  $$SellersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get contactInfo => $composableBuilder(
    column: $table.contactInfo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> rentalAssignmentsRefs<T extends Object>(
    Expression<T> Function($$RentalAssignmentsTableAnnotationComposer a) f,
  ) {
    final $$RentalAssignmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.rentalAssignments,
          getReferencedColumn: (t) => t.sellerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RentalAssignmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.rentalAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SellersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SellersTable,
          Seller,
          $$SellersTableFilterComposer,
          $$SellersTableOrderingComposer,
          $$SellersTableAnnotationComposer,
          $$SellersTableCreateCompanionBuilder,
          $$SellersTableUpdateCompanionBuilder,
          (Seller, $$SellersTableReferences),
          Seller,
          PrefetchHooks Function({bool rentalAssignmentsRefs})
        > {
  $$SellersTableTableManager(_$AppDatabase db, $SellersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SellersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SellersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SellersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> contactInfo = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SellersCompanion(
                id: id,
                name: name,
                contactInfo: contactInfo,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                Value<String?> contactInfo = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SellersCompanion.insert(
                id: id,
                name: name,
                contactInfo: contactInfo,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SellersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({rentalAssignmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (rentalAssignmentsRefs) db.rentalAssignments,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (rentalAssignmentsRefs)
                    await $_getPrefetchedData<
                      Seller,
                      $SellersTable,
                      RentalAssignment
                    >(
                      currentTable: table,
                      referencedTable: $$SellersTableReferences
                          ._rentalAssignmentsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SellersTableReferences(
                        db,
                        table,
                        p0,
                      ).rentalAssignmentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sellerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SellersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SellersTable,
      Seller,
      $$SellersTableFilterComposer,
      $$SellersTableOrderingComposer,
      $$SellersTableAnnotationComposer,
      $$SellersTableCreateCompanionBuilder,
      $$SellersTableUpdateCompanionBuilder,
      (Seller, $$SellersTableReferences),
      Seller,
      PrefetchHooks Function({bool rentalAssignmentsRefs})
    >;
typedef $$BoxesTableCreateCompanionBuilder =
    BoxesCompanion Function({
      Value<String> id,
      required String boxNumber,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BoxesTableUpdateCompanionBuilder =
    BoxesCompanion Function({
      Value<String> id,
      Value<String> boxNumber,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BoxesTableReferences
    extends BaseReferences<_$AppDatabase, $BoxesTable, Boxe> {
  $$BoxesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RentalAssignmentsTable, List<RentalAssignment>>
  _rentalAssignmentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rentalAssignments,
        aliasName: $_aliasNameGenerator(
          db.boxes.id,
          db.rentalAssignments.boxId,
        ),
      );

  $$RentalAssignmentsTableProcessedTableManager get rentalAssignmentsRefs {
    final manager = $$RentalAssignmentsTableTableManager(
      $_db,
      $_db.rentalAssignments,
    ).filter((f) => f.boxId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _rentalAssignmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BoxesTableFilterComposer extends Composer<_$AppDatabase, $BoxesTable> {
  $$BoxesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boxNumber => $composableBuilder(
    column: $table.boxNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> rentalAssignmentsRefs(
    Expression<bool> Function($$RentalAssignmentsTableFilterComposer f) f,
  ) {
    final $$RentalAssignmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rentalAssignments,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RentalAssignmentsTableFilterComposer(
            $db: $db,
            $table: $db.rentalAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoxesTableOrderingComposer
    extends Composer<_$AppDatabase, $BoxesTable> {
  $$BoxesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boxNumber => $composableBuilder(
    column: $table.boxNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoxesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoxesTable> {
  $$BoxesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get boxNumber =>
      $composableBuilder(column: $table.boxNumber, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> rentalAssignmentsRefs<T extends Object>(
    Expression<T> Function($$RentalAssignmentsTableAnnotationComposer a) f,
  ) {
    final $$RentalAssignmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.rentalAssignments,
          getReferencedColumn: (t) => t.boxId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RentalAssignmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.rentalAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BoxesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoxesTable,
          Boxe,
          $$BoxesTableFilterComposer,
          $$BoxesTableOrderingComposer,
          $$BoxesTableAnnotationComposer,
          $$BoxesTableCreateCompanionBuilder,
          $$BoxesTableUpdateCompanionBuilder,
          (Boxe, $$BoxesTableReferences),
          Boxe,
          PrefetchHooks Function({bool rentalAssignmentsRefs})
        > {
  $$BoxesTableTableManager(_$AppDatabase db, $BoxesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoxesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoxesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoxesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> boxNumber = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoxesCompanion(
                id: id,
                boxNumber: boxNumber,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String boxNumber,
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoxesCompanion.insert(
                id: id,
                boxNumber: boxNumber,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BoxesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({rentalAssignmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (rentalAssignmentsRefs) db.rentalAssignments,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (rentalAssignmentsRefs)
                    await $_getPrefetchedData<
                      Boxe,
                      $BoxesTable,
                      RentalAssignment
                    >(
                      currentTable: table,
                      referencedTable: $$BoxesTableReferences
                          ._rentalAssignmentsRefsTable(db),
                      managerFromTypedResult: (p0) => $$BoxesTableReferences(
                        db,
                        table,
                        p0,
                      ).rentalAssignmentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.boxId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BoxesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoxesTable,
      Boxe,
      $$BoxesTableFilterComposer,
      $$BoxesTableOrderingComposer,
      $$BoxesTableAnnotationComposer,
      $$BoxesTableCreateCompanionBuilder,
      $$BoxesTableUpdateCompanionBuilder,
      (Boxe, $$BoxesTableReferences),
      Boxe,
      PrefetchHooks Function({bool rentalAssignmentsRefs})
    >;
typedef $$RentalAssignmentsTableCreateCompanionBuilder =
    RentalAssignmentsCompanion Function({
      Value<String> id,
      required String sellerId,
      required String boxId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$RentalAssignmentsTableUpdateCompanionBuilder =
    RentalAssignmentsCompanion Function({
      Value<String> id,
      Value<String> sellerId,
      Value<String> boxId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$RentalAssignmentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RentalAssignmentsTable,
          RentalAssignment
        > {
  $$RentalAssignmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SellersTable _sellerIdTable(_$AppDatabase db) =>
      db.sellers.createAlias(
        $_aliasNameGenerator(db.rentalAssignments.sellerId, db.sellers.id),
      );

  $$SellersTableProcessedTableManager get sellerId {
    final $_column = $_itemColumn<String>('seller_id')!;

    final manager = $$SellersTableTableManager(
      $_db,
      $_db.sellers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sellerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BoxesTable _boxIdTable(_$AppDatabase db) => db.boxes.createAlias(
    $_aliasNameGenerator(db.rentalAssignments.boxId, db.boxes.id),
  );

  $$BoxesTableProcessedTableManager get boxId {
    final $_column = $_itemColumn<String>('box_id')!;

    final manager = $$BoxesTableTableManager(
      $_db,
      $_db.boxes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LogEntriesTable, List<LogEntry>>
  _logEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.logEntries,
    aliasName: $_aliasNameGenerator(
      db.rentalAssignments.id,
      db.logEntries.rentalAssignmentId,
    ),
  );

  $$LogEntriesTableProcessedTableManager get logEntriesRefs {
    final manager = $$LogEntriesTableTableManager($_db, $_db.logEntries).filter(
      (f) => f.rentalAssignmentId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_logEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RentalAssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $RentalAssignmentsTable> {
  $$RentalAssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SellersTableFilterComposer get sellerId {
    final $$SellersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sellerId,
      referencedTable: $db.sellers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SellersTableFilterComposer(
            $db: $db,
            $table: $db.sellers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoxesTableFilterComposer get boxId {
    final $$BoxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableFilterComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> logEntriesRefs(
    Expression<bool> Function($$LogEntriesTableFilterComposer f) f,
  ) {
    final $$LogEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.rentalAssignmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogEntriesTableFilterComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RentalAssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RentalAssignmentsTable> {
  $$RentalAssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SellersTableOrderingComposer get sellerId {
    final $$SellersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sellerId,
      referencedTable: $db.sellers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SellersTableOrderingComposer(
            $db: $db,
            $table: $db.sellers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoxesTableOrderingComposer get boxId {
    final $$BoxesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableOrderingComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RentalAssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RentalAssignmentsTable> {
  $$RentalAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SellersTableAnnotationComposer get sellerId {
    final $$SellersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sellerId,
      referencedTable: $db.sellers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SellersTableAnnotationComposer(
            $db: $db,
            $table: $db.sellers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoxesTableAnnotationComposer get boxId {
    final $$BoxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableAnnotationComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> logEntriesRefs<T extends Object>(
    Expression<T> Function($$LogEntriesTableAnnotationComposer a) f,
  ) {
    final $$LogEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.rentalAssignmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RentalAssignmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RentalAssignmentsTable,
          RentalAssignment,
          $$RentalAssignmentsTableFilterComposer,
          $$RentalAssignmentsTableOrderingComposer,
          $$RentalAssignmentsTableAnnotationComposer,
          $$RentalAssignmentsTableCreateCompanionBuilder,
          $$RentalAssignmentsTableUpdateCompanionBuilder,
          (RentalAssignment, $$RentalAssignmentsTableReferences),
          RentalAssignment,
          PrefetchHooks Function({
            bool sellerId,
            bool boxId,
            bool logEntriesRefs,
          })
        > {
  $$RentalAssignmentsTableTableManager(
    _$AppDatabase db,
    $RentalAssignmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RentalAssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RentalAssignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RentalAssignmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sellerId = const Value.absent(),
                Value<String> boxId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentalAssignmentsCompanion(
                id: id,
                sellerId: sellerId,
                boxId: boxId,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String sellerId,
                required String boxId,
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentalAssignmentsCompanion.insert(
                id: id,
                sellerId: sellerId,
                boxId: boxId,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RentalAssignmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sellerId = false, boxId = false, logEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (logEntriesRefs) db.logEntries],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sellerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sellerId,
                                    referencedTable:
                                        $$RentalAssignmentsTableReferences
                                            ._sellerIdTable(db),
                                    referencedColumn:
                                        $$RentalAssignmentsTableReferences
                                            ._sellerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (boxId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.boxId,
                                    referencedTable:
                                        $$RentalAssignmentsTableReferences
                                            ._boxIdTable(db),
                                    referencedColumn:
                                        $$RentalAssignmentsTableReferences
                                            ._boxIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (logEntriesRefs)
                        await $_getPrefetchedData<
                          RentalAssignment,
                          $RentalAssignmentsTable,
                          LogEntry
                        >(
                          currentTable: table,
                          referencedTable: $$RentalAssignmentsTableReferences
                              ._logEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RentalAssignmentsTableReferences(
                                db,
                                table,
                                p0,
                              ).logEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.rentalAssignmentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RentalAssignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RentalAssignmentsTable,
      RentalAssignment,
      $$RentalAssignmentsTableFilterComposer,
      $$RentalAssignmentsTableOrderingComposer,
      $$RentalAssignmentsTableAnnotationComposer,
      $$RentalAssignmentsTableCreateCompanionBuilder,
      $$RentalAssignmentsTableUpdateCompanionBuilder,
      (RentalAssignment, $$RentalAssignmentsTableReferences),
      RentalAssignment,
      PrefetchHooks Function({bool sellerId, bool boxId, bool logEntriesRefs})
    >;
typedef $$LogEntriesTableCreateCompanionBuilder =
    LogEntriesCompanion Function({
      Value<String> id,
      required String rentalAssignmentId,
      required String itemName,
      required double price,
      required String claimerName,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });
typedef $$LogEntriesTableUpdateCompanionBuilder =
    LogEntriesCompanion Function({
      Value<String> id,
      Value<String> rentalAssignmentId,
      Value<String> itemName,
      Value<double> price,
      Value<String> claimerName,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });

final class $$LogEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry> {
  $$LogEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RentalAssignmentsTable _rentalAssignmentIdTable(_$AppDatabase db) =>
      db.rentalAssignments.createAlias(
        $_aliasNameGenerator(
          db.logEntries.rentalAssignmentId,
          db.rentalAssignments.id,
        ),
      );

  $$RentalAssignmentsTableProcessedTableManager get rentalAssignmentId {
    final $_column = $_itemColumn<String>('rental_assignment_id')!;

    final manager = $$RentalAssignmentsTableTableManager(
      $_db,
      $_db.rentalAssignments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rentalAssignmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claimerName => $composableBuilder(
    column: $table.claimerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$RentalAssignmentsTableFilterComposer get rentalAssignmentId {
    final $$RentalAssignmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rentalAssignmentId,
      referencedTable: $db.rentalAssignments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RentalAssignmentsTableFilterComposer(
            $db: $db,
            $table: $db.rentalAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimerName => $composableBuilder(
    column: $table.claimerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$RentalAssignmentsTableOrderingComposer get rentalAssignmentId {
    final $$RentalAssignmentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rentalAssignmentId,
      referencedTable: $db.rentalAssignments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RentalAssignmentsTableOrderingComposer(
            $db: $db,
            $table: $db.rentalAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get claimerName => $composableBuilder(
    column: $table.claimerName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$RentalAssignmentsTableAnnotationComposer get rentalAssignmentId {
    final $$RentalAssignmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.rentalAssignmentId,
          referencedTable: $db.rentalAssignments,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RentalAssignmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.rentalAssignments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogEntriesTable,
          LogEntry,
          $$LogEntriesTableFilterComposer,
          $$LogEntriesTableOrderingComposer,
          $$LogEntriesTableAnnotationComposer,
          $$LogEntriesTableCreateCompanionBuilder,
          $$LogEntriesTableUpdateCompanionBuilder,
          (LogEntry, $$LogEntriesTableReferences),
          LogEntry,
          PrefetchHooks Function({bool rentalAssignmentId})
        > {
  $$LogEntriesTableTableManager(_$AppDatabase db, $LogEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rentalAssignmentId = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String> claimerName = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogEntriesCompanion(
                id: id,
                rentalAssignmentId: rentalAssignmentId,
                itemName: itemName,
                price: price,
                claimerName: claimerName,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String rentalAssignmentId,
                required String itemName,
                required double price,
                required String claimerName,
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogEntriesCompanion.insert(
                id: id,
                rentalAssignmentId: rentalAssignmentId,
                itemName: itemName,
                price: price,
                claimerName: claimerName,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LogEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({rentalAssignmentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (rentalAssignmentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.rentalAssignmentId,
                                referencedTable: $$LogEntriesTableReferences
                                    ._rentalAssignmentIdTable(db),
                                referencedColumn: $$LogEntriesTableReferences
                                    ._rentalAssignmentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogEntriesTable,
      LogEntry,
      $$LogEntriesTableFilterComposer,
      $$LogEntriesTableOrderingComposer,
      $$LogEntriesTableAnnotationComposer,
      $$LogEntriesTableCreateCompanionBuilder,
      $$LogEntriesTableUpdateCompanionBuilder,
      (LogEntry, $$LogEntriesTableReferences),
      LogEntry,
      PrefetchHooks Function({bool rentalAssignmentId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SellersTableTableManager get sellers =>
      $$SellersTableTableManager(_db, _db.sellers);
  $$BoxesTableTableManager get boxes =>
      $$BoxesTableTableManager(_db, _db.boxes);
  $$RentalAssignmentsTableTableManager get rentalAssignments =>
      $$RentalAssignmentsTableTableManager(_db, _db.rentalAssignments);
  $$LogEntriesTableTableManager get logEntries =>
      $$LogEntriesTableTableManager(_db, _db.logEntries);
}
