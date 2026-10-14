// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserProfileTable extends UserProfile
    with TableInfo<$UserProfileTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthdateMeta = const VerificationMeta(
    'birthdate',
  );
  @override
  late final GeneratedColumn<DateTime> birthdate = GeneratedColumn<DateTime>(
    'birthdate',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themePreferenceMeta = const VerificationMeta(
    'themePreference',
  );
  @override
  late final GeneratedColumn<String> themePreference = GeneratedColumn<String>(
    'theme_preference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appLockModeMeta = const VerificationMeta(
    'appLockMode',
  );
  @override
  late final GeneratedColumn<String> appLockMode = GeneratedColumn<String>(
    'app_lock_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    clientDefault: () => DateTime.now(),
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
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    displayName,
    birthdate,
    themePreference,
    appLockMode,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('birthdate')) {
      context.handle(
        _birthdateMeta,
        birthdate.isAcceptableOrUnknown(data['birthdate']!, _birthdateMeta),
      );
    }
    if (data.containsKey('theme_preference')) {
      context.handle(
        _themePreferenceMeta,
        themePreference.isAcceptableOrUnknown(
          data['theme_preference']!,
          _themePreferenceMeta,
        ),
      );
    }
    if (data.containsKey('app_lock_mode')) {
      context.handle(
        _appLockModeMeta,
        appLockMode.isAcceptableOrUnknown(
          data['app_lock_mode']!,
          _appLockModeMeta,
        ),
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
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      birthdate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birthdate'],
      ),
      themePreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_preference'],
      ),
      appLockMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_lock_mode'],
      ),
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
  $UserProfileTable createAlias(String alias) {
    return $UserProfileTable(attachedDatabase, alias);
  }
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final String id;
  final String? userId;
  final String? displayName;
  final DateTime? birthdate;
  final String? themePreference;
  final String? appLockMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserProfileRow({
    required this.id,
    this.userId,
    this.displayName,
    this.birthdate,
    this.themePreference,
    this.appLockMode,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || birthdate != null) {
      map['birthdate'] = Variable<DateTime>(birthdate);
    }
    if (!nullToAbsent || themePreference != null) {
      map['theme_preference'] = Variable<String>(themePreference);
    }
    if (!nullToAbsent || appLockMode != null) {
      map['app_lock_mode'] = Variable<String>(appLockMode);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfileCompanion toCompanion(bool nullToAbsent) {
    return UserProfileCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      birthdate: birthdate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthdate),
      themePreference: themePreference == null && nullToAbsent
          ? const Value.absent()
          : Value(themePreference),
      appLockMode: appLockMode == null && nullToAbsent
          ? const Value.absent()
          : Value(appLockMode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      birthdate: serializer.fromJson<DateTime?>(json['birthdate']),
      themePreference: serializer.fromJson<String?>(json['themePreference']),
      appLockMode: serializer.fromJson<String?>(json['appLockMode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'displayName': serializer.toJson<String?>(displayName),
      'birthdate': serializer.toJson<DateTime?>(birthdate),
      'themePreference': serializer.toJson<String?>(themePreference),
      'appLockMode': serializer.toJson<String?>(appLockMode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfileRow copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    Value<String?> displayName = const Value.absent(),
    Value<DateTime?> birthdate = const Value.absent(),
    Value<String?> themePreference = const Value.absent(),
    Value<String?> appLockMode = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfileRow(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    displayName: displayName.present ? displayName.value : this.displayName,
    birthdate: birthdate.present ? birthdate.value : this.birthdate,
    themePreference: themePreference.present
        ? themePreference.value
        : this.themePreference,
    appLockMode: appLockMode.present ? appLockMode.value : this.appLockMode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserProfileRow copyWithCompanion(UserProfileCompanion data) {
    return UserProfileRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      birthdate: data.birthdate.present ? data.birthdate.value : this.birthdate,
      themePreference: data.themePreference.present
          ? data.themePreference.value
          : this.themePreference,
      appLockMode: data.appLockMode.present
          ? data.appLockMode.value
          : this.appLockMode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('birthdate: $birthdate, ')
          ..write('themePreference: $themePreference, ')
          ..write('appLockMode: $appLockMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    displayName,
    birthdate,
    themePreference,
    appLockMode,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.displayName == this.displayName &&
          other.birthdate == this.birthdate &&
          other.themePreference == this.themePreference &&
          other.appLockMode == this.appLockMode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfileCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String?> displayName;
  final Value<DateTime?> birthdate;
  final Value<String?> themePreference;
  final Value<String?> appLockMode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserProfileCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.birthdate = const Value.absent(),
    this.themePreference = const Value.absent(),
    this.appLockMode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfileCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.birthdate = const Value.absent(),
    this.themePreference = const Value.absent(),
    this.appLockMode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<UserProfileRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? displayName,
    Expression<DateTime>? birthdate,
    Expression<String>? themePreference,
    Expression<String>? appLockMode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (birthdate != null) 'birthdate': birthdate,
      if (themePreference != null) 'theme_preference': themePreference,
      if (appLockMode != null) 'app_lock_mode': appLockMode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfileCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String?>? displayName,
    Value<DateTime?>? birthdate,
    Value<String?>? themePreference,
    Value<String?>? appLockMode,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserProfileCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      birthdate: birthdate ?? this.birthdate,
      themePreference: themePreference ?? this.themePreference,
      appLockMode: appLockMode ?? this.appLockMode,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (birthdate.present) {
      map['birthdate'] = Variable<DateTime>(birthdate.value);
    }
    if (themePreference.present) {
      map['theme_preference'] = Variable<String>(themePreference.value);
    }
    if (appLockMode.present) {
      map['app_lock_mode'] = Variable<String>(appLockMode.value);
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
    return (StringBuffer('UserProfileCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('birthdate: $birthdate, ')
          ..write('themePreference: $themePreference, ')
          ..write('appLockMode: $appLockMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemoteStatusCacheTable extends RemoteStatusCache
    with TableInfo<$RemoteStatusCacheTable, RemoteStatusCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteStatusCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastCheckedAtMeta = const VerificationMeta(
    'lastCheckedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCheckedAt =
      GeneratedColumn<DateTime>(
        'last_checked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _maintenanceModeMeta = const VerificationMeta(
    'maintenanceMode',
  );
  @override
  late final GeneratedColumn<bool> maintenanceMode = GeneratedColumn<bool>(
    'maintenance_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("maintenance_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _maintenanceMessageMeta =
      const VerificationMeta('maintenanceMessage');
  @override
  late final GeneratedColumn<String> maintenanceMessage =
      GeneratedColumn<String>(
        'maintenance_message',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _killSwitchMeta = const VerificationMeta(
    'killSwitch',
  );
  @override
  late final GeneratedColumn<bool> killSwitch = GeneratedColumn<bool>(
    'kill_switch',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("kill_switch" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastKnownGoodMeta = const VerificationMeta(
    'lastKnownGood',
  );
  @override
  late final GeneratedColumn<bool> lastKnownGood = GeneratedColumn<bool>(
    'last_known_good',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("last_known_good" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lastCheckedAt,
    maintenanceMode,
    maintenanceMessage,
    killSwitch,
    lastKnownGood,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_status_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteStatusCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('last_checked_at')) {
      context.handle(
        _lastCheckedAtMeta,
        lastCheckedAt.isAcceptableOrUnknown(
          data['last_checked_at']!,
          _lastCheckedAtMeta,
        ),
      );
    }
    if (data.containsKey('maintenance_mode')) {
      context.handle(
        _maintenanceModeMeta,
        maintenanceMode.isAcceptableOrUnknown(
          data['maintenance_mode']!,
          _maintenanceModeMeta,
        ),
      );
    }
    if (data.containsKey('maintenance_message')) {
      context.handle(
        _maintenanceMessageMeta,
        maintenanceMessage.isAcceptableOrUnknown(
          data['maintenance_message']!,
          _maintenanceMessageMeta,
        ),
      );
    }
    if (data.containsKey('kill_switch')) {
      context.handle(
        _killSwitchMeta,
        killSwitch.isAcceptableOrUnknown(data['kill_switch']!, _killSwitchMeta),
      );
    }
    if (data.containsKey('last_known_good')) {
      context.handle(
        _lastKnownGoodMeta,
        lastKnownGood.isAcceptableOrUnknown(
          data['last_known_good']!,
          _lastKnownGoodMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemoteStatusCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteStatusCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lastCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_checked_at'],
      ),
      maintenanceMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}maintenance_mode'],
      )!,
      maintenanceMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}maintenance_message'],
      ),
      killSwitch: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}kill_switch'],
      )!,
      lastKnownGood: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}last_known_good'],
      )!,
    );
  }

  @override
  $RemoteStatusCacheTable createAlias(String alias) {
    return $RemoteStatusCacheTable(attachedDatabase, alias);
  }
}

class RemoteStatusCacheRow extends DataClass
    implements Insertable<RemoteStatusCacheRow> {
  final String id;
  final DateTime? lastCheckedAt;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final bool killSwitch;
  final bool lastKnownGood;
  const RemoteStatusCacheRow({
    required this.id,
    this.lastCheckedAt,
    required this.maintenanceMode,
    this.maintenanceMessage,
    required this.killSwitch,
    required this.lastKnownGood,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || lastCheckedAt != null) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt);
    }
    map['maintenance_mode'] = Variable<bool>(maintenanceMode);
    if (!nullToAbsent || maintenanceMessage != null) {
      map['maintenance_message'] = Variable<String>(maintenanceMessage);
    }
    map['kill_switch'] = Variable<bool>(killSwitch);
    map['last_known_good'] = Variable<bool>(lastKnownGood);
    return map;
  }

  RemoteStatusCacheCompanion toCompanion(bool nullToAbsent) {
    return RemoteStatusCacheCompanion(
      id: Value(id),
      lastCheckedAt: lastCheckedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckedAt),
      maintenanceMode: Value(maintenanceMode),
      maintenanceMessage: maintenanceMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(maintenanceMessage),
      killSwitch: Value(killSwitch),
      lastKnownGood: Value(lastKnownGood),
    );
  }

  factory RemoteStatusCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteStatusCacheRow(
      id: serializer.fromJson<String>(json['id']),
      lastCheckedAt: serializer.fromJson<DateTime?>(json['lastCheckedAt']),
      maintenanceMode: serializer.fromJson<bool>(json['maintenanceMode']),
      maintenanceMessage: serializer.fromJson<String?>(
        json['maintenanceMessage'],
      ),
      killSwitch: serializer.fromJson<bool>(json['killSwitch']),
      lastKnownGood: serializer.fromJson<bool>(json['lastKnownGood']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lastCheckedAt': serializer.toJson<DateTime?>(lastCheckedAt),
      'maintenanceMode': serializer.toJson<bool>(maintenanceMode),
      'maintenanceMessage': serializer.toJson<String?>(maintenanceMessage),
      'killSwitch': serializer.toJson<bool>(killSwitch),
      'lastKnownGood': serializer.toJson<bool>(lastKnownGood),
    };
  }

  RemoteStatusCacheRow copyWith({
    String? id,
    Value<DateTime?> lastCheckedAt = const Value.absent(),
    bool? maintenanceMode,
    Value<String?> maintenanceMessage = const Value.absent(),
    bool? killSwitch,
    bool? lastKnownGood,
  }) => RemoteStatusCacheRow(
    id: id ?? this.id,
    lastCheckedAt: lastCheckedAt.present
        ? lastCheckedAt.value
        : this.lastCheckedAt,
    maintenanceMode: maintenanceMode ?? this.maintenanceMode,
    maintenanceMessage: maintenanceMessage.present
        ? maintenanceMessage.value
        : this.maintenanceMessage,
    killSwitch: killSwitch ?? this.killSwitch,
    lastKnownGood: lastKnownGood ?? this.lastKnownGood,
  );
  RemoteStatusCacheRow copyWithCompanion(RemoteStatusCacheCompanion data) {
    return RemoteStatusCacheRow(
      id: data.id.present ? data.id.value : this.id,
      lastCheckedAt: data.lastCheckedAt.present
          ? data.lastCheckedAt.value
          : this.lastCheckedAt,
      maintenanceMode: data.maintenanceMode.present
          ? data.maintenanceMode.value
          : this.maintenanceMode,
      maintenanceMessage: data.maintenanceMessage.present
          ? data.maintenanceMessage.value
          : this.maintenanceMessage,
      killSwitch: data.killSwitch.present
          ? data.killSwitch.value
          : this.killSwitch,
      lastKnownGood: data.lastKnownGood.present
          ? data.lastKnownGood.value
          : this.lastKnownGood,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteStatusCacheRow(')
          ..write('id: $id, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('maintenanceMode: $maintenanceMode, ')
          ..write('maintenanceMessage: $maintenanceMessage, ')
          ..write('killSwitch: $killSwitch, ')
          ..write('lastKnownGood: $lastKnownGood')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lastCheckedAt,
    maintenanceMode,
    maintenanceMessage,
    killSwitch,
    lastKnownGood,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteStatusCacheRow &&
          other.id == this.id &&
          other.lastCheckedAt == this.lastCheckedAt &&
          other.maintenanceMode == this.maintenanceMode &&
          other.maintenanceMessage == this.maintenanceMessage &&
          other.killSwitch == this.killSwitch &&
          other.lastKnownGood == this.lastKnownGood);
}

class RemoteStatusCacheCompanion extends UpdateCompanion<RemoteStatusCacheRow> {
  final Value<String> id;
  final Value<DateTime?> lastCheckedAt;
  final Value<bool> maintenanceMode;
  final Value<String?> maintenanceMessage;
  final Value<bool> killSwitch;
  final Value<bool> lastKnownGood;
  final Value<int> rowid;
  const RemoteStatusCacheCompanion({
    this.id = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.maintenanceMode = const Value.absent(),
    this.maintenanceMessage = const Value.absent(),
    this.killSwitch = const Value.absent(),
    this.lastKnownGood = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteStatusCacheCompanion.insert({
    required String id,
    this.lastCheckedAt = const Value.absent(),
    this.maintenanceMode = const Value.absent(),
    this.maintenanceMessage = const Value.absent(),
    this.killSwitch = const Value.absent(),
    this.lastKnownGood = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<RemoteStatusCacheRow> custom({
    Expression<String>? id,
    Expression<DateTime>? lastCheckedAt,
    Expression<bool>? maintenanceMode,
    Expression<String>? maintenanceMessage,
    Expression<bool>? killSwitch,
    Expression<bool>? lastKnownGood,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastCheckedAt != null) 'last_checked_at': lastCheckedAt,
      if (maintenanceMode != null) 'maintenance_mode': maintenanceMode,
      if (maintenanceMessage != null) 'maintenance_message': maintenanceMessage,
      if (killSwitch != null) 'kill_switch': killSwitch,
      if (lastKnownGood != null) 'last_known_good': lastKnownGood,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteStatusCacheCompanion copyWith({
    Value<String>? id,
    Value<DateTime?>? lastCheckedAt,
    Value<bool>? maintenanceMode,
    Value<String?>? maintenanceMessage,
    Value<bool>? killSwitch,
    Value<bool>? lastKnownGood,
    Value<int>? rowid,
  }) {
    return RemoteStatusCacheCompanion(
      id: id ?? this.id,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      killSwitch: killSwitch ?? this.killSwitch,
      lastKnownGood: lastKnownGood ?? this.lastKnownGood,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lastCheckedAt.present) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt.value);
    }
    if (maintenanceMode.present) {
      map['maintenance_mode'] = Variable<bool>(maintenanceMode.value);
    }
    if (maintenanceMessage.present) {
      map['maintenance_message'] = Variable<String>(maintenanceMessage.value);
    }
    if (killSwitch.present) {
      map['kill_switch'] = Variable<bool>(killSwitch.value);
    }
    if (lastKnownGood.present) {
      map['last_known_good'] = Variable<bool>(lastKnownGood.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteStatusCacheCompanion(')
          ..write('id: $id, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('maintenanceMode: $maintenanceMode, ')
          ..write('maintenanceMessage: $maintenanceMessage, ')
          ..write('killSwitch: $killSwitch, ')
          ..write('lastKnownGood: $lastKnownGood, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserProfileTable userProfile = $UserProfileTable(this);
  late final $RemoteStatusCacheTable remoteStatusCache =
      $RemoteStatusCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userProfile,
    remoteStatusCache,
  ];
}

typedef $$UserProfileTableCreateCompanionBuilder =
    UserProfileCompanion Function({
      required String id,
      Value<String?> userId,
      Value<String?> displayName,
      Value<DateTime?> birthdate,
      Value<String?> themePreference,
      Value<String?> appLockMode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserProfileTableUpdateCompanionBuilder =
    UserProfileCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String?> displayName,
      Value<DateTime?> birthdate,
      Value<String?> themePreference,
      Value<String?> appLockMode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserProfileTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthdate => $composableBuilder(
    column: $table.birthdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themePreference => $composableBuilder(
    column: $table.themePreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appLockMode => $composableBuilder(
    column: $table.appLockMode,
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
}

class $$UserProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthdate => $composableBuilder(
    column: $table.birthdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themePreference => $composableBuilder(
    column: $table.themePreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appLockMode => $composableBuilder(
    column: $table.appLockMode,
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

class $$UserProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get birthdate =>
      $composableBuilder(column: $table.birthdate, builder: (column) => column);

  GeneratedColumn<String> get themePreference => $composableBuilder(
    column: $table.themePreference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appLockMode => $composableBuilder(
    column: $table.appLockMode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfileTable,
          UserProfileRow,
          $$UserProfileTableFilterComposer,
          $$UserProfileTableOrderingComposer,
          $$UserProfileTableAnnotationComposer,
          $$UserProfileTableCreateCompanionBuilder,
          $$UserProfileTableUpdateCompanionBuilder,
          (
            UserProfileRow,
            BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileRow>,
          ),
          UserProfileRow,
          PrefetchHooks Function()
        > {
  $$UserProfileTableTableManager(_$AppDatabase db, $UserProfileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<DateTime?> birthdate = const Value.absent(),
                Value<String?> themePreference = const Value.absent(),
                Value<String?> appLockMode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfileCompanion(
                id: id,
                userId: userId,
                displayName: displayName,
                birthdate: birthdate,
                themePreference: themePreference,
                appLockMode: appLockMode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<DateTime?> birthdate = const Value.absent(),
                Value<String?> themePreference = const Value.absent(),
                Value<String?> appLockMode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfileCompanion.insert(
                id: id,
                userId: userId,
                displayName: displayName,
                birthdate: birthdate,
                themePreference: themePreference,
                appLockMode: appLockMode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserProfileTable, UserProfileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserProfileTable,
                    UserProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfileTable,
      UserProfileRow,
      $$UserProfileTableFilterComposer,
      $$UserProfileTableOrderingComposer,
      $$UserProfileTableAnnotationComposer,
      $$UserProfileTableCreateCompanionBuilder,
      $$UserProfileTableUpdateCompanionBuilder,
      (
        UserProfileRow,
        BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileRow>,
      ),
      UserProfileRow,
      PrefetchHooks Function()
    >;
typedef $$RemoteStatusCacheTableCreateCompanionBuilder =
    RemoteStatusCacheCompanion Function({
      required String id,
      Value<DateTime?> lastCheckedAt,
      Value<bool> maintenanceMode,
      Value<String?> maintenanceMessage,
      Value<bool> killSwitch,
      Value<bool> lastKnownGood,
      Value<int> rowid,
    });
typedef $$RemoteStatusCacheTableUpdateCompanionBuilder =
    RemoteStatusCacheCompanion Function({
      Value<String> id,
      Value<DateTime?> lastCheckedAt,
      Value<bool> maintenanceMode,
      Value<String?> maintenanceMessage,
      Value<bool> killSwitch,
      Value<bool> lastKnownGood,
      Value<int> rowid,
    });

class $$RemoteStatusCacheTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteStatusCacheTable> {
  $$RemoteStatusCacheTableFilterComposer({
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

  ColumnFilters<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get maintenanceMode => $composableBuilder(
    column: $table.maintenanceMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maintenanceMessage => $composableBuilder(
    column: $table.maintenanceMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get killSwitch => $composableBuilder(
    column: $table.killSwitch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lastKnownGood => $composableBuilder(
    column: $table.lastKnownGood,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemoteStatusCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteStatusCacheTable> {
  $$RemoteStatusCacheTableOrderingComposer({
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

  ColumnOrderings<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get maintenanceMode => $composableBuilder(
    column: $table.maintenanceMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maintenanceMessage => $composableBuilder(
    column: $table.maintenanceMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get killSwitch => $composableBuilder(
    column: $table.killSwitch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lastKnownGood => $composableBuilder(
    column: $table.lastKnownGood,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemoteStatusCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteStatusCacheTable> {
  $$RemoteStatusCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get maintenanceMode => $composableBuilder(
    column: $table.maintenanceMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get maintenanceMessage => $composableBuilder(
    column: $table.maintenanceMessage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get killSwitch => $composableBuilder(
    column: $table.killSwitch,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lastKnownGood => $composableBuilder(
    column: $table.lastKnownGood,
    builder: (column) => column,
  );
}

class $$RemoteStatusCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemoteStatusCacheTable,
          RemoteStatusCacheRow,
          $$RemoteStatusCacheTableFilterComposer,
          $$RemoteStatusCacheTableOrderingComposer,
          $$RemoteStatusCacheTableAnnotationComposer,
          $$RemoteStatusCacheTableCreateCompanionBuilder,
          $$RemoteStatusCacheTableUpdateCompanionBuilder,
          (
            RemoteStatusCacheRow,
            BaseReferences<
              _$AppDatabase,
              $RemoteStatusCacheTable,
              RemoteStatusCacheRow
            >,
          ),
          RemoteStatusCacheRow,
          PrefetchHooks Function()
        > {
  $$RemoteStatusCacheTableTableManager(
    _$AppDatabase db,
    $RemoteStatusCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteStatusCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteStatusCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemoteStatusCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime?> lastCheckedAt = const Value.absent(),
                Value<bool> maintenanceMode = const Value.absent(),
                Value<String?> maintenanceMessage = const Value.absent(),
                Value<bool> killSwitch = const Value.absent(),
                Value<bool> lastKnownGood = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteStatusCacheCompanion(
                id: id,
                lastCheckedAt: lastCheckedAt,
                maintenanceMode: maintenanceMode,
                maintenanceMessage: maintenanceMessage,
                killSwitch: killSwitch,
                lastKnownGood: lastKnownGood,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime?> lastCheckedAt = const Value.absent(),
                Value<bool> maintenanceMode = const Value.absent(),
                Value<String?> maintenanceMessage = const Value.absent(),
                Value<bool> killSwitch = const Value.absent(),
                Value<bool> lastKnownGood = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteStatusCacheCompanion.insert(
                id: id,
                lastCheckedAt: lastCheckedAt,
                maintenanceMode: maintenanceMode,
                maintenanceMessage: maintenanceMessage,
                killSwitch: killSwitch,
                lastKnownGood: lastKnownGood,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemoteStatusCacheTable, RemoteStatusCacheRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $RemoteStatusCacheTable,
                    RemoteStatusCacheRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemoteStatusCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemoteStatusCacheTable,
      RemoteStatusCacheRow,
      $$RemoteStatusCacheTableFilterComposer,
      $$RemoteStatusCacheTableOrderingComposer,
      $$RemoteStatusCacheTableAnnotationComposer,
      $$RemoteStatusCacheTableCreateCompanionBuilder,
      $$RemoteStatusCacheTableUpdateCompanionBuilder,
      (
        RemoteStatusCacheRow,
        BaseReferences<
          _$AppDatabase,
          $RemoteStatusCacheTable,
          RemoteStatusCacheRow
        >,
      ),
      RemoteStatusCacheRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$RemoteStatusCacheTableTableManager get remoteStatusCache =>
      $$RemoteStatusCacheTableTableManager(_db, _db.remoteStatusCache);
}
