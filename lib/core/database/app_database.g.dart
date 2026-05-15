// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TripsTable extends Trips with TableInfo<$TripsTable, TripRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topSpeedKmhMeta = const VerificationMeta(
    'topSpeedKmh',
  );
  @override
  late final GeneratedColumn<double> topSpeedKmh = GeneratedColumn<double>(
    'top_speed_kmh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgSpeedKmhMeta = const VerificationMeta(
    'avgSpeedKmh',
  );
  @override
  late final GeneratedColumn<double> avgSpeedKmh = GeneratedColumn<double>(
    'avg_speed_kmh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
    'distance_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stoppedSecondsMeta = const VerificationMeta(
    'stoppedSeconds',
  );
  @override
  late final GeneratedColumn<int> stoppedSeconds = GeneratedColumn<int>(
    'stopped_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxGforceMeta = const VerificationMeta(
    'maxGforce',
  );
  @override
  late final GeneratedColumn<double> maxGforce = GeneratedColumn<double>(
    'max_gforce',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hardCornersCountMeta = const VerificationMeta(
    'hardCornersCount',
  );
  @override
  late final GeneratedColumn<int> hardCornersCount = GeneratedColumn<int>(
    'hard_corners_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hardBrakesCountMeta = const VerificationMeta(
    'hardBrakesCount',
  );
  @override
  late final GeneratedColumn<int> hardBrakesCount = GeneratedColumn<int>(
    'hard_brakes_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fuelCostLocalMeta = const VerificationMeta(
    'fuelCostLocal',
  );
  @override
  late final GeneratedColumn<double> fuelCostLocal = GeneratedColumn<double>(
    'fuel_cost_local',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localCurrencyCodeMeta = const VerificationMeta(
    'localCurrencyCode',
  );
  @override
  late final GeneratedColumn<String> localCurrencyCode =
      GeneratedColumn<String>(
        'local_currency_code',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _weatherConditionMeta = const VerificationMeta(
    'weatherCondition',
  );
  @override
  late final GeneratedColumn<String> weatherCondition = GeneratedColumn<String>(
    'weather_condition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weatherTempCMeta = const VerificationMeta(
    'weatherTempC',
  );
  @override
  late final GeneratedColumn<double> weatherTempC = GeneratedColumn<double>(
    'weather_temp_c',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isNightDriveMeta = const VerificationMeta(
    'isNightDrive',
  );
  @override
  late final GeneratedColumn<bool> isNightDrive = GeneratedColumn<bool>(
    'is_night_drive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_night_drive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _mapThemeMeta = const VerificationMeta(
    'mapTheme',
  );
  @override
  late final GeneratedColumn<String> mapTheme = GeneratedColumn<String>(
    'map_theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('regular'),
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
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
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    topSpeedKmh,
    avgSpeedKmh,
    distanceKm,
    durationSeconds,
    stoppedSeconds,
    maxGforce,
    hardCornersCount,
    hardBrakesCount,
    fuelCostLocal,
    localCurrencyCode,
    weatherCondition,
    weatherTempC,
    isNightDrive,
    mapTheme,
    country,
    startedAt,
    endedAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('top_speed_kmh')) {
      context.handle(
        _topSpeedKmhMeta,
        topSpeedKmh.isAcceptableOrUnknown(
          data['top_speed_kmh']!,
          _topSpeedKmhMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_topSpeedKmhMeta);
    }
    if (data.containsKey('avg_speed_kmh')) {
      context.handle(
        _avgSpeedKmhMeta,
        avgSpeedKmh.isAcceptableOrUnknown(
          data['avg_speed_kmh']!,
          _avgSpeedKmhMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgSpeedKmhMeta);
    }
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceKmMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('stopped_seconds')) {
      context.handle(
        _stoppedSecondsMeta,
        stoppedSeconds.isAcceptableOrUnknown(
          data['stopped_seconds']!,
          _stoppedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('max_gforce')) {
      context.handle(
        _maxGforceMeta,
        maxGforce.isAcceptableOrUnknown(data['max_gforce']!, _maxGforceMeta),
      );
    }
    if (data.containsKey('hard_corners_count')) {
      context.handle(
        _hardCornersCountMeta,
        hardCornersCount.isAcceptableOrUnknown(
          data['hard_corners_count']!,
          _hardCornersCountMeta,
        ),
      );
    }
    if (data.containsKey('hard_brakes_count')) {
      context.handle(
        _hardBrakesCountMeta,
        hardBrakesCount.isAcceptableOrUnknown(
          data['hard_brakes_count']!,
          _hardBrakesCountMeta,
        ),
      );
    }
    if (data.containsKey('fuel_cost_local')) {
      context.handle(
        _fuelCostLocalMeta,
        fuelCostLocal.isAcceptableOrUnknown(
          data['fuel_cost_local']!,
          _fuelCostLocalMeta,
        ),
      );
    }
    if (data.containsKey('local_currency_code')) {
      context.handle(
        _localCurrencyCodeMeta,
        localCurrencyCode.isAcceptableOrUnknown(
          data['local_currency_code']!,
          _localCurrencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('weather_condition')) {
      context.handle(
        _weatherConditionMeta,
        weatherCondition.isAcceptableOrUnknown(
          data['weather_condition']!,
          _weatherConditionMeta,
        ),
      );
    }
    if (data.containsKey('weather_temp_c')) {
      context.handle(
        _weatherTempCMeta,
        weatherTempC.isAcceptableOrUnknown(
          data['weather_temp_c']!,
          _weatherTempCMeta,
        ),
      );
    }
    if (data.containsKey('is_night_drive')) {
      context.handle(
        _isNightDriveMeta,
        isNightDrive.isAcceptableOrUnknown(
          data['is_night_drive']!,
          _isNightDriveMeta,
        ),
      );
    }
    if (data.containsKey('map_theme')) {
      context.handle(
        _mapThemeMeta,
        mapTheme.isAcceptableOrUnknown(data['map_theme']!, _mapThemeMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TripRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      topSpeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}top_speed_kmh'],
      )!,
      avgSpeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_speed_kmh'],
      )!,
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_km'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      stoppedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stopped_seconds'],
      )!,
      maxGforce: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_gforce'],
      )!,
      hardCornersCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hard_corners_count'],
      )!,
      hardBrakesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hard_brakes_count'],
      )!,
      fuelCostLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fuel_cost_local'],
      ),
      localCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_currency_code'],
      ),
      weatherCondition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weather_condition'],
      ),
      weatherTempC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weather_temp_c'],
      ),
      isNightDrive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_night_drive'],
      )!,
      mapTheme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}map_theme'],
      )!,
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class TripRow extends DataClass implements Insertable<TripRow> {
  final int id;

  /// Owning user id (Firebase Auth UID, or anonymous local UID).
  final String uid;
  final double topSpeedKmh;
  final double avgSpeedKmh;
  final double distanceKm;
  final int durationSeconds;
  final int stoppedSeconds;
  final double maxGforce;
  final int hardCornersCount;
  final int hardBrakesCount;

  /// Fuel cost in the user's local currency at trip time. Null if the user
  /// hasn't configured fuel price/consumption — the UI shows "—" then.
  final double? fuelCostLocal;
  final String? localCurrencyCode;
  final String? weatherCondition;
  final double? weatherTempC;
  final bool isNightDrive;

  /// Map theme used to render this trip's route — kept so the share card
  /// can re-render in the original theme even if the user changed it later.
  final String mapTheme;

  /// ISO 3166-1 alpha-2 country code where the trip occurred.
  final String? country;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isSynced;
  const TripRow({
    required this.id,
    required this.uid,
    required this.topSpeedKmh,
    required this.avgSpeedKmh,
    required this.distanceKm,
    required this.durationSeconds,
    required this.stoppedSeconds,
    required this.maxGforce,
    required this.hardCornersCount,
    required this.hardBrakesCount,
    this.fuelCostLocal,
    this.localCurrencyCode,
    this.weatherCondition,
    this.weatherTempC,
    required this.isNightDrive,
    required this.mapTheme,
    this.country,
    required this.startedAt,
    this.endedAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    map['top_speed_kmh'] = Variable<double>(topSpeedKmh);
    map['avg_speed_kmh'] = Variable<double>(avgSpeedKmh);
    map['distance_km'] = Variable<double>(distanceKm);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['stopped_seconds'] = Variable<int>(stoppedSeconds);
    map['max_gforce'] = Variable<double>(maxGforce);
    map['hard_corners_count'] = Variable<int>(hardCornersCount);
    map['hard_brakes_count'] = Variable<int>(hardBrakesCount);
    if (!nullToAbsent || fuelCostLocal != null) {
      map['fuel_cost_local'] = Variable<double>(fuelCostLocal);
    }
    if (!nullToAbsent || localCurrencyCode != null) {
      map['local_currency_code'] = Variable<String>(localCurrencyCode);
    }
    if (!nullToAbsent || weatherCondition != null) {
      map['weather_condition'] = Variable<String>(weatherCondition);
    }
    if (!nullToAbsent || weatherTempC != null) {
      map['weather_temp_c'] = Variable<double>(weatherTempC);
    }
    map['is_night_drive'] = Variable<bool>(isNightDrive);
    map['map_theme'] = Variable<String>(mapTheme);
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      uid: Value(uid),
      topSpeedKmh: Value(topSpeedKmh),
      avgSpeedKmh: Value(avgSpeedKmh),
      distanceKm: Value(distanceKm),
      durationSeconds: Value(durationSeconds),
      stoppedSeconds: Value(stoppedSeconds),
      maxGforce: Value(maxGforce),
      hardCornersCount: Value(hardCornersCount),
      hardBrakesCount: Value(hardBrakesCount),
      fuelCostLocal: fuelCostLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(fuelCostLocal),
      localCurrencyCode: localCurrencyCode == null && nullToAbsent
          ? const Value.absent()
          : Value(localCurrencyCode),
      weatherCondition: weatherCondition == null && nullToAbsent
          ? const Value.absent()
          : Value(weatherCondition),
      weatherTempC: weatherTempC == null && nullToAbsent
          ? const Value.absent()
          : Value(weatherTempC),
      isNightDrive: Value(isNightDrive),
      mapTheme: Value(mapTheme),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      isSynced: Value(isSynced),
    );
  }

  factory TripRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripRow(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      topSpeedKmh: serializer.fromJson<double>(json['topSpeedKmh']),
      avgSpeedKmh: serializer.fromJson<double>(json['avgSpeedKmh']),
      distanceKm: serializer.fromJson<double>(json['distanceKm']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      stoppedSeconds: serializer.fromJson<int>(json['stoppedSeconds']),
      maxGforce: serializer.fromJson<double>(json['maxGforce']),
      hardCornersCount: serializer.fromJson<int>(json['hardCornersCount']),
      hardBrakesCount: serializer.fromJson<int>(json['hardBrakesCount']),
      fuelCostLocal: serializer.fromJson<double?>(json['fuelCostLocal']),
      localCurrencyCode: serializer.fromJson<String?>(
        json['localCurrencyCode'],
      ),
      weatherCondition: serializer.fromJson<String?>(json['weatherCondition']),
      weatherTempC: serializer.fromJson<double?>(json['weatherTempC']),
      isNightDrive: serializer.fromJson<bool>(json['isNightDrive']),
      mapTheme: serializer.fromJson<String>(json['mapTheme']),
      country: serializer.fromJson<String?>(json['country']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'topSpeedKmh': serializer.toJson<double>(topSpeedKmh),
      'avgSpeedKmh': serializer.toJson<double>(avgSpeedKmh),
      'distanceKm': serializer.toJson<double>(distanceKm),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'stoppedSeconds': serializer.toJson<int>(stoppedSeconds),
      'maxGforce': serializer.toJson<double>(maxGforce),
      'hardCornersCount': serializer.toJson<int>(hardCornersCount),
      'hardBrakesCount': serializer.toJson<int>(hardBrakesCount),
      'fuelCostLocal': serializer.toJson<double?>(fuelCostLocal),
      'localCurrencyCode': serializer.toJson<String?>(localCurrencyCode),
      'weatherCondition': serializer.toJson<String?>(weatherCondition),
      'weatherTempC': serializer.toJson<double?>(weatherTempC),
      'isNightDrive': serializer.toJson<bool>(isNightDrive),
      'mapTheme': serializer.toJson<String>(mapTheme),
      'country': serializer.toJson<String?>(country),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  TripRow copyWith({
    int? id,
    String? uid,
    double? topSpeedKmh,
    double? avgSpeedKmh,
    double? distanceKm,
    int? durationSeconds,
    int? stoppedSeconds,
    double? maxGforce,
    int? hardCornersCount,
    int? hardBrakesCount,
    Value<double?> fuelCostLocal = const Value.absent(),
    Value<String?> localCurrencyCode = const Value.absent(),
    Value<String?> weatherCondition = const Value.absent(),
    Value<double?> weatherTempC = const Value.absent(),
    bool? isNightDrive,
    String? mapTheme,
    Value<String?> country = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    bool? isSynced,
  }) => TripRow(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    topSpeedKmh: topSpeedKmh ?? this.topSpeedKmh,
    avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
    distanceKm: distanceKm ?? this.distanceKm,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    stoppedSeconds: stoppedSeconds ?? this.stoppedSeconds,
    maxGforce: maxGforce ?? this.maxGforce,
    hardCornersCount: hardCornersCount ?? this.hardCornersCount,
    hardBrakesCount: hardBrakesCount ?? this.hardBrakesCount,
    fuelCostLocal: fuelCostLocal.present
        ? fuelCostLocal.value
        : this.fuelCostLocal,
    localCurrencyCode: localCurrencyCode.present
        ? localCurrencyCode.value
        : this.localCurrencyCode,
    weatherCondition: weatherCondition.present
        ? weatherCondition.value
        : this.weatherCondition,
    weatherTempC: weatherTempC.present ? weatherTempC.value : this.weatherTempC,
    isNightDrive: isNightDrive ?? this.isNightDrive,
    mapTheme: mapTheme ?? this.mapTheme,
    country: country.present ? country.value : this.country,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    isSynced: isSynced ?? this.isSynced,
  );
  TripRow copyWithCompanion(TripsCompanion data) {
    return TripRow(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      topSpeedKmh: data.topSpeedKmh.present
          ? data.topSpeedKmh.value
          : this.topSpeedKmh,
      avgSpeedKmh: data.avgSpeedKmh.present
          ? data.avgSpeedKmh.value
          : this.avgSpeedKmh,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      stoppedSeconds: data.stoppedSeconds.present
          ? data.stoppedSeconds.value
          : this.stoppedSeconds,
      maxGforce: data.maxGforce.present ? data.maxGforce.value : this.maxGforce,
      hardCornersCount: data.hardCornersCount.present
          ? data.hardCornersCount.value
          : this.hardCornersCount,
      hardBrakesCount: data.hardBrakesCount.present
          ? data.hardBrakesCount.value
          : this.hardBrakesCount,
      fuelCostLocal: data.fuelCostLocal.present
          ? data.fuelCostLocal.value
          : this.fuelCostLocal,
      localCurrencyCode: data.localCurrencyCode.present
          ? data.localCurrencyCode.value
          : this.localCurrencyCode,
      weatherCondition: data.weatherCondition.present
          ? data.weatherCondition.value
          : this.weatherCondition,
      weatherTempC: data.weatherTempC.present
          ? data.weatherTempC.value
          : this.weatherTempC,
      isNightDrive: data.isNightDrive.present
          ? data.isNightDrive.value
          : this.isNightDrive,
      mapTheme: data.mapTheme.present ? data.mapTheme.value : this.mapTheme,
      country: data.country.present ? data.country.value : this.country,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripRow(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('topSpeedKmh: $topSpeedKmh, ')
          ..write('avgSpeedKmh: $avgSpeedKmh, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('stoppedSeconds: $stoppedSeconds, ')
          ..write('maxGforce: $maxGforce, ')
          ..write('hardCornersCount: $hardCornersCount, ')
          ..write('hardBrakesCount: $hardBrakesCount, ')
          ..write('fuelCostLocal: $fuelCostLocal, ')
          ..write('localCurrencyCode: $localCurrencyCode, ')
          ..write('weatherCondition: $weatherCondition, ')
          ..write('weatherTempC: $weatherTempC, ')
          ..write('isNightDrive: $isNightDrive, ')
          ..write('mapTheme: $mapTheme, ')
          ..write('country: $country, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    topSpeedKmh,
    avgSpeedKmh,
    distanceKm,
    durationSeconds,
    stoppedSeconds,
    maxGforce,
    hardCornersCount,
    hardBrakesCount,
    fuelCostLocal,
    localCurrencyCode,
    weatherCondition,
    weatherTempC,
    isNightDrive,
    mapTheme,
    country,
    startedAt,
    endedAt,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripRow &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.topSpeedKmh == this.topSpeedKmh &&
          other.avgSpeedKmh == this.avgSpeedKmh &&
          other.distanceKm == this.distanceKm &&
          other.durationSeconds == this.durationSeconds &&
          other.stoppedSeconds == this.stoppedSeconds &&
          other.maxGforce == this.maxGforce &&
          other.hardCornersCount == this.hardCornersCount &&
          other.hardBrakesCount == this.hardBrakesCount &&
          other.fuelCostLocal == this.fuelCostLocal &&
          other.localCurrencyCode == this.localCurrencyCode &&
          other.weatherCondition == this.weatherCondition &&
          other.weatherTempC == this.weatherTempC &&
          other.isNightDrive == this.isNightDrive &&
          other.mapTheme == this.mapTheme &&
          other.country == this.country &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.isSynced == this.isSynced);
}

class TripsCompanion extends UpdateCompanion<TripRow> {
  final Value<int> id;
  final Value<String> uid;
  final Value<double> topSpeedKmh;
  final Value<double> avgSpeedKmh;
  final Value<double> distanceKm;
  final Value<int> durationSeconds;
  final Value<int> stoppedSeconds;
  final Value<double> maxGforce;
  final Value<int> hardCornersCount;
  final Value<int> hardBrakesCount;
  final Value<double?> fuelCostLocal;
  final Value<String?> localCurrencyCode;
  final Value<String?> weatherCondition;
  final Value<double?> weatherTempC;
  final Value<bool> isNightDrive;
  final Value<String> mapTheme;
  final Value<String?> country;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<bool> isSynced;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.topSpeedKmh = const Value.absent(),
    this.avgSpeedKmh = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.stoppedSeconds = const Value.absent(),
    this.maxGforce = const Value.absent(),
    this.hardCornersCount = const Value.absent(),
    this.hardBrakesCount = const Value.absent(),
    this.fuelCostLocal = const Value.absent(),
    this.localCurrencyCode = const Value.absent(),
    this.weatherCondition = const Value.absent(),
    this.weatherTempC = const Value.absent(),
    this.isNightDrive = const Value.absent(),
    this.mapTheme = const Value.absent(),
    this.country = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
  });
  TripsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required double topSpeedKmh,
    required double avgSpeedKmh,
    required double distanceKm,
    required int durationSeconds,
    this.stoppedSeconds = const Value.absent(),
    this.maxGforce = const Value.absent(),
    this.hardCornersCount = const Value.absent(),
    this.hardBrakesCount = const Value.absent(),
    this.fuelCostLocal = const Value.absent(),
    this.localCurrencyCode = const Value.absent(),
    this.weatherCondition = const Value.absent(),
    this.weatherTempC = const Value.absent(),
    this.isNightDrive = const Value.absent(),
    this.mapTheme = const Value.absent(),
    this.country = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
  }) : uid = Value(uid),
       topSpeedKmh = Value(topSpeedKmh),
       avgSpeedKmh = Value(avgSpeedKmh),
       distanceKm = Value(distanceKm),
       durationSeconds = Value(durationSeconds),
       startedAt = Value(startedAt);
  static Insertable<TripRow> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<double>? topSpeedKmh,
    Expression<double>? avgSpeedKmh,
    Expression<double>? distanceKm,
    Expression<int>? durationSeconds,
    Expression<int>? stoppedSeconds,
    Expression<double>? maxGforce,
    Expression<int>? hardCornersCount,
    Expression<int>? hardBrakesCount,
    Expression<double>? fuelCostLocal,
    Expression<String>? localCurrencyCode,
    Expression<String>? weatherCondition,
    Expression<double>? weatherTempC,
    Expression<bool>? isNightDrive,
    Expression<String>? mapTheme,
    Expression<String>? country,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<bool>? isSynced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (topSpeedKmh != null) 'top_speed_kmh': topSpeedKmh,
      if (avgSpeedKmh != null) 'avg_speed_kmh': avgSpeedKmh,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (stoppedSeconds != null) 'stopped_seconds': stoppedSeconds,
      if (maxGforce != null) 'max_gforce': maxGforce,
      if (hardCornersCount != null) 'hard_corners_count': hardCornersCount,
      if (hardBrakesCount != null) 'hard_brakes_count': hardBrakesCount,
      if (fuelCostLocal != null) 'fuel_cost_local': fuelCostLocal,
      if (localCurrencyCode != null) 'local_currency_code': localCurrencyCode,
      if (weatherCondition != null) 'weather_condition': weatherCondition,
      if (weatherTempC != null) 'weather_temp_c': weatherTempC,
      if (isNightDrive != null) 'is_night_drive': isNightDrive,
      if (mapTheme != null) 'map_theme': mapTheme,
      if (country != null) 'country': country,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (isSynced != null) 'is_synced': isSynced,
    });
  }

  TripsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<double>? topSpeedKmh,
    Value<double>? avgSpeedKmh,
    Value<double>? distanceKm,
    Value<int>? durationSeconds,
    Value<int>? stoppedSeconds,
    Value<double>? maxGforce,
    Value<int>? hardCornersCount,
    Value<int>? hardBrakesCount,
    Value<double?>? fuelCostLocal,
    Value<String?>? localCurrencyCode,
    Value<String?>? weatherCondition,
    Value<double?>? weatherTempC,
    Value<bool>? isNightDrive,
    Value<String>? mapTheme,
    Value<String?>? country,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<bool>? isSynced,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      topSpeedKmh: topSpeedKmh ?? this.topSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      stoppedSeconds: stoppedSeconds ?? this.stoppedSeconds,
      maxGforce: maxGforce ?? this.maxGforce,
      hardCornersCount: hardCornersCount ?? this.hardCornersCount,
      hardBrakesCount: hardBrakesCount ?? this.hardBrakesCount,
      fuelCostLocal: fuelCostLocal ?? this.fuelCostLocal,
      localCurrencyCode: localCurrencyCode ?? this.localCurrencyCode,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      weatherTempC: weatherTempC ?? this.weatherTempC,
      isNightDrive: isNightDrive ?? this.isNightDrive,
      mapTheme: mapTheme ?? this.mapTheme,
      country: country ?? this.country,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (topSpeedKmh.present) {
      map['top_speed_kmh'] = Variable<double>(topSpeedKmh.value);
    }
    if (avgSpeedKmh.present) {
      map['avg_speed_kmh'] = Variable<double>(avgSpeedKmh.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (stoppedSeconds.present) {
      map['stopped_seconds'] = Variable<int>(stoppedSeconds.value);
    }
    if (maxGforce.present) {
      map['max_gforce'] = Variable<double>(maxGforce.value);
    }
    if (hardCornersCount.present) {
      map['hard_corners_count'] = Variable<int>(hardCornersCount.value);
    }
    if (hardBrakesCount.present) {
      map['hard_brakes_count'] = Variable<int>(hardBrakesCount.value);
    }
    if (fuelCostLocal.present) {
      map['fuel_cost_local'] = Variable<double>(fuelCostLocal.value);
    }
    if (localCurrencyCode.present) {
      map['local_currency_code'] = Variable<String>(localCurrencyCode.value);
    }
    if (weatherCondition.present) {
      map['weather_condition'] = Variable<String>(weatherCondition.value);
    }
    if (weatherTempC.present) {
      map['weather_temp_c'] = Variable<double>(weatherTempC.value);
    }
    if (isNightDrive.present) {
      map['is_night_drive'] = Variable<bool>(isNightDrive.value);
    }
    if (mapTheme.present) {
      map['map_theme'] = Variable<String>(mapTheme.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('topSpeedKmh: $topSpeedKmh, ')
          ..write('avgSpeedKmh: $avgSpeedKmh, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('stoppedSeconds: $stoppedSeconds, ')
          ..write('maxGforce: $maxGforce, ')
          ..write('hardCornersCount: $hardCornersCount, ')
          ..write('hardBrakesCount: $hardBrakesCount, ')
          ..write('fuelCostLocal: $fuelCostLocal, ')
          ..write('localCurrencyCode: $localCurrencyCode, ')
          ..write('weatherCondition: $weatherCondition, ')
          ..write('weatherTempC: $weatherTempC, ')
          ..write('isNightDrive: $isNightDrive, ')
          ..write('mapTheme: $mapTheme, ')
          ..write('country: $country, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }
}

class $WaypointsTable extends Waypoints
    with TableInfo<$WaypointsTable, WaypointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaypointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedKmhMeta = const VerificationMeta(
    'speedKmh',
  );
  @override
  late final GeneratedColumn<double> speedKmh = GeneratedColumn<double>(
    'speed_kmh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMetersMeta = const VerificationMeta(
    'accuracyMeters',
  );
  @override
  late final GeneratedColumn<double> accuracyMeters = GeneratedColumn<double>(
    'accuracy_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    lat,
    lng,
    speedKmh,
    accuracyMeters,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'waypoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaypointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('speed_kmh')) {
      context.handle(
        _speedKmhMeta,
        speedKmh.isAcceptableOrUnknown(data['speed_kmh']!, _speedKmhMeta),
      );
    } else if (isInserting) {
      context.missing(_speedKmhMeta);
    }
    if (data.containsKey('accuracy_meters')) {
      context.handle(
        _accuracyMetersMeta,
        accuracyMeters.isAcceptableOrUnknown(
          data['accuracy_meters']!,
          _accuracyMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accuracyMetersMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaypointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaypointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trip_id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      speedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_kmh'],
      )!,
      accuracyMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_meters'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $WaypointsTable createAlias(String alias) {
    return $WaypointsTable(attachedDatabase, alias);
  }
}

class WaypointRow extends DataClass implements Insertable<WaypointRow> {
  final int id;
  final int tripId;
  final double lat;
  final double lng;

  /// Instantaneous speed at this waypoint (km/h, metric).
  final double speedKmh;

  /// Reported GPS accuracy in metres (lower is better).
  final double accuracyMeters;
  final DateTime timestamp;
  const WaypointRow({
    required this.id,
    required this.tripId,
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.accuracyMeters,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<int>(tripId);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['speed_kmh'] = Variable<double>(speedKmh);
    map['accuracy_meters'] = Variable<double>(accuracyMeters);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  WaypointsCompanion toCompanion(bool nullToAbsent) {
    return WaypointsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      lat: Value(lat),
      lng: Value(lng),
      speedKmh: Value(speedKmh),
      accuracyMeters: Value(accuracyMeters),
      timestamp: Value(timestamp),
    );
  }

  factory WaypointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaypointRow(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<int>(json['tripId']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      speedKmh: serializer.fromJson<double>(json['speedKmh']),
      accuracyMeters: serializer.fromJson<double>(json['accuracyMeters']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<int>(tripId),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'speedKmh': serializer.toJson<double>(speedKmh),
      'accuracyMeters': serializer.toJson<double>(accuracyMeters),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  WaypointRow copyWith({
    int? id,
    int? tripId,
    double? lat,
    double? lng,
    double? speedKmh,
    double? accuracyMeters,
    DateTime? timestamp,
  }) => WaypointRow(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    speedKmh: speedKmh ?? this.speedKmh,
    accuracyMeters: accuracyMeters ?? this.accuracyMeters,
    timestamp: timestamp ?? this.timestamp,
  );
  WaypointRow copyWithCompanion(WaypointsCompanion data) {
    return WaypointRow(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      speedKmh: data.speedKmh.present ? data.speedKmh.value : this.speedKmh,
      accuracyMeters: data.accuracyMeters.present
          ? data.accuracyMeters.value
          : this.accuracyMeters,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaypointRow(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('speedKmh: $speedKmh, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tripId, lat, lng, speedKmh, accuracyMeters, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaypointRow &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.speedKmh == this.speedKmh &&
          other.accuracyMeters == this.accuracyMeters &&
          other.timestamp == this.timestamp);
}

class WaypointsCompanion extends UpdateCompanion<WaypointRow> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double> speedKmh;
  final Value<double> accuracyMeters;
  final Value<DateTime> timestamp;
  const WaypointsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.speedKmh = const Value.absent(),
    this.accuracyMeters = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  WaypointsCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    required double lat,
    required double lng,
    required double speedKmh,
    required double accuracyMeters,
    required DateTime timestamp,
  }) : tripId = Value(tripId),
       lat = Value(lat),
       lng = Value(lng),
       speedKmh = Value(speedKmh),
       accuracyMeters = Value(accuracyMeters),
       timestamp = Value(timestamp);
  static Insertable<WaypointRow> custom({
    Expression<int>? id,
    Expression<int>? tripId,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? speedKmh,
    Expression<double>? accuracyMeters,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (speedKmh != null) 'speed_kmh': speedKmh,
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  WaypointsCompanion copyWith({
    Value<int>? id,
    Value<int>? tripId,
    Value<double>? lat,
    Value<double>? lng,
    Value<double>? speedKmh,
    Value<double>? accuracyMeters,
    Value<DateTime>? timestamp,
  }) {
    return WaypointsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speedKmh: speedKmh ?? this.speedKmh,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (speedKmh.present) {
      map['speed_kmh'] = Variable<double>(speedKmh.value);
    }
    if (accuracyMeters.present) {
      map['accuracy_meters'] = Variable<double>(accuracyMeters.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaypointsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('speedKmh: $speedKmh, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _carMakeMeta = const VerificationMeta(
    'carMake',
  );
  @override
  late final GeneratedColumn<String> carMake = GeneratedColumn<String>(
    'car_make',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _carModelMeta = const VerificationMeta(
    'carModel',
  );
  @override
  late final GeneratedColumn<String> carModel = GeneratedColumn<String>(
    'car_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _carYearMeta = const VerificationMeta(
    'carYear',
  );
  @override
  late final GeneratedColumn<int> carYear = GeneratedColumn<int>(
    'car_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carColourMeta = const VerificationMeta(
    'carColour',
  );
  @override
  late final GeneratedColumn<String> carColour = GeneratedColumn<String>(
    'car_colour',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carPhotoPathMeta = const VerificationMeta(
    'carPhotoPath',
  );
  @override
  late final GeneratedColumn<String> carPhotoPath = GeneratedColumn<String>(
    'car_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vehicleTypeMeta = const VerificationMeta(
    'vehicleType',
  );
  @override
  late final GeneratedColumn<String> vehicleType = GeneratedColumn<String>(
    'vehicle_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('car'),
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitSystemMeta = const VerificationMeta(
    'unitSystem',
  );
  @override
  late final GeneratedColumn<String> unitSystem = GeneratedColumn<String>(
    'unit_system',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('metric'),
  );
  static const VerificationMeta _fuelTypeMeta = const VerificationMeta(
    'fuelType',
  );
  @override
  late final GeneratedColumn<String> fuelType = GeneratedColumn<String>(
    'fuel_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fuelConsumptionMeta = const VerificationMeta(
    'fuelConsumption',
  );
  @override
  late final GeneratedColumn<double> fuelConsumption = GeneratedColumn<double>(
    'fuel_consumption',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fuelPricePerUnitMeta = const VerificationMeta(
    'fuelPricePerUnit',
  );
  @override
  late final GeneratedColumn<double> fuelPricePerUnit = GeneratedColumn<double>(
    'fuel_price_per_unit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _selectedMapThemeMeta = const VerificationMeta(
    'selectedMapTheme',
  );
  @override
  late final GeneratedColumn<String> selectedMapTheme = GeneratedColumn<String>(
    'selected_map_theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('regular'),
  );
  static const VerificationMeta _freeTripsUsedMeta = const VerificationMeta(
    'freeTripsUsed',
  );
  @override
  late final GeneratedColumn<int> freeTripsUsed = GeneratedColumn<int>(
    'free_trips_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isProMeta = const VerificationMeta('isPro');
  @override
  late final GeneratedColumn<bool> isPro = GeneratedColumn<bool>(
    'is_pro',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pro" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _onboardingCompleteMeta =
      const VerificationMeta('onboardingComplete');
  @override
  late final GeneratedColumn<bool> onboardingComplete = GeneratedColumn<bool>(
    'onboarding_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_complete" IN (0, 1))',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    username,
    carMake,
    carModel,
    carYear,
    carColour,
    carPhotoPath,
    vehicleType,
    country,
    unitSystem,
    fuelType,
    fuelConsumption,
    fuelPricePerUnit,
    currencyCode,
    selectedMapTheme,
    freeTripsUsed,
    isPro,
    onboardingComplete,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('car_make')) {
      context.handle(
        _carMakeMeta,
        carMake.isAcceptableOrUnknown(data['car_make']!, _carMakeMeta),
      );
    }
    if (data.containsKey('car_model')) {
      context.handle(
        _carModelMeta,
        carModel.isAcceptableOrUnknown(data['car_model']!, _carModelMeta),
      );
    }
    if (data.containsKey('car_year')) {
      context.handle(
        _carYearMeta,
        carYear.isAcceptableOrUnknown(data['car_year']!, _carYearMeta),
      );
    }
    if (data.containsKey('car_colour')) {
      context.handle(
        _carColourMeta,
        carColour.isAcceptableOrUnknown(data['car_colour']!, _carColourMeta),
      );
    }
    if (data.containsKey('car_photo_path')) {
      context.handle(
        _carPhotoPathMeta,
        carPhotoPath.isAcceptableOrUnknown(
          data['car_photo_path']!,
          _carPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('vehicle_type')) {
      context.handle(
        _vehicleTypeMeta,
        vehicleType.isAcceptableOrUnknown(
          data['vehicle_type']!,
          _vehicleTypeMeta,
        ),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('unit_system')) {
      context.handle(
        _unitSystemMeta,
        unitSystem.isAcceptableOrUnknown(data['unit_system']!, _unitSystemMeta),
      );
    }
    if (data.containsKey('fuel_type')) {
      context.handle(
        _fuelTypeMeta,
        fuelType.isAcceptableOrUnknown(data['fuel_type']!, _fuelTypeMeta),
      );
    }
    if (data.containsKey('fuel_consumption')) {
      context.handle(
        _fuelConsumptionMeta,
        fuelConsumption.isAcceptableOrUnknown(
          data['fuel_consumption']!,
          _fuelConsumptionMeta,
        ),
      );
    }
    if (data.containsKey('fuel_price_per_unit')) {
      context.handle(
        _fuelPricePerUnitMeta,
        fuelPricePerUnit.isAcceptableOrUnknown(
          data['fuel_price_per_unit']!,
          _fuelPricePerUnitMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('selected_map_theme')) {
      context.handle(
        _selectedMapThemeMeta,
        selectedMapTheme.isAcceptableOrUnknown(
          data['selected_map_theme']!,
          _selectedMapThemeMeta,
        ),
      );
    }
    if (data.containsKey('free_trips_used')) {
      context.handle(
        _freeTripsUsedMeta,
        freeTripsUsed.isAcceptableOrUnknown(
          data['free_trips_used']!,
          _freeTripsUsedMeta,
        ),
      );
    }
    if (data.containsKey('is_pro')) {
      context.handle(
        _isProMeta,
        isPro.isAcceptableOrUnknown(data['is_pro']!, _isProMeta),
      );
    }
    if (data.containsKey('onboarding_complete')) {
      context.handle(
        _onboardingCompleteMeta,
        onboardingComplete.isAcceptableOrUnknown(
          data['onboarding_complete']!,
          _onboardingCompleteMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      carMake: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}car_make'],
      )!,
      carModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}car_model'],
      )!,
      carYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}car_year'],
      ),
      carColour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}car_colour'],
      ),
      carPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}car_photo_path'],
      ),
      vehicleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_type'],
      )!,
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      unitSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_system'],
      )!,
      fuelType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fuel_type'],
      ),
      fuelConsumption: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fuel_consumption'],
      ),
      fuelPricePerUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fuel_price_per_unit'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      ),
      selectedMapTheme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_map_theme'],
      )!,
      freeTripsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}free_trips_used'],
      )!,
      isPro: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pro'],
      )!,
      onboardingComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_complete'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSettingsRow extends DataClass implements Insertable<UserSettingsRow> {
  final int id;
  final String uid;
  final String username;
  final String carMake;
  final String carModel;
  final int? carYear;
  final String? carColour;
  final String? carPhotoPath;
  final String vehicleType;
  final String? country;
  final String unitSystem;
  final String? fuelType;
  final double? fuelConsumption;
  final double? fuelPricePerUnit;
  final String? currencyCode;
  final String selectedMapTheme;
  final int freeTripsUsed;
  final bool isPro;
  final bool onboardingComplete;
  final DateTime createdAt;
  const UserSettingsRow({
    required this.id,
    required this.uid,
    required this.username,
    required this.carMake,
    required this.carModel,
    this.carYear,
    this.carColour,
    this.carPhotoPath,
    required this.vehicleType,
    this.country,
    required this.unitSystem,
    this.fuelType,
    this.fuelConsumption,
    this.fuelPricePerUnit,
    this.currencyCode,
    required this.selectedMapTheme,
    required this.freeTripsUsed,
    required this.isPro,
    required this.onboardingComplete,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    map['username'] = Variable<String>(username);
    map['car_make'] = Variable<String>(carMake);
    map['car_model'] = Variable<String>(carModel);
    if (!nullToAbsent || carYear != null) {
      map['car_year'] = Variable<int>(carYear);
    }
    if (!nullToAbsent || carColour != null) {
      map['car_colour'] = Variable<String>(carColour);
    }
    if (!nullToAbsent || carPhotoPath != null) {
      map['car_photo_path'] = Variable<String>(carPhotoPath);
    }
    map['vehicle_type'] = Variable<String>(vehicleType);
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    map['unit_system'] = Variable<String>(unitSystem);
    if (!nullToAbsent || fuelType != null) {
      map['fuel_type'] = Variable<String>(fuelType);
    }
    if (!nullToAbsent || fuelConsumption != null) {
      map['fuel_consumption'] = Variable<double>(fuelConsumption);
    }
    if (!nullToAbsent || fuelPricePerUnit != null) {
      map['fuel_price_per_unit'] = Variable<double>(fuelPricePerUnit);
    }
    if (!nullToAbsent || currencyCode != null) {
      map['currency_code'] = Variable<String>(currencyCode);
    }
    map['selected_map_theme'] = Variable<String>(selectedMapTheme);
    map['free_trips_used'] = Variable<int>(freeTripsUsed);
    map['is_pro'] = Variable<bool>(isPro);
    map['onboarding_complete'] = Variable<bool>(onboardingComplete);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      id: Value(id),
      uid: Value(uid),
      username: Value(username),
      carMake: Value(carMake),
      carModel: Value(carModel),
      carYear: carYear == null && nullToAbsent
          ? const Value.absent()
          : Value(carYear),
      carColour: carColour == null && nullToAbsent
          ? const Value.absent()
          : Value(carColour),
      carPhotoPath: carPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(carPhotoPath),
      vehicleType: Value(vehicleType),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      unitSystem: Value(unitSystem),
      fuelType: fuelType == null && nullToAbsent
          ? const Value.absent()
          : Value(fuelType),
      fuelConsumption: fuelConsumption == null && nullToAbsent
          ? const Value.absent()
          : Value(fuelConsumption),
      fuelPricePerUnit: fuelPricePerUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(fuelPricePerUnit),
      currencyCode: currencyCode == null && nullToAbsent
          ? const Value.absent()
          : Value(currencyCode),
      selectedMapTheme: Value(selectedMapTheme),
      freeTripsUsed: Value(freeTripsUsed),
      isPro: Value(isPro),
      onboardingComplete: Value(onboardingComplete),
      createdAt: Value(createdAt),
    );
  }

  factory UserSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      username: serializer.fromJson<String>(json['username']),
      carMake: serializer.fromJson<String>(json['carMake']),
      carModel: serializer.fromJson<String>(json['carModel']),
      carYear: serializer.fromJson<int?>(json['carYear']),
      carColour: serializer.fromJson<String?>(json['carColour']),
      carPhotoPath: serializer.fromJson<String?>(json['carPhotoPath']),
      vehicleType: serializer.fromJson<String>(json['vehicleType']),
      country: serializer.fromJson<String?>(json['country']),
      unitSystem: serializer.fromJson<String>(json['unitSystem']),
      fuelType: serializer.fromJson<String?>(json['fuelType']),
      fuelConsumption: serializer.fromJson<double?>(json['fuelConsumption']),
      fuelPricePerUnit: serializer.fromJson<double?>(json['fuelPricePerUnit']),
      currencyCode: serializer.fromJson<String?>(json['currencyCode']),
      selectedMapTheme: serializer.fromJson<String>(json['selectedMapTheme']),
      freeTripsUsed: serializer.fromJson<int>(json['freeTripsUsed']),
      isPro: serializer.fromJson<bool>(json['isPro']),
      onboardingComplete: serializer.fromJson<bool>(json['onboardingComplete']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'username': serializer.toJson<String>(username),
      'carMake': serializer.toJson<String>(carMake),
      'carModel': serializer.toJson<String>(carModel),
      'carYear': serializer.toJson<int?>(carYear),
      'carColour': serializer.toJson<String?>(carColour),
      'carPhotoPath': serializer.toJson<String?>(carPhotoPath),
      'vehicleType': serializer.toJson<String>(vehicleType),
      'country': serializer.toJson<String?>(country),
      'unitSystem': serializer.toJson<String>(unitSystem),
      'fuelType': serializer.toJson<String?>(fuelType),
      'fuelConsumption': serializer.toJson<double?>(fuelConsumption),
      'fuelPricePerUnit': serializer.toJson<double?>(fuelPricePerUnit),
      'currencyCode': serializer.toJson<String?>(currencyCode),
      'selectedMapTheme': serializer.toJson<String>(selectedMapTheme),
      'freeTripsUsed': serializer.toJson<int>(freeTripsUsed),
      'isPro': serializer.toJson<bool>(isPro),
      'onboardingComplete': serializer.toJson<bool>(onboardingComplete),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserSettingsRow copyWith({
    int? id,
    String? uid,
    String? username,
    String? carMake,
    String? carModel,
    Value<int?> carYear = const Value.absent(),
    Value<String?> carColour = const Value.absent(),
    Value<String?> carPhotoPath = const Value.absent(),
    String? vehicleType,
    Value<String?> country = const Value.absent(),
    String? unitSystem,
    Value<String?> fuelType = const Value.absent(),
    Value<double?> fuelConsumption = const Value.absent(),
    Value<double?> fuelPricePerUnit = const Value.absent(),
    Value<String?> currencyCode = const Value.absent(),
    String? selectedMapTheme,
    int? freeTripsUsed,
    bool? isPro,
    bool? onboardingComplete,
    DateTime? createdAt,
  }) => UserSettingsRow(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    username: username ?? this.username,
    carMake: carMake ?? this.carMake,
    carModel: carModel ?? this.carModel,
    carYear: carYear.present ? carYear.value : this.carYear,
    carColour: carColour.present ? carColour.value : this.carColour,
    carPhotoPath: carPhotoPath.present ? carPhotoPath.value : this.carPhotoPath,
    vehicleType: vehicleType ?? this.vehicleType,
    country: country.present ? country.value : this.country,
    unitSystem: unitSystem ?? this.unitSystem,
    fuelType: fuelType.present ? fuelType.value : this.fuelType,
    fuelConsumption: fuelConsumption.present
        ? fuelConsumption.value
        : this.fuelConsumption,
    fuelPricePerUnit: fuelPricePerUnit.present
        ? fuelPricePerUnit.value
        : this.fuelPricePerUnit,
    currencyCode: currencyCode.present ? currencyCode.value : this.currencyCode,
    selectedMapTheme: selectedMapTheme ?? this.selectedMapTheme,
    freeTripsUsed: freeTripsUsed ?? this.freeTripsUsed,
    isPro: isPro ?? this.isPro,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    createdAt: createdAt ?? this.createdAt,
  );
  UserSettingsRow copyWithCompanion(UserSettingsCompanion data) {
    return UserSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      username: data.username.present ? data.username.value : this.username,
      carMake: data.carMake.present ? data.carMake.value : this.carMake,
      carModel: data.carModel.present ? data.carModel.value : this.carModel,
      carYear: data.carYear.present ? data.carYear.value : this.carYear,
      carColour: data.carColour.present ? data.carColour.value : this.carColour,
      carPhotoPath: data.carPhotoPath.present
          ? data.carPhotoPath.value
          : this.carPhotoPath,
      vehicleType: data.vehicleType.present
          ? data.vehicleType.value
          : this.vehicleType,
      country: data.country.present ? data.country.value : this.country,
      unitSystem: data.unitSystem.present
          ? data.unitSystem.value
          : this.unitSystem,
      fuelType: data.fuelType.present ? data.fuelType.value : this.fuelType,
      fuelConsumption: data.fuelConsumption.present
          ? data.fuelConsumption.value
          : this.fuelConsumption,
      fuelPricePerUnit: data.fuelPricePerUnit.present
          ? data.fuelPricePerUnit.value
          : this.fuelPricePerUnit,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      selectedMapTheme: data.selectedMapTheme.present
          ? data.selectedMapTheme.value
          : this.selectedMapTheme,
      freeTripsUsed: data.freeTripsUsed.present
          ? data.freeTripsUsed.value
          : this.freeTripsUsed,
      isPro: data.isPro.present ? data.isPro.value : this.isPro,
      onboardingComplete: data.onboardingComplete.present
          ? data.onboardingComplete.value
          : this.onboardingComplete,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsRow(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('username: $username, ')
          ..write('carMake: $carMake, ')
          ..write('carModel: $carModel, ')
          ..write('carYear: $carYear, ')
          ..write('carColour: $carColour, ')
          ..write('carPhotoPath: $carPhotoPath, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('country: $country, ')
          ..write('unitSystem: $unitSystem, ')
          ..write('fuelType: $fuelType, ')
          ..write('fuelConsumption: $fuelConsumption, ')
          ..write('fuelPricePerUnit: $fuelPricePerUnit, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('selectedMapTheme: $selectedMapTheme, ')
          ..write('freeTripsUsed: $freeTripsUsed, ')
          ..write('isPro: $isPro, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    username,
    carMake,
    carModel,
    carYear,
    carColour,
    carPhotoPath,
    vehicleType,
    country,
    unitSystem,
    fuelType,
    fuelConsumption,
    fuelPricePerUnit,
    currencyCode,
    selectedMapTheme,
    freeTripsUsed,
    isPro,
    onboardingComplete,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSettingsRow &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.username == this.username &&
          other.carMake == this.carMake &&
          other.carModel == this.carModel &&
          other.carYear == this.carYear &&
          other.carColour == this.carColour &&
          other.carPhotoPath == this.carPhotoPath &&
          other.vehicleType == this.vehicleType &&
          other.country == this.country &&
          other.unitSystem == this.unitSystem &&
          other.fuelType == this.fuelType &&
          other.fuelConsumption == this.fuelConsumption &&
          other.fuelPricePerUnit == this.fuelPricePerUnit &&
          other.currencyCode == this.currencyCode &&
          other.selectedMapTheme == this.selectedMapTheme &&
          other.freeTripsUsed == this.freeTripsUsed &&
          other.isPro == this.isPro &&
          other.onboardingComplete == this.onboardingComplete &&
          other.createdAt == this.createdAt);
}

class UserSettingsCompanion extends UpdateCompanion<UserSettingsRow> {
  final Value<int> id;
  final Value<String> uid;
  final Value<String> username;
  final Value<String> carMake;
  final Value<String> carModel;
  final Value<int?> carYear;
  final Value<String?> carColour;
  final Value<String?> carPhotoPath;
  final Value<String> vehicleType;
  final Value<String?> country;
  final Value<String> unitSystem;
  final Value<String?> fuelType;
  final Value<double?> fuelConsumption;
  final Value<double?> fuelPricePerUnit;
  final Value<String?> currencyCode;
  final Value<String> selectedMapTheme;
  final Value<int> freeTripsUsed;
  final Value<bool> isPro;
  final Value<bool> onboardingComplete;
  final Value<DateTime> createdAt;
  const UserSettingsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.username = const Value.absent(),
    this.carMake = const Value.absent(),
    this.carModel = const Value.absent(),
    this.carYear = const Value.absent(),
    this.carColour = const Value.absent(),
    this.carPhotoPath = const Value.absent(),
    this.vehicleType = const Value.absent(),
    this.country = const Value.absent(),
    this.unitSystem = const Value.absent(),
    this.fuelType = const Value.absent(),
    this.fuelConsumption = const Value.absent(),
    this.fuelPricePerUnit = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.selectedMapTheme = const Value.absent(),
    this.freeTripsUsed = const Value.absent(),
    this.isPro = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    this.username = const Value.absent(),
    this.carMake = const Value.absent(),
    this.carModel = const Value.absent(),
    this.carYear = const Value.absent(),
    this.carColour = const Value.absent(),
    this.carPhotoPath = const Value.absent(),
    this.vehicleType = const Value.absent(),
    this.country = const Value.absent(),
    this.unitSystem = const Value.absent(),
    this.fuelType = const Value.absent(),
    this.fuelConsumption = const Value.absent(),
    this.fuelPricePerUnit = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.selectedMapTheme = const Value.absent(),
    this.freeTripsUsed = const Value.absent(),
    this.isPro = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    required DateTime createdAt,
  }) : uid = Value(uid),
       createdAt = Value(createdAt);
  static Insertable<UserSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<String>? username,
    Expression<String>? carMake,
    Expression<String>? carModel,
    Expression<int>? carYear,
    Expression<String>? carColour,
    Expression<String>? carPhotoPath,
    Expression<String>? vehicleType,
    Expression<String>? country,
    Expression<String>? unitSystem,
    Expression<String>? fuelType,
    Expression<double>? fuelConsumption,
    Expression<double>? fuelPricePerUnit,
    Expression<String>? currencyCode,
    Expression<String>? selectedMapTheme,
    Expression<int>? freeTripsUsed,
    Expression<bool>? isPro,
    Expression<bool>? onboardingComplete,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (username != null) 'username': username,
      if (carMake != null) 'car_make': carMake,
      if (carModel != null) 'car_model': carModel,
      if (carYear != null) 'car_year': carYear,
      if (carColour != null) 'car_colour': carColour,
      if (carPhotoPath != null) 'car_photo_path': carPhotoPath,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (country != null) 'country': country,
      if (unitSystem != null) 'unit_system': unitSystem,
      if (fuelType != null) 'fuel_type': fuelType,
      if (fuelConsumption != null) 'fuel_consumption': fuelConsumption,
      if (fuelPricePerUnit != null) 'fuel_price_per_unit': fuelPricePerUnit,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (selectedMapTheme != null) 'selected_map_theme': selectedMapTheme,
      if (freeTripsUsed != null) 'free_trips_used': freeTripsUsed,
      if (isPro != null) 'is_pro': isPro,
      if (onboardingComplete != null) 'onboarding_complete': onboardingComplete,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<String>? username,
    Value<String>? carMake,
    Value<String>? carModel,
    Value<int?>? carYear,
    Value<String?>? carColour,
    Value<String?>? carPhotoPath,
    Value<String>? vehicleType,
    Value<String?>? country,
    Value<String>? unitSystem,
    Value<String?>? fuelType,
    Value<double?>? fuelConsumption,
    Value<double?>? fuelPricePerUnit,
    Value<String?>? currencyCode,
    Value<String>? selectedMapTheme,
    Value<int>? freeTripsUsed,
    Value<bool>? isPro,
    Value<bool>? onboardingComplete,
    Value<DateTime>? createdAt,
  }) {
    return UserSettingsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      carMake: carMake ?? this.carMake,
      carModel: carModel ?? this.carModel,
      carYear: carYear ?? this.carYear,
      carColour: carColour ?? this.carColour,
      carPhotoPath: carPhotoPath ?? this.carPhotoPath,
      vehicleType: vehicleType ?? this.vehicleType,
      country: country ?? this.country,
      unitSystem: unitSystem ?? this.unitSystem,
      fuelType: fuelType ?? this.fuelType,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      fuelPricePerUnit: fuelPricePerUnit ?? this.fuelPricePerUnit,
      currencyCode: currencyCode ?? this.currencyCode,
      selectedMapTheme: selectedMapTheme ?? this.selectedMapTheme,
      freeTripsUsed: freeTripsUsed ?? this.freeTripsUsed,
      isPro: isPro ?? this.isPro,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (carMake.present) {
      map['car_make'] = Variable<String>(carMake.value);
    }
    if (carModel.present) {
      map['car_model'] = Variable<String>(carModel.value);
    }
    if (carYear.present) {
      map['car_year'] = Variable<int>(carYear.value);
    }
    if (carColour.present) {
      map['car_colour'] = Variable<String>(carColour.value);
    }
    if (carPhotoPath.present) {
      map['car_photo_path'] = Variable<String>(carPhotoPath.value);
    }
    if (vehicleType.present) {
      map['vehicle_type'] = Variable<String>(vehicleType.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (unitSystem.present) {
      map['unit_system'] = Variable<String>(unitSystem.value);
    }
    if (fuelType.present) {
      map['fuel_type'] = Variable<String>(fuelType.value);
    }
    if (fuelConsumption.present) {
      map['fuel_consumption'] = Variable<double>(fuelConsumption.value);
    }
    if (fuelPricePerUnit.present) {
      map['fuel_price_per_unit'] = Variable<double>(fuelPricePerUnit.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (selectedMapTheme.present) {
      map['selected_map_theme'] = Variable<String>(selectedMapTheme.value);
    }
    if (freeTripsUsed.present) {
      map['free_trips_used'] = Variable<int>(freeTripsUsed.value);
    }
    if (isPro.present) {
      map['is_pro'] = Variable<bool>(isPro.value);
    }
    if (onboardingComplete.present) {
      map['onboarding_complete'] = Variable<bool>(onboardingComplete.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('username: $username, ')
          ..write('carMake: $carMake, ')
          ..write('carModel: $carModel, ')
          ..write('carYear: $carYear, ')
          ..write('carColour: $carColour, ')
          ..write('carPhotoPath: $carPhotoPath, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('country: $country, ')
          ..write('unitSystem: $unitSystem, ')
          ..write('fuelType: $fuelType, ')
          ..write('fuelConsumption: $fuelConsumption, ')
          ..write('fuelPricePerUnit: $fuelPricePerUnit, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('selectedMapTheme: $selectedMapTheme, ')
          ..write('freeTripsUsed: $freeTripsUsed, ')
          ..write('isPro: $isPro, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $WaypointsTable waypoints = $WaypointsTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trips,
    waypoints,
    userSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'trips',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('waypoints', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TripsTableCreateCompanionBuilder =
    TripsCompanion Function({
      Value<int> id,
      required String uid,
      required double topSpeedKmh,
      required double avgSpeedKmh,
      required double distanceKm,
      required int durationSeconds,
      Value<int> stoppedSeconds,
      Value<double> maxGforce,
      Value<int> hardCornersCount,
      Value<int> hardBrakesCount,
      Value<double?> fuelCostLocal,
      Value<String?> localCurrencyCode,
      Value<String?> weatherCondition,
      Value<double?> weatherTempC,
      Value<bool> isNightDrive,
      Value<String> mapTheme,
      Value<String?> country,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<bool> isSynced,
    });
typedef $$TripsTableUpdateCompanionBuilder =
    TripsCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<double> topSpeedKmh,
      Value<double> avgSpeedKmh,
      Value<double> distanceKm,
      Value<int> durationSeconds,
      Value<int> stoppedSeconds,
      Value<double> maxGforce,
      Value<int> hardCornersCount,
      Value<int> hardBrakesCount,
      Value<double?> fuelCostLocal,
      Value<String?> localCurrencyCode,
      Value<String?> weatherCondition,
      Value<double?> weatherTempC,
      Value<bool> isNightDrive,
      Value<String> mapTheme,
      Value<String?> country,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<bool> isSynced,
    });

final class $$TripsTableReferences
    extends BaseReferences<_$AppDatabase, $TripsTable, TripRow> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WaypointsTable, List<WaypointRow>>
  _waypointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.waypoints,
    aliasName: $_aliasNameGenerator(db.trips.id, db.waypoints.tripId),
  );

  $$WaypointsTableProcessedTableManager get waypointsRefs {
    final manager = $$WaypointsTableTableManager(
      $_db,
      $_db.waypoints,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_waypointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get topSpeedKmh => $composableBuilder(
    column: $table.topSpeedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgSpeedKmh => $composableBuilder(
    column: $table.avgSpeedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stoppedSeconds => $composableBuilder(
    column: $table.stoppedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxGforce => $composableBuilder(
    column: $table.maxGforce,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hardCornersCount => $composableBuilder(
    column: $table.hardCornersCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hardBrakesCount => $composableBuilder(
    column: $table.hardBrakesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fuelCostLocal => $composableBuilder(
    column: $table.fuelCostLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localCurrencyCode => $composableBuilder(
    column: $table.localCurrencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weatherCondition => $composableBuilder(
    column: $table.weatherCondition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weatherTempC => $composableBuilder(
    column: $table.weatherTempC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNightDrive => $composableBuilder(
    column: $table.isNightDrive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mapTheme => $composableBuilder(
    column: $table.mapTheme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
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

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> waypointsRefs(
    Expression<bool> Function($$WaypointsTableFilterComposer f) f,
  ) {
    final $$WaypointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.waypoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaypointsTableFilterComposer(
            $db: $db,
            $table: $db.waypoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get topSpeedKmh => $composableBuilder(
    column: $table.topSpeedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgSpeedKmh => $composableBuilder(
    column: $table.avgSpeedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stoppedSeconds => $composableBuilder(
    column: $table.stoppedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxGforce => $composableBuilder(
    column: $table.maxGforce,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hardCornersCount => $composableBuilder(
    column: $table.hardCornersCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hardBrakesCount => $composableBuilder(
    column: $table.hardBrakesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fuelCostLocal => $composableBuilder(
    column: $table.fuelCostLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localCurrencyCode => $composableBuilder(
    column: $table.localCurrencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weatherCondition => $composableBuilder(
    column: $table.weatherCondition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weatherTempC => $composableBuilder(
    column: $table.weatherTempC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNightDrive => $composableBuilder(
    column: $table.isNightDrive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mapTheme => $composableBuilder(
    column: $table.mapTheme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
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

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<double> get topSpeedKmh => $composableBuilder(
    column: $table.topSpeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgSpeedKmh => $composableBuilder(
    column: $table.avgSpeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stoppedSeconds => $composableBuilder(
    column: $table.stoppedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxGforce =>
      $composableBuilder(column: $table.maxGforce, builder: (column) => column);

  GeneratedColumn<int> get hardCornersCount => $composableBuilder(
    column: $table.hardCornersCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hardBrakesCount => $composableBuilder(
    column: $table.hardBrakesCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fuelCostLocal => $composableBuilder(
    column: $table.fuelCostLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localCurrencyCode => $composableBuilder(
    column: $table.localCurrencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weatherCondition => $composableBuilder(
    column: $table.weatherCondition,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weatherTempC => $composableBuilder(
    column: $table.weatherTempC,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isNightDrive => $composableBuilder(
    column: $table.isNightDrive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mapTheme =>
      $composableBuilder(column: $table.mapTheme, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  Expression<T> waypointsRefs<T extends Object>(
    Expression<T> Function($$WaypointsTableAnnotationComposer a) f,
  ) {
    final $$WaypointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.waypoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaypointsTableAnnotationComposer(
            $db: $db,
            $table: $db.waypoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          TripRow,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (TripRow, $$TripsTableReferences),
          TripRow,
          PrefetchHooks Function({bool waypointsRefs})
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<double> topSpeedKmh = const Value.absent(),
                Value<double> avgSpeedKmh = const Value.absent(),
                Value<double> distanceKm = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int> stoppedSeconds = const Value.absent(),
                Value<double> maxGforce = const Value.absent(),
                Value<int> hardCornersCount = const Value.absent(),
                Value<int> hardBrakesCount = const Value.absent(),
                Value<double?> fuelCostLocal = const Value.absent(),
                Value<String?> localCurrencyCode = const Value.absent(),
                Value<String?> weatherCondition = const Value.absent(),
                Value<double?> weatherTempC = const Value.absent(),
                Value<bool> isNightDrive = const Value.absent(),
                Value<String> mapTheme = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                uid: uid,
                topSpeedKmh: topSpeedKmh,
                avgSpeedKmh: avgSpeedKmh,
                distanceKm: distanceKm,
                durationSeconds: durationSeconds,
                stoppedSeconds: stoppedSeconds,
                maxGforce: maxGforce,
                hardCornersCount: hardCornersCount,
                hardBrakesCount: hardBrakesCount,
                fuelCostLocal: fuelCostLocal,
                localCurrencyCode: localCurrencyCode,
                weatherCondition: weatherCondition,
                weatherTempC: weatherTempC,
                isNightDrive: isNightDrive,
                mapTheme: mapTheme,
                country: country,
                startedAt: startedAt,
                endedAt: endedAt,
                isSynced: isSynced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                required double topSpeedKmh,
                required double avgSpeedKmh,
                required double distanceKm,
                required int durationSeconds,
                Value<int> stoppedSeconds = const Value.absent(),
                Value<double> maxGforce = const Value.absent(),
                Value<int> hardCornersCount = const Value.absent(),
                Value<int> hardBrakesCount = const Value.absent(),
                Value<double?> fuelCostLocal = const Value.absent(),
                Value<String?> localCurrencyCode = const Value.absent(),
                Value<String?> weatherCondition = const Value.absent(),
                Value<double?> weatherTempC = const Value.absent(),
                Value<bool> isNightDrive = const Value.absent(),
                Value<String> mapTheme = const Value.absent(),
                Value<String?> country = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => TripsCompanion.insert(
                id: id,
                uid: uid,
                topSpeedKmh: topSpeedKmh,
                avgSpeedKmh: avgSpeedKmh,
                distanceKm: distanceKm,
                durationSeconds: durationSeconds,
                stoppedSeconds: stoppedSeconds,
                maxGforce: maxGforce,
                hardCornersCount: hardCornersCount,
                hardBrakesCount: hardBrakesCount,
                fuelCostLocal: fuelCostLocal,
                localCurrencyCode: localCurrencyCode,
                weatherCondition: weatherCondition,
                weatherTempC: weatherTempC,
                isNightDrive: isNightDrive,
                mapTheme: mapTheme,
                country: country,
                startedAt: startedAt,
                endedAt: endedAt,
                isSynced: isSynced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TripsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({waypointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (waypointsRefs) db.waypoints],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (waypointsRefs)
                    await $_getPrefetchedData<
                      TripRow,
                      $TripsTable,
                      WaypointRow
                    >(
                      currentTable: table,
                      referencedTable: $$TripsTableReferences
                          ._waypointsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TripsTableReferences(db, table, p0).waypointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tripId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      TripRow,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (TripRow, $$TripsTableReferences),
      TripRow,
      PrefetchHooks Function({bool waypointsRefs})
    >;
typedef $$WaypointsTableCreateCompanionBuilder =
    WaypointsCompanion Function({
      Value<int> id,
      required int tripId,
      required double lat,
      required double lng,
      required double speedKmh,
      required double accuracyMeters,
      required DateTime timestamp,
    });
typedef $$WaypointsTableUpdateCompanionBuilder =
    WaypointsCompanion Function({
      Value<int> id,
      Value<int> tripId,
      Value<double> lat,
      Value<double> lng,
      Value<double> speedKmh,
      Value<double> accuracyMeters,
      Value<DateTime> timestamp,
    });

final class $$WaypointsTableReferences
    extends BaseReferences<_$AppDatabase, $WaypointsTable, WaypointRow> {
  $$WaypointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips.createAlias(
    $_aliasNameGenerator(db.waypoints.tripId, db.trips.id),
  );

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<int>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WaypointsTableFilterComposer
    extends Composer<_$AppDatabase, $WaypointsTable> {
  $$WaypointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedKmh => $composableBuilder(
    column: $table.speedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaypointsTableOrderingComposer
    extends Composer<_$AppDatabase, $WaypointsTable> {
  $$WaypointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedKmh => $composableBuilder(
    column: $table.speedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaypointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaypointsTable> {
  $$WaypointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get speedKmh =>
      $composableBuilder(column: $table.speedKmh, builder: (column) => column);

  GeneratedColumn<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaypointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaypointsTable,
          WaypointRow,
          $$WaypointsTableFilterComposer,
          $$WaypointsTableOrderingComposer,
          $$WaypointsTableAnnotationComposer,
          $$WaypointsTableCreateCompanionBuilder,
          $$WaypointsTableUpdateCompanionBuilder,
          (WaypointRow, $$WaypointsTableReferences),
          WaypointRow,
          PrefetchHooks Function({bool tripId})
        > {
  $$WaypointsTableTableManager(_$AppDatabase db, $WaypointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaypointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaypointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaypointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> tripId = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double> speedKmh = const Value.absent(),
                Value<double> accuracyMeters = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => WaypointsCompanion(
                id: id,
                tripId: tripId,
                lat: lat,
                lng: lng,
                speedKmh: speedKmh,
                accuracyMeters: accuracyMeters,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tripId,
                required double lat,
                required double lng,
                required double speedKmh,
                required double accuracyMeters,
                required DateTime timestamp,
              }) => WaypointsCompanion.insert(
                id: id,
                tripId: tripId,
                lat: lat,
                lng: lng,
                speedKmh: speedKmh,
                accuracyMeters: accuracyMeters,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WaypointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false}) {
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
                    if (tripId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tripId,
                                referencedTable: $$WaypointsTableReferences
                                    ._tripIdTable(db),
                                referencedColumn: $$WaypointsTableReferences
                                    ._tripIdTable(db)
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

typedef $$WaypointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaypointsTable,
      WaypointRow,
      $$WaypointsTableFilterComposer,
      $$WaypointsTableOrderingComposer,
      $$WaypointsTableAnnotationComposer,
      $$WaypointsTableCreateCompanionBuilder,
      $$WaypointsTableUpdateCompanionBuilder,
      (WaypointRow, $$WaypointsTableReferences),
      WaypointRow,
      PrefetchHooks Function({bool tripId})
    >;
typedef $$UserSettingsTableCreateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      required String uid,
      Value<String> username,
      Value<String> carMake,
      Value<String> carModel,
      Value<int?> carYear,
      Value<String?> carColour,
      Value<String?> carPhotoPath,
      Value<String> vehicleType,
      Value<String?> country,
      Value<String> unitSystem,
      Value<String?> fuelType,
      Value<double?> fuelConsumption,
      Value<double?> fuelPricePerUnit,
      Value<String?> currencyCode,
      Value<String> selectedMapTheme,
      Value<int> freeTripsUsed,
      Value<bool> isPro,
      Value<bool> onboardingComplete,
      required DateTime createdAt,
    });
typedef $$UserSettingsTableUpdateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<String> username,
      Value<String> carMake,
      Value<String> carModel,
      Value<int?> carYear,
      Value<String?> carColour,
      Value<String?> carPhotoPath,
      Value<String> vehicleType,
      Value<String?> country,
      Value<String> unitSystem,
      Value<String?> fuelType,
      Value<double?> fuelConsumption,
      Value<double?> fuelPricePerUnit,
      Value<String?> currencyCode,
      Value<String> selectedMapTheme,
      Value<int> freeTripsUsed,
      Value<bool> isPro,
      Value<bool> onboardingComplete,
      Value<DateTime> createdAt,
    });

class $$UserSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carMake => $composableBuilder(
    column: $table.carMake,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carModel => $composableBuilder(
    column: $table.carModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carYear => $composableBuilder(
    column: $table.carYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carColour => $composableBuilder(
    column: $table.carColour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carPhotoPath => $composableBuilder(
    column: $table.carPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitSystem => $composableBuilder(
    column: $table.unitSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fuelConsumption => $composableBuilder(
    column: $table.fuelConsumption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fuelPricePerUnit => $composableBuilder(
    column: $table.fuelPricePerUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedMapTheme => $composableBuilder(
    column: $table.selectedMapTheme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freeTripsUsed => $composableBuilder(
    column: $table.freeTripsUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPro => $composableBuilder(
    column: $table.isPro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carMake => $composableBuilder(
    column: $table.carMake,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carModel => $composableBuilder(
    column: $table.carModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carYear => $composableBuilder(
    column: $table.carYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carColour => $composableBuilder(
    column: $table.carColour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carPhotoPath => $composableBuilder(
    column: $table.carPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitSystem => $composableBuilder(
    column: $table.unitSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fuelConsumption => $composableBuilder(
    column: $table.fuelConsumption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fuelPricePerUnit => $composableBuilder(
    column: $table.fuelPricePerUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedMapTheme => $composableBuilder(
    column: $table.selectedMapTheme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freeTripsUsed => $composableBuilder(
    column: $table.freeTripsUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPro => $composableBuilder(
    column: $table.isPro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get carMake =>
      $composableBuilder(column: $table.carMake, builder: (column) => column);

  GeneratedColumn<String> get carModel =>
      $composableBuilder(column: $table.carModel, builder: (column) => column);

  GeneratedColumn<int> get carYear =>
      $composableBuilder(column: $table.carYear, builder: (column) => column);

  GeneratedColumn<String> get carColour =>
      $composableBuilder(column: $table.carColour, builder: (column) => column);

  GeneratedColumn<String> get carPhotoPath => $composableBuilder(
    column: $table.carPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get unitSystem => $composableBuilder(
    column: $table.unitSystem,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fuelType =>
      $composableBuilder(column: $table.fuelType, builder: (column) => column);

  GeneratedColumn<double> get fuelConsumption => $composableBuilder(
    column: $table.fuelConsumption,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fuelPricePerUnit => $composableBuilder(
    column: $table.fuelPricePerUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedMapTheme => $composableBuilder(
    column: $table.selectedMapTheme,
    builder: (column) => column,
  );

  GeneratedColumn<int> get freeTripsUsed => $composableBuilder(
    column: $table.freeTripsUsed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPro =>
      $composableBuilder(column: $table.isPro, builder: (column) => column);

  GeneratedColumn<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTable,
          UserSettingsRow,
          $$UserSettingsTableFilterComposer,
          $$UserSettingsTableOrderingComposer,
          $$UserSettingsTableAnnotationComposer,
          $$UserSettingsTableCreateCompanionBuilder,
          $$UserSettingsTableUpdateCompanionBuilder,
          (
            UserSettingsRow,
            BaseReferences<_$AppDatabase, $UserSettingsTable, UserSettingsRow>,
          ),
          UserSettingsRow,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableManager(_$AppDatabase db, $UserSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> carMake = const Value.absent(),
                Value<String> carModel = const Value.absent(),
                Value<int?> carYear = const Value.absent(),
                Value<String?> carColour = const Value.absent(),
                Value<String?> carPhotoPath = const Value.absent(),
                Value<String> vehicleType = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String> unitSystem = const Value.absent(),
                Value<String?> fuelType = const Value.absent(),
                Value<double?> fuelConsumption = const Value.absent(),
                Value<double?> fuelPricePerUnit = const Value.absent(),
                Value<String?> currencyCode = const Value.absent(),
                Value<String> selectedMapTheme = const Value.absent(),
                Value<int> freeTripsUsed = const Value.absent(),
                Value<bool> isPro = const Value.absent(),
                Value<bool> onboardingComplete = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserSettingsCompanion(
                id: id,
                uid: uid,
                username: username,
                carMake: carMake,
                carModel: carModel,
                carYear: carYear,
                carColour: carColour,
                carPhotoPath: carPhotoPath,
                vehicleType: vehicleType,
                country: country,
                unitSystem: unitSystem,
                fuelType: fuelType,
                fuelConsumption: fuelConsumption,
                fuelPricePerUnit: fuelPricePerUnit,
                currencyCode: currencyCode,
                selectedMapTheme: selectedMapTheme,
                freeTripsUsed: freeTripsUsed,
                isPro: isPro,
                onboardingComplete: onboardingComplete,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                Value<String> username = const Value.absent(),
                Value<String> carMake = const Value.absent(),
                Value<String> carModel = const Value.absent(),
                Value<int?> carYear = const Value.absent(),
                Value<String?> carColour = const Value.absent(),
                Value<String?> carPhotoPath = const Value.absent(),
                Value<String> vehicleType = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String> unitSystem = const Value.absent(),
                Value<String?> fuelType = const Value.absent(),
                Value<double?> fuelConsumption = const Value.absent(),
                Value<double?> fuelPricePerUnit = const Value.absent(),
                Value<String?> currencyCode = const Value.absent(),
                Value<String> selectedMapTheme = const Value.absent(),
                Value<int> freeTripsUsed = const Value.absent(),
                Value<bool> isPro = const Value.absent(),
                Value<bool> onboardingComplete = const Value.absent(),
                required DateTime createdAt,
              }) => UserSettingsCompanion.insert(
                id: id,
                uid: uid,
                username: username,
                carMake: carMake,
                carModel: carModel,
                carYear: carYear,
                carColour: carColour,
                carPhotoPath: carPhotoPath,
                vehicleType: vehicleType,
                country: country,
                unitSystem: unitSystem,
                fuelType: fuelType,
                fuelConsumption: fuelConsumption,
                fuelPricePerUnit: fuelPricePerUnit,
                currencyCode: currencyCode,
                selectedMapTheme: selectedMapTheme,
                freeTripsUsed: freeTripsUsed,
                isPro: isPro,
                onboardingComplete: onboardingComplete,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTable,
      UserSettingsRow,
      $$UserSettingsTableFilterComposer,
      $$UserSettingsTableOrderingComposer,
      $$UserSettingsTableAnnotationComposer,
      $$UserSettingsTableCreateCompanionBuilder,
      $$UserSettingsTableUpdateCompanionBuilder,
      (
        UserSettingsRow,
        BaseReferences<_$AppDatabase, $UserSettingsTable, UserSettingsRow>,
      ),
      UserSettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$WaypointsTableTableManager get waypoints =>
      $$WaypointsTableTableManager(_db, _db.waypoints);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
}
