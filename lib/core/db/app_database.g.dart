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

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startingBalanceCentsMeta =
      const VerificationMeta('startingBalanceCents');
  @override
  late final GeneratedColumn<int> startingBalanceCents = GeneratedColumn<int>(
    'starting_balance_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    name,
    type,
    currency,
    startingBalanceCents,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
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
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('starting_balance_cents')) {
      context.handle(
        _startingBalanceCentsMeta,
        startingBalanceCents.isAcceptableOrUnknown(
          data['starting_balance_cents']!,
          _startingBalanceCentsMeta,
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
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      startingBalanceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}starting_balance_cents'],
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
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final String userId;
  final String name;

  /// AccountType.name — cash/bank/card/other. Fixed enum, not free
  /// text (task response flag, confirmed by owner).
  final String type;
  final String currency;

  /// Integer minor units (cents), NEVER a float — money is never
  /// stored as double/Real in this project, to avoid rounding drift
  /// once Task 2.2 sums many transactions into a live balance. Named
  /// explicitly `...Cents`, not `startingBalance`, so nothing
  /// downstream can accidentally treat this as a decimal-dollar value.
  /// This is now the standing convention for every money field project-
  /// wide (Transactions.amount, Budgets.limit_amount,
  /// Investments.cost_basis/current_value in later tasks) — see
  /// DECISIONS.md.
  final int startingBalanceCents;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AccountRow({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.currency,
    required this.startingBalanceCents,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['currency'] = Variable<String>(currency);
    map['starting_balance_cents'] = Variable<int>(startingBalanceCents);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(type),
      currency: Value(currency),
      startingBalanceCents: Value(startingBalanceCents),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      currency: serializer.fromJson<String>(json['currency']),
      startingBalanceCents: serializer.fromJson<int>(
        json['startingBalanceCents'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'currency': serializer.toJson<String>(currency),
      'startingBalanceCents': serializer.toJson<int>(startingBalanceCents),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AccountRow copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? currency,
    int? startingBalanceCents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AccountRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    type: type ?? this.type,
    currency: currency ?? this.currency,
    startingBalanceCents: startingBalanceCents ?? this.startingBalanceCents,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      currency: data.currency.present ? data.currency.value : this.currency,
      startingBalanceCents: data.startingBalanceCents.present
          ? data.startingBalanceCents.value
          : this.startingBalanceCents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currency: $currency, ')
          ..write('startingBalanceCents: $startingBalanceCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    type,
    currency,
    startingBalanceCents,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.type == this.type &&
          other.currency == this.currency &&
          other.startingBalanceCents == this.startingBalanceCents &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> type;
  final Value<String> currency;
  final Value<int> startingBalanceCents;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.currency = const Value.absent(),
    this.startingBalanceCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String type,
    required String currency,
    this.startingBalanceCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       type = Value(type),
       currency = Value(currency);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? currency,
    Expression<int>? startingBalanceCents,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (currency != null) 'currency': currency,
      if (startingBalanceCents != null)
        'starting_balance_cents': startingBalanceCents,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? type,
    Value<String>? currency,
    Value<int>? startingBalanceCents,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      startingBalanceCents: startingBalanceCents ?? this.startingBalanceCents,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (startingBalanceCents.present) {
      map['starting_balance_cents'] = Variable<int>(startingBalanceCents.value);
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
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currency: $currency, ')
          ..write('startingBalanceCents: $startingBalanceCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    name,
    icon,
    color,
    kind,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
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
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
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
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
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
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String userId;
  final String name;

  /// Key into domain/category_style.dart's CategoryIcons.options map.
  final String icon;

  /// Light-mode hex, e.g. '#966E40'. See class doc above.
  final String color;

  /// CategoryKind.name — income/expense.
  final String kind;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CategoryRow({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<String>(color);
    map['kind'] = Variable<String>(kind);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      icon: Value(icon),
      color: Value(color),
      kind: Value(kind),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<String>(json['color']),
      kind: serializer.fromJson<String>(json['kind']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<String>(color),
      'kind': serializer.toJson<String>(kind),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    String? kind,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CategoryRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    kind: kind ?? this.kind,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      kind: data.kind.present ? data.kind.value : this.kind,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, name, icon, color, kind, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> icon;
  final Value<String> color;
  final Value<String> kind;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String icon,
    required String color,
    required String kind,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       icon = Value(icon),
       color = Value(color),
       kind = Value(kind);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<String>? kind,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? icon,
    Value<String>? color,
    Value<String>? kind,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      kind: kind ?? this.kind,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
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
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    accountId,
    categoryId,
    amountCents,
    type,
    note,
    occurredAt,
    isRecurring,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
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
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
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
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
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
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final String userId;

  /// References accounts.id / categories.id by convention only — no
  /// Drift-level FK constraint (see DECISIONS.md: app-layer deletion
  /// blocking in accounts_dao.dart/categories_dao.dart is the
  /// integrity mechanism for now; revisit if PowerSync sync is wired
  /// up for Finance, since a server-side merge could write around the
  /// DAO layer).
  final String accountId;
  final String categoryId;

  /// Integer minor units (cents), ALWAYS stored positive. Sign is
  /// applied only at balance-computation time based on `type`, never
  /// stored negative. Same convention as
  /// accounts.startingBalanceCents.
  final int amountCents;

  /// CategoryKind.name ('income'/'expense') — auto-derived from the
  /// selected category's kind at creation/edit time (locked decision,
  /// Task 2.2). Stamped historically: editing the source category's
  /// kind later does NOT recalculate existing transactions.
  final String type;
  final String note;
  final DateTime occurredAt;

  /// Plain boolean toggle only — no recurrence rule, no
  /// auto-generation, no scheduling. Separate future TODO.md item.
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransactionRow({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.amountCents,
    required this.type,
    required this.note,
    required this.occurredAt,
    required this.isRecurring,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['account_id'] = Variable<String>(accountId);
    map['category_id'] = Variable<String>(categoryId);
    map['amount_cents'] = Variable<int>(amountCents);
    map['type'] = Variable<String>(type);
    map['note'] = Variable<String>(note);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['is_recurring'] = Variable<bool>(isRecurring);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      userId: Value(userId),
      accountId: Value(accountId),
      categoryId: Value(categoryId),
      amountCents: Value(amountCents),
      type: Value(type),
      note: Value(note),
      occurredAt: Value(occurredAt),
      isRecurring: Value(isRecurring),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      type: serializer.fromJson<String>(json['type']),
      note: serializer.fromJson<String>(json['note']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'accountId': serializer.toJson<String>(accountId),
      'categoryId': serializer.toJson<String>(categoryId),
      'amountCents': serializer.toJson<int>(amountCents),
      'type': serializer.toJson<String>(type),
      'note': serializer.toJson<String>(note),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransactionRow copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? categoryId,
    int? amountCents,
    String? type,
    String? note,
    DateTime? occurredAt,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransactionRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    amountCents: amountCents ?? this.amountCents,
    type: type ?? this.type,
    note: note ?? this.note,
    occurredAt: occurredAt ?? this.occurredAt,
    isRecurring: isRecurring ?? this.isRecurring,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      type: data.type.present ? data.type.value : this.type,
      note: data.note.present ? data.note.value : this.note,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountCents: $amountCents, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    accountId,
    categoryId,
    amountCents,
    type,
    note,
    occurredAt,
    isRecurring,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId &&
          other.amountCents == this.amountCents &&
          other.type == this.type &&
          other.note == this.note &&
          other.occurredAt == this.occurredAt &&
          other.isRecurring == this.isRecurring &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> accountId;
  final Value<String> categoryId;
  final Value<int> amountCents;
  final Value<String> type;
  final Value<String> note;
  final Value<DateTime> occurredAt;
  final Value<bool> isRecurring;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.type = const Value.absent(),
    this.note = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String userId,
    required String accountId,
    required String categoryId,
    required int amountCents,
    required String type,
    this.note = const Value.absent(),
    required DateTime occurredAt,
    this.isRecurring = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       accountId = Value(accountId),
       categoryId = Value(categoryId),
       amountCents = Value(amountCents),
       type = Value(type),
       occurredAt = Value(occurredAt);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? accountId,
    Expression<String>? categoryId,
    Expression<int>? amountCents,
    Expression<String>? type,
    Expression<String>? note,
    Expression<DateTime>? occurredAt,
    Expression<bool>? isRecurring,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      if (amountCents != null) 'amount_cents': amountCents,
      if (type != null) 'type': type,
      if (note != null) 'note': note,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? accountId,
    Value<String>? categoryId,
    Value<int>? amountCents,
    Value<String>? type,
    Value<String>? note,
    Value<DateTime>? occurredAt,
    Value<bool>? isRecurring,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amountCents: amountCents ?? this.amountCents,
      type: type ?? this.type,
      note: note ?? this.note,
      occurredAt: occurredAt ?? this.occurredAt,
      isRecurring: isRecurring ?? this.isRecurring,
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
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
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
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountCents: $amountCents, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, BudgetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitAmountCentsMeta = const VerificationMeta(
    'limitAmountCents',
  );
  @override
  late final GeneratedColumn<int> limitAmountCents = GeneratedColumn<int>(
    'limit_amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    categoryId,
    month,
    limitAmountCents,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetRow> instance, {
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
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('limit_amount_cents')) {
      context.handle(
        _limitAmountCentsMeta,
        limitAmountCents.isAcceptableOrUnknown(
          data['limit_amount_cents']!,
          _limitAmountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limitAmountCentsMeta);
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
  BudgetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      limitAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_amount_cents'],
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
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class BudgetRow extends DataClass implements Insertable<BudgetRow> {
  final String id;
  final String userId;

  /// References categories.id by convention only — no DB-level FK,
  /// same as accounts_id/category_id on Transactions (Task 2.2
  /// decision, extended here). Always an expense-kind category at
  /// creation (locked decision 2), enforced only by the category
  /// picker in budget_form_sheet.dart, not at the DB level.
  final String categoryId;

  /// 'YYYY-MM' TEXT, e.g. '2026-09' — not a DateTime column, per
  /// DATABASE.md locked decision 3. See domain/month_key.dart for the
  /// parse/format helpers.
  final String month;

  /// Integer minor units (cents), same convention as every other
  /// money field in this project.
  final int limitAmountCents;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BudgetRow({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.month,
    required this.limitAmountCents,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['category_id'] = Variable<String>(categoryId);
    map['month'] = Variable<String>(month);
    map['limit_amount_cents'] = Variable<int>(limitAmountCents);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      userId: Value(userId),
      categoryId: Value(categoryId),
      month: Value(month),
      limitAmountCents: Value(limitAmountCents),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BudgetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      month: serializer.fromJson<String>(json['month']),
      limitAmountCents: serializer.fromJson<int>(json['limitAmountCents']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'categoryId': serializer.toJson<String>(categoryId),
      'month': serializer.toJson<String>(month),
      'limitAmountCents': serializer.toJson<int>(limitAmountCents),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BudgetRow copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? month,
    int? limitAmountCents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BudgetRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    categoryId: categoryId ?? this.categoryId,
    month: month ?? this.month,
    limitAmountCents: limitAmountCents ?? this.limitAmountCents,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BudgetRow copyWithCompanion(BudgetsCompanion data) {
    return BudgetRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      month: data.month.present ? data.month.value : this.month,
      limitAmountCents: data.limitAmountCents.present
          ? data.limitAmountCents.value
          : this.limitAmountCents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('month: $month, ')
          ..write('limitAmountCents: $limitAmountCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    categoryId,
    month,
    limitAmountCents,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.categoryId == this.categoryId &&
          other.month == this.month &&
          other.limitAmountCents == this.limitAmountCents &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BudgetsCompanion extends UpdateCompanion<BudgetRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> categoryId;
  final Value<String> month;
  final Value<int> limitAmountCents;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.month = const Value.absent(),
    this.limitAmountCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String userId,
    required String categoryId,
    required String month,
    required int limitAmountCents,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       categoryId = Value(categoryId),
       month = Value(month),
       limitAmountCents = Value(limitAmountCents);
  static Insertable<BudgetRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? categoryId,
    Expression<String>? month,
    Expression<int>? limitAmountCents,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      if (month != null) 'month': month,
      if (limitAmountCents != null) 'limit_amount_cents': limitAmountCents,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? categoryId,
    Value<String>? month,
    Value<int>? limitAmountCents,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      limitAmountCents: limitAmountCents ?? this.limitAmountCents,
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
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (limitAmountCents.present) {
      map['limit_amount_cents'] = Variable<int>(limitAmountCents.value);
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
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('month: $month, ')
          ..write('limitAmountCents: $limitAmountCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvestmentsTable extends Investments
    with TableInfo<$InvestmentsTable, InvestmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestmentsTable(this.attachedDatabase, [this._alias]);
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costBasisCentsMeta = const VerificationMeta(
    'costBasisCents',
  );
  @override
  late final GeneratedColumn<int> costBasisCents = GeneratedColumn<int>(
    'cost_basis_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentValueCentsMeta = const VerificationMeta(
    'currentValueCents',
  );
  @override
  late final GeneratedColumn<int> currentValueCents = GeneratedColumn<int>(
    'current_value_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdatedAt =
      GeneratedColumn<DateTime>(
        'last_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
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
    name,
    type,
    quantity,
    costBasisCents,
    currentValueCents,
    lastUpdatedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investments';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvestmentRow> instance, {
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
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('cost_basis_cents')) {
      context.handle(
        _costBasisCentsMeta,
        costBasisCents.isAcceptableOrUnknown(
          data['cost_basis_cents']!,
          _costBasisCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costBasisCentsMeta);
    }
    if (data.containsKey('current_value_cents')) {
      context.handle(
        _currentValueCentsMeta,
        currentValueCents.isAcceptableOrUnknown(
          data['current_value_cents']!,
          _currentValueCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentValueCentsMeta);
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
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
  InvestmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvestmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      costBasisCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_basis_cents'],
      )!,
      currentValueCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_value_cents'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated_at'],
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
  $InvestmentsTable createAlias(String alias) {
    return $InvestmentsTable(attachedDatabase, alias);
  }
}

class InvestmentRow extends DataClass implements Insertable<InvestmentRow> {
  final String id;
  final String userId;
  final String name;

  /// InvestmentType.name — stock/crypto/realEstate/other (camelCase
  /// enum member names, same convention as AccountType/CategoryKind;
  /// not literally DATABASE.md's snake_case 'real_estate').
  final String type;

  /// Plain informational number (e.g. "10 shares", "0.5 BTC") — NEVER
  /// multiplied into cost_basis/current_value (locked decision 3).
  /// REAL, not cents — not a money field, exempt from the
  /// integer-cents rule for that reason.
  final double quantity;

  /// TOTAL cost basis, integer cents — not per-unit.
  final int costBasisCents;

  /// TOTAL current value, integer cents — not per-unit. Initialized
  /// equal to costBasisCents at creation (investments_dao.dart);
  /// changed only via updateCurrentValue (update_value_dialog.dart),
  /// never through the full edit form.
  final int currentValueCents;

  /// Auto-set to DateTime.now() only when currentValueCents changes —
  /// never directly user-editable (locked decision 4).
  final DateTime lastUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const InvestmentRow({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.quantity,
    required this.costBasisCents,
    required this.currentValueCents,
    required this.lastUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['quantity'] = Variable<double>(quantity);
    map['cost_basis_cents'] = Variable<int>(costBasisCents);
    map['current_value_cents'] = Variable<int>(currentValueCents);
    map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InvestmentsCompanion toCompanion(bool nullToAbsent) {
    return InvestmentsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(type),
      quantity: Value(quantity),
      costBasisCents: Value(costBasisCents),
      currentValueCents: Value(currentValueCents),
      lastUpdatedAt: Value(lastUpdatedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InvestmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvestmentRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      quantity: serializer.fromJson<double>(json['quantity']),
      costBasisCents: serializer.fromJson<int>(json['costBasisCents']),
      currentValueCents: serializer.fromJson<int>(json['currentValueCents']),
      lastUpdatedAt: serializer.fromJson<DateTime>(json['lastUpdatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'quantity': serializer.toJson<double>(quantity),
      'costBasisCents': serializer.toJson<int>(costBasisCents),
      'currentValueCents': serializer.toJson<int>(currentValueCents),
      'lastUpdatedAt': serializer.toJson<DateTime>(lastUpdatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InvestmentRow copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    double? quantity,
    int? costBasisCents,
    int? currentValueCents,
    DateTime? lastUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InvestmentRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    type: type ?? this.type,
    quantity: quantity ?? this.quantity,
    costBasisCents: costBasisCents ?? this.costBasisCents,
    currentValueCents: currentValueCents ?? this.currentValueCents,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InvestmentRow copyWithCompanion(InvestmentsCompanion data) {
    return InvestmentRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      costBasisCents: data.costBasisCents.present
          ? data.costBasisCents.value
          : this.costBasisCents,
      currentValueCents: data.currentValueCents.present
          ? data.currentValueCents.value
          : this.currentValueCents,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('quantity: $quantity, ')
          ..write('costBasisCents: $costBasisCents, ')
          ..write('currentValueCents: $currentValueCents, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    type,
    quantity,
    costBasisCents,
    currentValueCents,
    lastUpdatedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvestmentRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.type == this.type &&
          other.quantity == this.quantity &&
          other.costBasisCents == this.costBasisCents &&
          other.currentValueCents == this.currentValueCents &&
          other.lastUpdatedAt == this.lastUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InvestmentsCompanion extends UpdateCompanion<InvestmentRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> type;
  final Value<double> quantity;
  final Value<int> costBasisCents;
  final Value<int> currentValueCents;
  final Value<DateTime> lastUpdatedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InvestmentsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.quantity = const Value.absent(),
    this.costBasisCents = const Value.absent(),
    this.currentValueCents = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvestmentsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String type,
    required double quantity,
    required int costBasisCents,
    required int currentValueCents,
    required DateTime lastUpdatedAt,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       type = Value(type),
       quantity = Value(quantity),
       costBasisCents = Value(costBasisCents),
       currentValueCents = Value(currentValueCents),
       lastUpdatedAt = Value(lastUpdatedAt);
  static Insertable<InvestmentRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<double>? quantity,
    Expression<int>? costBasisCents,
    Expression<int>? currentValueCents,
    Expression<DateTime>? lastUpdatedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (quantity != null) 'quantity': quantity,
      if (costBasisCents != null) 'cost_basis_cents': costBasisCents,
      if (currentValueCents != null) 'current_value_cents': currentValueCents,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvestmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? type,
    Value<double>? quantity,
    Value<int>? costBasisCents,
    Value<int>? currentValueCents,
    Value<DateTime>? lastUpdatedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InvestmentsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      costBasisCents: costBasisCents ?? this.costBasisCents,
      currentValueCents: currentValueCents ?? this.currentValueCents,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (costBasisCents.present) {
      map['cost_basis_cents'] = Variable<int>(costBasisCents.value);
    }
    if (currentValueCents.present) {
      map['current_value_cents'] = Variable<int>(currentValueCents.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt.value);
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
    return (StringBuffer('InvestmentsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('quantity: $quantity, ')
          ..write('costBasisCents: $costBasisCents, ')
          ..write('currentValueCents: $currentValueCents, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvestmentSalesTable extends InvestmentSales
    with TableInfo<$InvestmentSalesTable, InvestmentSaleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestmentSalesTable(this.attachedDatabase, [this._alias]);
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _investmentIdMeta = const VerificationMeta(
    'investmentId',
  );
  @override
  late final GeneratedColumn<String> investmentId = GeneratedColumn<String>(
    'investment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantitySoldMeta = const VerificationMeta(
    'quantitySold',
  );
  @override
  late final GeneratedColumn<double> quantitySold = GeneratedColumn<double>(
    'quantity_sold',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proceedsCentsMeta = const VerificationMeta(
    'proceedsCents',
  );
  @override
  late final GeneratedColumn<int> proceedsCents = GeneratedColumn<int>(
    'proceeds_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _realizedGainCentsMeta = const VerificationMeta(
    'realizedGainCents',
  );
  @override
  late final GeneratedColumn<int> realizedGainCents = GeneratedColumn<int>(
    'realized_gain_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _soldAtMeta = const VerificationMeta('soldAt');
  @override
  late final GeneratedColumn<DateTime> soldAt = GeneratedColumn<DateTime>(
    'sold_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    investmentId,
    quantitySold,
    proceedsCents,
    realizedGainCents,
    soldAt,
    transactionId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investment_sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvestmentSaleRow> instance, {
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
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('investment_id')) {
      context.handle(
        _investmentIdMeta,
        investmentId.isAcceptableOrUnknown(
          data['investment_id']!,
          _investmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_investmentIdMeta);
    }
    if (data.containsKey('quantity_sold')) {
      context.handle(
        _quantitySoldMeta,
        quantitySold.isAcceptableOrUnknown(
          data['quantity_sold']!,
          _quantitySoldMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantitySoldMeta);
    }
    if (data.containsKey('proceeds_cents')) {
      context.handle(
        _proceedsCentsMeta,
        proceedsCents.isAcceptableOrUnknown(
          data['proceeds_cents']!,
          _proceedsCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proceedsCentsMeta);
    }
    if (data.containsKey('realized_gain_cents')) {
      context.handle(
        _realizedGainCentsMeta,
        realizedGainCents.isAcceptableOrUnknown(
          data['realized_gain_cents']!,
          _realizedGainCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_realizedGainCentsMeta);
    }
    if (data.containsKey('sold_at')) {
      context.handle(
        _soldAtMeta,
        soldAt.isAcceptableOrUnknown(data['sold_at']!, _soldAtMeta),
      );
    } else if (isInserting) {
      context.missing(_soldAtMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
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
  InvestmentSaleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvestmentSaleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      investmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}investment_id'],
      )!,
      quantitySold: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_sold'],
      )!,
      proceedsCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}proceeds_cents'],
      )!,
      realizedGainCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}realized_gain_cents'],
      )!,
      soldAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sold_at'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $InvestmentSalesTable createAlias(String alias) {
    return $InvestmentSalesTable(attachedDatabase, alias);
  }
}

class InvestmentSaleRow extends DataClass
    implements Insertable<InvestmentSaleRow> {
  final String id;
  final String userId;
  final String investmentId;

  /// REAL, not cents — same "not a money field, exempt from the
  /// cents rule" reasoning as Investments.quantity.
  final double quantitySold;
  final int proceedsCents;

  /// proceeds_cents - proportional cost basis removed at the moment
  /// of sale. A historical snapshot: if the linked transaction's
  /// amount is edited afterward, this does NOT retroactively update
  /// (see DECISIONS.md note in task response).
  final int realizedGainCents;
  final DateTime soldAt;

  /// References transactions.id — the income Transaction created for
  /// this sale's proceeds. No DB-level FK (project convention), but
  /// deletion-blocked in BOTH directions this task: deleteInvestment
  /// blocks if sales exist, and deleteTransaction now blocks if a
  /// sale still references it.
  final String transactionId;
  final DateTime createdAt;
  const InvestmentSaleRow({
    required this.id,
    required this.userId,
    required this.investmentId,
    required this.quantitySold,
    required this.proceedsCents,
    required this.realizedGainCents,
    required this.soldAt,
    required this.transactionId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['investment_id'] = Variable<String>(investmentId);
    map['quantity_sold'] = Variable<double>(quantitySold);
    map['proceeds_cents'] = Variable<int>(proceedsCents);
    map['realized_gain_cents'] = Variable<int>(realizedGainCents);
    map['sold_at'] = Variable<DateTime>(soldAt);
    map['transaction_id'] = Variable<String>(transactionId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InvestmentSalesCompanion toCompanion(bool nullToAbsent) {
    return InvestmentSalesCompanion(
      id: Value(id),
      userId: Value(userId),
      investmentId: Value(investmentId),
      quantitySold: Value(quantitySold),
      proceedsCents: Value(proceedsCents),
      realizedGainCents: Value(realizedGainCents),
      soldAt: Value(soldAt),
      transactionId: Value(transactionId),
      createdAt: Value(createdAt),
    );
  }

  factory InvestmentSaleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvestmentSaleRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      investmentId: serializer.fromJson<String>(json['investmentId']),
      quantitySold: serializer.fromJson<double>(json['quantitySold']),
      proceedsCents: serializer.fromJson<int>(json['proceedsCents']),
      realizedGainCents: serializer.fromJson<int>(json['realizedGainCents']),
      soldAt: serializer.fromJson<DateTime>(json['soldAt']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'investmentId': serializer.toJson<String>(investmentId),
      'quantitySold': serializer.toJson<double>(quantitySold),
      'proceedsCents': serializer.toJson<int>(proceedsCents),
      'realizedGainCents': serializer.toJson<int>(realizedGainCents),
      'soldAt': serializer.toJson<DateTime>(soldAt),
      'transactionId': serializer.toJson<String>(transactionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InvestmentSaleRow copyWith({
    String? id,
    String? userId,
    String? investmentId,
    double? quantitySold,
    int? proceedsCents,
    int? realizedGainCents,
    DateTime? soldAt,
    String? transactionId,
    DateTime? createdAt,
  }) => InvestmentSaleRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    investmentId: investmentId ?? this.investmentId,
    quantitySold: quantitySold ?? this.quantitySold,
    proceedsCents: proceedsCents ?? this.proceedsCents,
    realizedGainCents: realizedGainCents ?? this.realizedGainCents,
    soldAt: soldAt ?? this.soldAt,
    transactionId: transactionId ?? this.transactionId,
    createdAt: createdAt ?? this.createdAt,
  );
  InvestmentSaleRow copyWithCompanion(InvestmentSalesCompanion data) {
    return InvestmentSaleRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      investmentId: data.investmentId.present
          ? data.investmentId.value
          : this.investmentId,
      quantitySold: data.quantitySold.present
          ? data.quantitySold.value
          : this.quantitySold,
      proceedsCents: data.proceedsCents.present
          ? data.proceedsCents.value
          : this.proceedsCents,
      realizedGainCents: data.realizedGainCents.present
          ? data.realizedGainCents.value
          : this.realizedGainCents,
      soldAt: data.soldAt.present ? data.soldAt.value : this.soldAt,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentSaleRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('investmentId: $investmentId, ')
          ..write('quantitySold: $quantitySold, ')
          ..write('proceedsCents: $proceedsCents, ')
          ..write('realizedGainCents: $realizedGainCents, ')
          ..write('soldAt: $soldAt, ')
          ..write('transactionId: $transactionId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    investmentId,
    quantitySold,
    proceedsCents,
    realizedGainCents,
    soldAt,
    transactionId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvestmentSaleRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.investmentId == this.investmentId &&
          other.quantitySold == this.quantitySold &&
          other.proceedsCents == this.proceedsCents &&
          other.realizedGainCents == this.realizedGainCents &&
          other.soldAt == this.soldAt &&
          other.transactionId == this.transactionId &&
          other.createdAt == this.createdAt);
}

class InvestmentSalesCompanion extends UpdateCompanion<InvestmentSaleRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> investmentId;
  final Value<double> quantitySold;
  final Value<int> proceedsCents;
  final Value<int> realizedGainCents;
  final Value<DateTime> soldAt;
  final Value<String> transactionId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const InvestmentSalesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.investmentId = const Value.absent(),
    this.quantitySold = const Value.absent(),
    this.proceedsCents = const Value.absent(),
    this.realizedGainCents = const Value.absent(),
    this.soldAt = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvestmentSalesCompanion.insert({
    required String id,
    required String userId,
    required String investmentId,
    required double quantitySold,
    required int proceedsCents,
    required int realizedGainCents,
    required DateTime soldAt,
    required String transactionId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       investmentId = Value(investmentId),
       quantitySold = Value(quantitySold),
       proceedsCents = Value(proceedsCents),
       realizedGainCents = Value(realizedGainCents),
       soldAt = Value(soldAt),
       transactionId = Value(transactionId);
  static Insertable<InvestmentSaleRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? investmentId,
    Expression<double>? quantitySold,
    Expression<int>? proceedsCents,
    Expression<int>? realizedGainCents,
    Expression<DateTime>? soldAt,
    Expression<String>? transactionId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (investmentId != null) 'investment_id': investmentId,
      if (quantitySold != null) 'quantity_sold': quantitySold,
      if (proceedsCents != null) 'proceeds_cents': proceedsCents,
      if (realizedGainCents != null) 'realized_gain_cents': realizedGainCents,
      if (soldAt != null) 'sold_at': soldAt,
      if (transactionId != null) 'transaction_id': transactionId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvestmentSalesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? investmentId,
    Value<double>? quantitySold,
    Value<int>? proceedsCents,
    Value<int>? realizedGainCents,
    Value<DateTime>? soldAt,
    Value<String>? transactionId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return InvestmentSalesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      investmentId: investmentId ?? this.investmentId,
      quantitySold: quantitySold ?? this.quantitySold,
      proceedsCents: proceedsCents ?? this.proceedsCents,
      realizedGainCents: realizedGainCents ?? this.realizedGainCents,
      soldAt: soldAt ?? this.soldAt,
      transactionId: transactionId ?? this.transactionId,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (investmentId.present) {
      map['investment_id'] = Variable<String>(investmentId.value);
    }
    if (quantitySold.present) {
      map['quantity_sold'] = Variable<double>(quantitySold.value);
    }
    if (proceedsCents.present) {
      map['proceeds_cents'] = Variable<int>(proceedsCents.value);
    }
    if (realizedGainCents.present) {
      map['realized_gain_cents'] = Variable<int>(realizedGainCents.value);
    }
    if (soldAt.present) {
      map['sold_at'] = Variable<DateTime>(soldAt.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
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
    return (StringBuffer('InvestmentSalesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('investmentId: $investmentId, ')
          ..write('quantitySold: $quantitySold, ')
          ..write('proceedsCents: $proceedsCents, ')
          ..write('realizedGainCents: $realizedGainCents, ')
          ..write('soldAt: $soldAt, ')
          ..write('transactionId: $transactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvestmentValueSnapshotsTable extends InvestmentValueSnapshots
    with TableInfo<$InvestmentValueSnapshotsTable, InvestmentValueSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestmentValueSnapshotsTable(this.attachedDatabase, [this._alias]);
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _investmentIdMeta = const VerificationMeta(
    'investmentId',
  );
  @override
  late final GeneratedColumn<String> investmentId = GeneratedColumn<String>(
    'investment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueCentsMeta = const VerificationMeta(
    'valueCents',
  );
  @override
  late final GeneratedColumn<int> valueCents = GeneratedColumn<int>(
    'value_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    investmentId,
    valueCents,
    recordedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investment_value_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvestmentValueSnapshotRow> instance, {
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
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('investment_id')) {
      context.handle(
        _investmentIdMeta,
        investmentId.isAcceptableOrUnknown(
          data['investment_id']!,
          _investmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_investmentIdMeta);
    }
    if (data.containsKey('value_cents')) {
      context.handle(
        _valueCentsMeta,
        valueCents.isAcceptableOrUnknown(data['value_cents']!, _valueCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_valueCentsMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
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
  InvestmentValueSnapshotRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvestmentValueSnapshotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      investmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}investment_id'],
      )!,
      valueCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value_cents'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
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
  $InvestmentValueSnapshotsTable createAlias(String alias) {
    return $InvestmentValueSnapshotsTable(attachedDatabase, alias);
  }
}

class InvestmentValueSnapshotRow extends DataClass
    implements Insertable<InvestmentValueSnapshotRow> {
  final String id;
  final String userId;

  /// References investments.id — no DB-level FK (project convention).
  /// Deleted together with its investment in one db.transaction
  /// (investments_dao.dart) — snapshots are derived history, not user
  /// records, so they never block a deletion themselves.
  final String investmentId;
  final int valueCents;

  /// ALWAYS DateTime.now() at the moment the value changed — including
  /// the post-sale snapshot in sellInvestment, even when the sale's
  /// own soldAt date is in the past. A sale backdated into a past
  /// month therefore leaves that month's DERIVED net worth (once a
  /// net-worth chart exists) double-counting: both the proceeds
  /// (landed in an account on the backdated date) and the pre-sale
  /// investment value (still "current" as of today, since no snapshot
  /// exists at the backdated date). This cannot be made correct
  /// without guessing at a historical valuation that was never
  /// recorded — snapshots are not backdated to compensate. The
  /// eventual chart screen states this as a known limitation.
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const InvestmentValueSnapshotRow({
    required this.id,
    required this.userId,
    required this.investmentId,
    required this.valueCents,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['investment_id'] = Variable<String>(investmentId);
    map['value_cents'] = Variable<int>(valueCents);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InvestmentValueSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return InvestmentValueSnapshotsCompanion(
      id: Value(id),
      userId: Value(userId),
      investmentId: Value(investmentId),
      valueCents: Value(valueCents),
      recordedAt: Value(recordedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InvestmentValueSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvestmentValueSnapshotRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      investmentId: serializer.fromJson<String>(json['investmentId']),
      valueCents: serializer.fromJson<int>(json['valueCents']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'investmentId': serializer.toJson<String>(investmentId),
      'valueCents': serializer.toJson<int>(valueCents),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InvestmentValueSnapshotRow copyWith({
    String? id,
    String? userId,
    String? investmentId,
    int? valueCents,
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InvestmentValueSnapshotRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    investmentId: investmentId ?? this.investmentId,
    valueCents: valueCents ?? this.valueCents,
    recordedAt: recordedAt ?? this.recordedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InvestmentValueSnapshotRow copyWithCompanion(
    InvestmentValueSnapshotsCompanion data,
  ) {
    return InvestmentValueSnapshotRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      investmentId: data.investmentId.present
          ? data.investmentId.value
          : this.investmentId,
      valueCents: data.valueCents.present
          ? data.valueCents.value
          : this.valueCents,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentValueSnapshotRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('investmentId: $investmentId, ')
          ..write('valueCents: $valueCents, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    investmentId,
    valueCents,
    recordedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvestmentValueSnapshotRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.investmentId == this.investmentId &&
          other.valueCents == this.valueCents &&
          other.recordedAt == this.recordedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InvestmentValueSnapshotsCompanion
    extends UpdateCompanion<InvestmentValueSnapshotRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> investmentId;
  final Value<int> valueCents;
  final Value<DateTime> recordedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InvestmentValueSnapshotsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.investmentId = const Value.absent(),
    this.valueCents = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvestmentValueSnapshotsCompanion.insert({
    required String id,
    required String userId,
    required String investmentId,
    required int valueCents,
    required DateTime recordedAt,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       investmentId = Value(investmentId),
       valueCents = Value(valueCents),
       recordedAt = Value(recordedAt);
  static Insertable<InvestmentValueSnapshotRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? investmentId,
    Expression<int>? valueCents,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (investmentId != null) 'investment_id': investmentId,
      if (valueCents != null) 'value_cents': valueCents,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvestmentValueSnapshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? investmentId,
    Value<int>? valueCents,
    Value<DateTime>? recordedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InvestmentValueSnapshotsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      investmentId: investmentId ?? this.investmentId,
      valueCents: valueCents ?? this.valueCents,
      recordedAt: recordedAt ?? this.recordedAt,
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
    if (investmentId.present) {
      map['investment_id'] = Variable<String>(investmentId.value);
    }
    if (valueCents.present) {
      map['value_cents'] = Variable<int>(valueCents.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
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
    return (StringBuffer('InvestmentValueSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('investmentId: $investmentId, ')
          ..write('valueCents: $valueCents, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
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
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $InvestmentsTable investments = $InvestmentsTable(this);
  late final $InvestmentSalesTable investmentSales = $InvestmentSalesTable(
    this,
  );
  late final $InvestmentValueSnapshotsTable investmentValueSnapshots =
      $InvestmentValueSnapshotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userProfile,
    remoteStatusCache,
    accounts,
    categories,
    transactions,
    budgets,
    investments,
    investmentSales,
    investmentValueSnapshots,
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
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String id,
      required String userId,
      required String name,
      required String type,
      required String currency,
      Value<int> startingBalanceCents,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String> type,
      Value<String> currency,
      Value<int> startingBalanceCents,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startingBalanceCents => $composableBuilder(
    column: $table.startingBalanceCents,
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

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startingBalanceCents => $composableBuilder(
    column: $table.startingBalanceCents,
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

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get startingBalanceCents => $composableBuilder(
    column: $table.startingBalanceCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (
            AccountRow,
            BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>,
          ),
          AccountRow,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> startingBalanceCents = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                userId: userId,
                name: name,
                type: type,
                currency: currency,
                startingBalanceCents: startingBalanceCents,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                required String type,
                required String currency,
                Value<int> startingBalanceCents = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                type: type,
                currency: currency,
                startingBalanceCents: startingBalanceCents,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, AccountRow>(table),
                  BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>),
      AccountRow,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String userId,
      required String name,
      required String icon,
      required String color,
      required String kind,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String> icon,
      Value<String> color,
      Value<String> kind,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
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

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
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

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                userId: userId,
                name: name,
                icon: icon,
                color: color,
                kind: kind,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                required String icon,
                required String color,
                required String kind,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                icon: icon,
                color: color,
                kind: kind,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String userId,
      required String accountId,
      required String categoryId,
      required int amountCents,
      required String type,
      Value<String> note,
      required DateTime occurredAt,
      Value<bool> isRecurring,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> accountId,
      Value<String> categoryId,
      Value<int> amountCents,
      Value<String> type,
      Value<String> note,
      Value<DateTime> occurredAt,
      Value<bool> isRecurring,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
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

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
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

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
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

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionRow,
            BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
          ),
          TransactionRow,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                userId: userId,
                accountId: accountId,
                categoryId: categoryId,
                amountCents: amountCents,
                type: type,
                note: note,
                occurredAt: occurredAt,
                isRecurring: isRecurring,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String accountId,
                required String categoryId,
                required int amountCents,
                required String type,
                Value<String> note = const Value.absent(),
                required DateTime occurredAt,
                Value<bool> isRecurring = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                userId: userId,
                accountId: accountId,
                categoryId: categoryId,
                amountCents: amountCents,
                type: type,
                note: note,
                occurredAt: occurredAt,
                isRecurring: isRecurring,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TransactionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TransactionsTable,
                    TransactionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionRow,
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
      ),
      TransactionRow,
      PrefetchHooks Function()
    >;
typedef $$BudgetsTableCreateCompanionBuilder =
    BudgetsCompanion Function({
      required String id,
      required String userId,
      required String categoryId,
      required String month,
      required int limitAmountCents,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BudgetsTableUpdateCompanionBuilder =
    BudgetsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> categoryId,
      Value<String> month,
      Value<int> limitAmountCents,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
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

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitAmountCents => $composableBuilder(
    column: $table.limitAmountCents,
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

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
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

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitAmountCents => $composableBuilder(
    column: $table.limitAmountCents,
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

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
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

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get limitAmountCents => $composableBuilder(
    column: $table.limitAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          BudgetRow,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (BudgetRow, BaseReferences<_$AppDatabase, $BudgetsTable, BudgetRow>),
          BudgetRow,
          PrefetchHooks Function()
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> month = const Value.absent(),
                Value<int> limitAmountCents = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                userId: userId,
                categoryId: categoryId,
                month: month,
                limitAmountCents: limitAmountCents,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String categoryId,
                required String month,
                required int limitAmountCents,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                userId: userId,
                categoryId: categoryId,
                month: month,
                limitAmountCents: limitAmountCents,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, BudgetRow>(table),
                  BaseReferences<_$AppDatabase, $BudgetsTable, BudgetRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      BudgetRow,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (BudgetRow, BaseReferences<_$AppDatabase, $BudgetsTable, BudgetRow>),
      BudgetRow,
      PrefetchHooks Function()
    >;
typedef $$InvestmentsTableCreateCompanionBuilder =
    InvestmentsCompanion Function({
      required String id,
      required String userId,
      required String name,
      required String type,
      required double quantity,
      required int costBasisCents,
      required int currentValueCents,
      required DateTime lastUpdatedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$InvestmentsTableUpdateCompanionBuilder =
    InvestmentsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String> type,
      Value<double> quantity,
      Value<int> costBasisCents,
      Value<int> currentValueCents,
      Value<DateTime> lastUpdatedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$InvestmentsTableFilterComposer
    extends Composer<_$AppDatabase, $InvestmentsTable> {
  $$InvestmentsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costBasisCents => $composableBuilder(
    column: $table.costBasisCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentValueCents => $composableBuilder(
    column: $table.currentValueCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
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

class $$InvestmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvestmentsTable> {
  $$InvestmentsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costBasisCents => $composableBuilder(
    column: $table.costBasisCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentValueCents => $composableBuilder(
    column: $table.currentValueCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
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

class $$InvestmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvestmentsTable> {
  $$InvestmentsTableAnnotationComposer({
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get costBasisCents => $composableBuilder(
    column: $table.costBasisCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentValueCents => $composableBuilder(
    column: $table.currentValueCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InvestmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvestmentsTable,
          InvestmentRow,
          $$InvestmentsTableFilterComposer,
          $$InvestmentsTableOrderingComposer,
          $$InvestmentsTableAnnotationComposer,
          $$InvestmentsTableCreateCompanionBuilder,
          $$InvestmentsTableUpdateCompanionBuilder,
          (
            InvestmentRow,
            BaseReferences<_$AppDatabase, $InvestmentsTable, InvestmentRow>,
          ),
          InvestmentRow,
          PrefetchHooks Function()
        > {
  $$InvestmentsTableTableManager(_$AppDatabase db, $InvestmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvestmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvestmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvestmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<int> costBasisCents = const Value.absent(),
                Value<int> currentValueCents = const Value.absent(),
                Value<DateTime> lastUpdatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentsCompanion(
                id: id,
                userId: userId,
                name: name,
                type: type,
                quantity: quantity,
                costBasisCents: costBasisCents,
                currentValueCents: currentValueCents,
                lastUpdatedAt: lastUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                required String type,
                required double quantity,
                required int costBasisCents,
                required int currentValueCents,
                required DateTime lastUpdatedAt,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                type: type,
                quantity: quantity,
                costBasisCents: costBasisCents,
                currentValueCents: currentValueCents,
                lastUpdatedAt: lastUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InvestmentsTable, InvestmentRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $InvestmentsTable,
                    InvestmentRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InvestmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvestmentsTable,
      InvestmentRow,
      $$InvestmentsTableFilterComposer,
      $$InvestmentsTableOrderingComposer,
      $$InvestmentsTableAnnotationComposer,
      $$InvestmentsTableCreateCompanionBuilder,
      $$InvestmentsTableUpdateCompanionBuilder,
      (
        InvestmentRow,
        BaseReferences<_$AppDatabase, $InvestmentsTable, InvestmentRow>,
      ),
      InvestmentRow,
      PrefetchHooks Function()
    >;
typedef $$InvestmentSalesTableCreateCompanionBuilder =
    InvestmentSalesCompanion Function({
      required String id,
      required String userId,
      required String investmentId,
      required double quantitySold,
      required int proceedsCents,
      required int realizedGainCents,
      required DateTime soldAt,
      required String transactionId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$InvestmentSalesTableUpdateCompanionBuilder =
    InvestmentSalesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> investmentId,
      Value<double> quantitySold,
      Value<int> proceedsCents,
      Value<int> realizedGainCents,
      Value<DateTime> soldAt,
      Value<String> transactionId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$InvestmentSalesTableFilterComposer
    extends Composer<_$AppDatabase, $InvestmentSalesTable> {
  $$InvestmentSalesTableFilterComposer({
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

  ColumnFilters<String> get investmentId => $composableBuilder(
    column: $table.investmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantitySold => $composableBuilder(
    column: $table.quantitySold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proceedsCents => $composableBuilder(
    column: $table.proceedsCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get realizedGainCents => $composableBuilder(
    column: $table.realizedGainCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get soldAt => $composableBuilder(
    column: $table.soldAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InvestmentSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvestmentSalesTable> {
  $$InvestmentSalesTableOrderingComposer({
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

  ColumnOrderings<String> get investmentId => $composableBuilder(
    column: $table.investmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantitySold => $composableBuilder(
    column: $table.quantitySold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proceedsCents => $composableBuilder(
    column: $table.proceedsCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get realizedGainCents => $composableBuilder(
    column: $table.realizedGainCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get soldAt => $composableBuilder(
    column: $table.soldAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvestmentSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvestmentSalesTable> {
  $$InvestmentSalesTableAnnotationComposer({
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

  GeneratedColumn<String> get investmentId => $composableBuilder(
    column: $table.investmentId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantitySold => $composableBuilder(
    column: $table.quantitySold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get proceedsCents => $composableBuilder(
    column: $table.proceedsCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get realizedGainCents => $composableBuilder(
    column: $table.realizedGainCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get soldAt =>
      $composableBuilder(column: $table.soldAt, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$InvestmentSalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvestmentSalesTable,
          InvestmentSaleRow,
          $$InvestmentSalesTableFilterComposer,
          $$InvestmentSalesTableOrderingComposer,
          $$InvestmentSalesTableAnnotationComposer,
          $$InvestmentSalesTableCreateCompanionBuilder,
          $$InvestmentSalesTableUpdateCompanionBuilder,
          (
            InvestmentSaleRow,
            BaseReferences<
              _$AppDatabase,
              $InvestmentSalesTable,
              InvestmentSaleRow
            >,
          ),
          InvestmentSaleRow,
          PrefetchHooks Function()
        > {
  $$InvestmentSalesTableTableManager(
    _$AppDatabase db,
    $InvestmentSalesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvestmentSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvestmentSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvestmentSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> investmentId = const Value.absent(),
                Value<double> quantitySold = const Value.absent(),
                Value<int> proceedsCents = const Value.absent(),
                Value<int> realizedGainCents = const Value.absent(),
                Value<DateTime> soldAt = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentSalesCompanion(
                id: id,
                userId: userId,
                investmentId: investmentId,
                quantitySold: quantitySold,
                proceedsCents: proceedsCents,
                realizedGainCents: realizedGainCents,
                soldAt: soldAt,
                transactionId: transactionId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String investmentId,
                required double quantitySold,
                required int proceedsCents,
                required int realizedGainCents,
                required DateTime soldAt,
                required String transactionId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentSalesCompanion.insert(
                id: id,
                userId: userId,
                investmentId: investmentId,
                quantitySold: quantitySold,
                proceedsCents: proceedsCents,
                realizedGainCents: realizedGainCents,
                soldAt: soldAt,
                transactionId: transactionId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InvestmentSalesTable, InvestmentSaleRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $InvestmentSalesTable,
                    InvestmentSaleRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InvestmentSalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvestmentSalesTable,
      InvestmentSaleRow,
      $$InvestmentSalesTableFilterComposer,
      $$InvestmentSalesTableOrderingComposer,
      $$InvestmentSalesTableAnnotationComposer,
      $$InvestmentSalesTableCreateCompanionBuilder,
      $$InvestmentSalesTableUpdateCompanionBuilder,
      (
        InvestmentSaleRow,
        BaseReferences<_$AppDatabase, $InvestmentSalesTable, InvestmentSaleRow>,
      ),
      InvestmentSaleRow,
      PrefetchHooks Function()
    >;
typedef $$InvestmentValueSnapshotsTableCreateCompanionBuilder =
    InvestmentValueSnapshotsCompanion Function({
      required String id,
      required String userId,
      required String investmentId,
      required int valueCents,
      required DateTime recordedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$InvestmentValueSnapshotsTableUpdateCompanionBuilder =
    InvestmentValueSnapshotsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> investmentId,
      Value<int> valueCents,
      Value<DateTime> recordedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$InvestmentValueSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $InvestmentValueSnapshotsTable> {
  $$InvestmentValueSnapshotsTableFilterComposer({
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

  ColumnFilters<String> get investmentId => $composableBuilder(
    column: $table.investmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valueCents => $composableBuilder(
    column: $table.valueCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
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

class $$InvestmentValueSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvestmentValueSnapshotsTable> {
  $$InvestmentValueSnapshotsTableOrderingComposer({
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

  ColumnOrderings<String> get investmentId => $composableBuilder(
    column: $table.investmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valueCents => $composableBuilder(
    column: $table.valueCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
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

class $$InvestmentValueSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvestmentValueSnapshotsTable> {
  $$InvestmentValueSnapshotsTableAnnotationComposer({
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

  GeneratedColumn<String> get investmentId => $composableBuilder(
    column: $table.investmentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get valueCents => $composableBuilder(
    column: $table.valueCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InvestmentValueSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvestmentValueSnapshotsTable,
          InvestmentValueSnapshotRow,
          $$InvestmentValueSnapshotsTableFilterComposer,
          $$InvestmentValueSnapshotsTableOrderingComposer,
          $$InvestmentValueSnapshotsTableAnnotationComposer,
          $$InvestmentValueSnapshotsTableCreateCompanionBuilder,
          $$InvestmentValueSnapshotsTableUpdateCompanionBuilder,
          (
            InvestmentValueSnapshotRow,
            BaseReferences<
              _$AppDatabase,
              $InvestmentValueSnapshotsTable,
              InvestmentValueSnapshotRow
            >,
          ),
          InvestmentValueSnapshotRow,
          PrefetchHooks Function()
        > {
  $$InvestmentValueSnapshotsTableTableManager(
    _$AppDatabase db,
    $InvestmentValueSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvestmentValueSnapshotsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InvestmentValueSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InvestmentValueSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> investmentId = const Value.absent(),
                Value<int> valueCents = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentValueSnapshotsCompanion(
                id: id,
                userId: userId,
                investmentId: investmentId,
                valueCents: valueCents,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String investmentId,
                required int valueCents,
                required DateTime recordedAt,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentValueSnapshotsCompanion.insert(
                id: id,
                userId: userId,
                investmentId: investmentId,
                valueCents: valueCents,
                recordedAt: recordedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $InvestmentValueSnapshotsTable,
                    InvestmentValueSnapshotRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $InvestmentValueSnapshotsTable,
                    InvestmentValueSnapshotRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InvestmentValueSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvestmentValueSnapshotsTable,
      InvestmentValueSnapshotRow,
      $$InvestmentValueSnapshotsTableFilterComposer,
      $$InvestmentValueSnapshotsTableOrderingComposer,
      $$InvestmentValueSnapshotsTableAnnotationComposer,
      $$InvestmentValueSnapshotsTableCreateCompanionBuilder,
      $$InvestmentValueSnapshotsTableUpdateCompanionBuilder,
      (
        InvestmentValueSnapshotRow,
        BaseReferences<
          _$AppDatabase,
          $InvestmentValueSnapshotsTable,
          InvestmentValueSnapshotRow
        >,
      ),
      InvestmentValueSnapshotRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$RemoteStatusCacheTableTableManager get remoteStatusCache =>
      $$RemoteStatusCacheTableTableManager(_db, _db.remoteStatusCache);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$InvestmentsTableTableManager get investments =>
      $$InvestmentsTableTableManager(_db, _db.investments);
  $$InvestmentSalesTableTableManager get investmentSales =>
      $$InvestmentSalesTableTableManager(_db, _db.investmentSales);
  $$InvestmentValueSnapshotsTableTableManager get investmentValueSnapshots =>
      $$InvestmentValueSnapshotsTableTableManager(
        _db,
        _db.investmentValueSnapshots,
      );
}
