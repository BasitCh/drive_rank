// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_app_database_v10.dart';

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
  static const VerificationMeta _stopCountMeta = const VerificationMeta(
    'stopCount',
  );
  @override
  late final GeneratedColumn<int> stopCount = GeneratedColumn<int>(
    'stop_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _elevationGainMetersMeta =
      const VerificationMeta('elevationGainMeters');
  @override
  late final GeneratedColumn<double> elevationGainMeters =
      GeneratedColumn<double>(
        'elevation_gain_meters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _maxElevationMetersMeta =
      const VerificationMeta('maxElevationMeters');
  @override
  late final GeneratedColumn<double> maxElevationMeters =
      GeneratedColumn<double>(
        'max_elevation_meters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
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
  static const VerificationMeta _leftTurnCountMeta = const VerificationMeta(
    'leftTurnCount',
  );
  @override
  late final GeneratedColumn<int> leftTurnCount = GeneratedColumn<int>(
    'left_turn_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rightTurnCountMeta = const VerificationMeta(
    'rightTurnCount',
  );
  @override
  late final GeneratedColumn<int> rightTurnCount = GeneratedColumn<int>(
    'right_turn_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _laneChangeCountMeta = const VerificationMeta(
    'laneChangeCount',
  );
  @override
  late final GeneratedColumn<int> laneChangeCount = GeneratedColumn<int>(
    'lane_change_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxAccelerationMps2Meta =
      const VerificationMeta('maxAccelerationMps2');
  @override
  late final GeneratedColumn<double> maxAccelerationMps2 =
      GeneratedColumn<double>(
        'max_acceleration_mps2',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _maxDecelerationMps2Meta =
      const VerificationMeta('maxDecelerationMps2');
  @override
  late final GeneratedColumn<double> maxDecelerationMps2 =
      GeneratedColumn<double>(
        'max_deceleration_mps2',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _topCorneringSpeedKmhMeta =
      const VerificationMeta('topCorneringSpeedKmh');
  @override
  late final GeneratedColumn<double> topCorneringSpeedKmh =
      GeneratedColumn<double>(
        'top_cornering_speed_kmh',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _zeroToHundredSecondsMeta =
      const VerificationMeta('zeroToHundredSeconds');
  @override
  late final GeneratedColumn<double> zeroToHundredSeconds =
      GeneratedColumn<double>(
        'zero_to_hundred_seconds',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
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
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roadSegmentIdsMeta = const VerificationMeta(
    'roadSegmentIds',
  );
  @override
  late final GeneratedColumn<String> roadSegmentIds = GeneratedColumn<String>(
    'road_segment_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    stopCount,
    elevationGainMeters,
    maxElevationMeters,
    maxGforce,
    hardCornersCount,
    hardBrakesCount,
    leftTurnCount,
    rightTurnCount,
    laneChangeCount,
    maxAccelerationMps2,
    maxDecelerationMps2,
    topCorneringSpeedKmh,
    zeroToHundredSeconds,
    fuelCostLocal,
    localCurrencyCode,
    weatherCondition,
    weatherTempC,
    isNightDrive,
    mapTheme,
    country,
    locationName,
    roadSegmentIds,
    startedAt,
    endedAt,
    isSynced,
    remoteId,
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
    if (data.containsKey('stop_count')) {
      context.handle(
        _stopCountMeta,
        stopCount.isAcceptableOrUnknown(data['stop_count']!, _stopCountMeta),
      );
    }
    if (data.containsKey('elevation_gain_meters')) {
      context.handle(
        _elevationGainMetersMeta,
        elevationGainMeters.isAcceptableOrUnknown(
          data['elevation_gain_meters']!,
          _elevationGainMetersMeta,
        ),
      );
    }
    if (data.containsKey('max_elevation_meters')) {
      context.handle(
        _maxElevationMetersMeta,
        maxElevationMeters.isAcceptableOrUnknown(
          data['max_elevation_meters']!,
          _maxElevationMetersMeta,
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
    if (data.containsKey('left_turn_count')) {
      context.handle(
        _leftTurnCountMeta,
        leftTurnCount.isAcceptableOrUnknown(
          data['left_turn_count']!,
          _leftTurnCountMeta,
        ),
      );
    }
    if (data.containsKey('right_turn_count')) {
      context.handle(
        _rightTurnCountMeta,
        rightTurnCount.isAcceptableOrUnknown(
          data['right_turn_count']!,
          _rightTurnCountMeta,
        ),
      );
    }
    if (data.containsKey('lane_change_count')) {
      context.handle(
        _laneChangeCountMeta,
        laneChangeCount.isAcceptableOrUnknown(
          data['lane_change_count']!,
          _laneChangeCountMeta,
        ),
      );
    }
    if (data.containsKey('max_acceleration_mps2')) {
      context.handle(
        _maxAccelerationMps2Meta,
        maxAccelerationMps2.isAcceptableOrUnknown(
          data['max_acceleration_mps2']!,
          _maxAccelerationMps2Meta,
        ),
      );
    }
    if (data.containsKey('max_deceleration_mps2')) {
      context.handle(
        _maxDecelerationMps2Meta,
        maxDecelerationMps2.isAcceptableOrUnknown(
          data['max_deceleration_mps2']!,
          _maxDecelerationMps2Meta,
        ),
      );
    }
    if (data.containsKey('top_cornering_speed_kmh')) {
      context.handle(
        _topCorneringSpeedKmhMeta,
        topCorneringSpeedKmh.isAcceptableOrUnknown(
          data['top_cornering_speed_kmh']!,
          _topCorneringSpeedKmhMeta,
        ),
      );
    }
    if (data.containsKey('zero_to_hundred_seconds')) {
      context.handle(
        _zeroToHundredSecondsMeta,
        zeroToHundredSeconds.isAcceptableOrUnknown(
          data['zero_to_hundred_seconds']!,
          _zeroToHundredSecondsMeta,
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
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('road_segment_ids')) {
      context.handle(
        _roadSegmentIdsMeta,
        roadSegmentIds.isAcceptableOrUnknown(
          data['road_segment_ids']!,
          _roadSegmentIdsMeta,
        ),
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
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
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
      stopCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stop_count'],
      )!,
      elevationGainMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_gain_meters'],
      ),
      maxElevationMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_elevation_meters'],
      ),
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
      leftTurnCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}left_turn_count'],
      )!,
      rightTurnCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}right_turn_count'],
      )!,
      laneChangeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lane_change_count'],
      )!,
      maxAccelerationMps2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_acceleration_mps2'],
      )!,
      maxDecelerationMps2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_deceleration_mps2'],
      )!,
      topCorneringSpeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}top_cornering_speed_kmh'],
      )!,
      zeroToHundredSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}zero_to_hundred_seconds'],
      ),
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
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      ),
      roadSegmentIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}road_segment_ids'],
      )!,
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
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
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
  final int stopCount;

  /// Sum of positive altitude deltas between consecutive waypoints.
  /// Null when the trip has no reliable altitude samples.
  final double? elevationGainMeters;

  /// Highest altitude reached during the trip. Null when the trip has
  /// no reliable altitude samples.
  final double? maxElevationMeters;
  final double maxGforce;
  final int hardCornersCount;
  final int hardBrakesCount;

  /// Heading-based turn-direction counts — additive to, not a
  /// replacement for, the g-force-based `hardCornersCount` above (that
  /// stays exactly as-is; this is a separate, direction-aware signal).
  /// See `AppConstants.turnHeadingDeltaThresholdDeg`.
  final int leftTurnCount;
  final int rightTurnCount;

  /// Heuristic lane-change count — see `AppConstants.laneChangeHeadingDeltaMinDeg`.
  final int laneChangeCount;

  /// Peak acceleration/deceleration (m/s²), derived from Δspeed/Δt —
  /// not the accelerometer. See `AppConstants.maxPlausibleAccelMps2`.
  final double maxAccelerationMps2;
  final double maxDecelerationMps2;

  /// Fastest speed recorded at the instant of any detected turn
  /// (left or right).
  final double topCorneringSpeedKmh;

  /// Fastest 0→100 km/h run, persisted once at save time so lifetime
  /// "best 0-100" aggregation doesn't need to re-walk every trip's
  /// waypoints. Null when the trip never reached 100 km/h from a
  /// standstill. See `zeroToHundredSeconds` in
  /// `lib/features/trip_insights/domain/usecases/zero_to_hundred.dart`.
  final double? zeroToHundredSeconds;

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

  /// Reverse-geocoded, human-readable place name for the trip's start
  /// coordinates (e.g. "Bahawalpur District, Pakistan") — resolved
  /// once on save via `GeocodingService` and cached here since it's an
  /// on-device OS lookup, not free to redo on every card render. Null
  /// when geocoding failed or was unavailable; the card footer falls
  /// back to the date alone in that case, never a placeholder string.
  final String? locationName;

  /// Comma-separated road-segment ids the trip's bounding box overlapped
  /// at save time (e.g. `nurburgring_nordschleife,m25_london`). Empty when
  /// the trip touched no known segment. We denormalise instead of using a
  /// join table because the v1 leaderboard query is "find me a trip's
  /// segments", not "find me all trips on a segment" — and the comma list
  /// loads with the row, no extra query.
  final String roadSegmentIds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isSynced;

  /// Stable UUID used as the Firestore document id for cloud sync,
  /// decoupled from the local autoincrement primary key so two devices
  /// restoring/pushing under the same account can't collide on the same
  /// path. Nullable — pre-existing trips get one lazily the first time
  /// they're pushed; new trips get one unconditionally at save time.
  final String? remoteId;
  const TripRow({
    required this.id,
    required this.uid,
    required this.topSpeedKmh,
    required this.avgSpeedKmh,
    required this.distanceKm,
    required this.durationSeconds,
    required this.stoppedSeconds,
    required this.stopCount,
    this.elevationGainMeters,
    this.maxElevationMeters,
    required this.maxGforce,
    required this.hardCornersCount,
    required this.hardBrakesCount,
    required this.leftTurnCount,
    required this.rightTurnCount,
    required this.laneChangeCount,
    required this.maxAccelerationMps2,
    required this.maxDecelerationMps2,
    required this.topCorneringSpeedKmh,
    this.zeroToHundredSeconds,
    this.fuelCostLocal,
    this.localCurrencyCode,
    this.weatherCondition,
    this.weatherTempC,
    required this.isNightDrive,
    required this.mapTheme,
    this.country,
    this.locationName,
    required this.roadSegmentIds,
    required this.startedAt,
    this.endedAt,
    required this.isSynced,
    this.remoteId,
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
    map['stop_count'] = Variable<int>(stopCount);
    if (!nullToAbsent || elevationGainMeters != null) {
      map['elevation_gain_meters'] = Variable<double>(elevationGainMeters);
    }
    if (!nullToAbsent || maxElevationMeters != null) {
      map['max_elevation_meters'] = Variable<double>(maxElevationMeters);
    }
    map['max_gforce'] = Variable<double>(maxGforce);
    map['hard_corners_count'] = Variable<int>(hardCornersCount);
    map['hard_brakes_count'] = Variable<int>(hardBrakesCount);
    map['left_turn_count'] = Variable<int>(leftTurnCount);
    map['right_turn_count'] = Variable<int>(rightTurnCount);
    map['lane_change_count'] = Variable<int>(laneChangeCount);
    map['max_acceleration_mps2'] = Variable<double>(maxAccelerationMps2);
    map['max_deceleration_mps2'] = Variable<double>(maxDecelerationMps2);
    map['top_cornering_speed_kmh'] = Variable<double>(topCorneringSpeedKmh);
    if (!nullToAbsent || zeroToHundredSeconds != null) {
      map['zero_to_hundred_seconds'] = Variable<double>(zeroToHundredSeconds);
    }
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
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    map['road_segment_ids'] = Variable<String>(roadSegmentIds);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
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
      stopCount: Value(stopCount),
      elevationGainMeters: elevationGainMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(elevationGainMeters),
      maxElevationMeters: maxElevationMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(maxElevationMeters),
      maxGforce: Value(maxGforce),
      hardCornersCount: Value(hardCornersCount),
      hardBrakesCount: Value(hardBrakesCount),
      leftTurnCount: Value(leftTurnCount),
      rightTurnCount: Value(rightTurnCount),
      laneChangeCount: Value(laneChangeCount),
      maxAccelerationMps2: Value(maxAccelerationMps2),
      maxDecelerationMps2: Value(maxDecelerationMps2),
      topCorneringSpeedKmh: Value(topCorneringSpeedKmh),
      zeroToHundredSeconds: zeroToHundredSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(zeroToHundredSeconds),
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
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      roadSegmentIds: Value(roadSegmentIds),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      isSynced: Value(isSynced),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
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
      stopCount: serializer.fromJson<int>(json['stopCount']),
      elevationGainMeters: serializer.fromJson<double?>(
        json['elevationGainMeters'],
      ),
      maxElevationMeters: serializer.fromJson<double?>(
        json['maxElevationMeters'],
      ),
      maxGforce: serializer.fromJson<double>(json['maxGforce']),
      hardCornersCount: serializer.fromJson<int>(json['hardCornersCount']),
      hardBrakesCount: serializer.fromJson<int>(json['hardBrakesCount']),
      leftTurnCount: serializer.fromJson<int>(json['leftTurnCount']),
      rightTurnCount: serializer.fromJson<int>(json['rightTurnCount']),
      laneChangeCount: serializer.fromJson<int>(json['laneChangeCount']),
      maxAccelerationMps2: serializer.fromJson<double>(
        json['maxAccelerationMps2'],
      ),
      maxDecelerationMps2: serializer.fromJson<double>(
        json['maxDecelerationMps2'],
      ),
      topCorneringSpeedKmh: serializer.fromJson<double>(
        json['topCorneringSpeedKmh'],
      ),
      zeroToHundredSeconds: serializer.fromJson<double?>(
        json['zeroToHundredSeconds'],
      ),
      fuelCostLocal: serializer.fromJson<double?>(json['fuelCostLocal']),
      localCurrencyCode: serializer.fromJson<String?>(
        json['localCurrencyCode'],
      ),
      weatherCondition: serializer.fromJson<String?>(json['weatherCondition']),
      weatherTempC: serializer.fromJson<double?>(json['weatherTempC']),
      isNightDrive: serializer.fromJson<bool>(json['isNightDrive']),
      mapTheme: serializer.fromJson<String>(json['mapTheme']),
      country: serializer.fromJson<String?>(json['country']),
      locationName: serializer.fromJson<String?>(json['locationName']),
      roadSegmentIds: serializer.fromJson<String>(json['roadSegmentIds']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
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
      'stopCount': serializer.toJson<int>(stopCount),
      'elevationGainMeters': serializer.toJson<double?>(elevationGainMeters),
      'maxElevationMeters': serializer.toJson<double?>(maxElevationMeters),
      'maxGforce': serializer.toJson<double>(maxGforce),
      'hardCornersCount': serializer.toJson<int>(hardCornersCount),
      'hardBrakesCount': serializer.toJson<int>(hardBrakesCount),
      'leftTurnCount': serializer.toJson<int>(leftTurnCount),
      'rightTurnCount': serializer.toJson<int>(rightTurnCount),
      'laneChangeCount': serializer.toJson<int>(laneChangeCount),
      'maxAccelerationMps2': serializer.toJson<double>(maxAccelerationMps2),
      'maxDecelerationMps2': serializer.toJson<double>(maxDecelerationMps2),
      'topCorneringSpeedKmh': serializer.toJson<double>(topCorneringSpeedKmh),
      'zeroToHundredSeconds': serializer.toJson<double?>(zeroToHundredSeconds),
      'fuelCostLocal': serializer.toJson<double?>(fuelCostLocal),
      'localCurrencyCode': serializer.toJson<String?>(localCurrencyCode),
      'weatherCondition': serializer.toJson<String?>(weatherCondition),
      'weatherTempC': serializer.toJson<double?>(weatherTempC),
      'isNightDrive': serializer.toJson<bool>(isNightDrive),
      'mapTheme': serializer.toJson<String>(mapTheme),
      'country': serializer.toJson<String?>(country),
      'locationName': serializer.toJson<String?>(locationName),
      'roadSegmentIds': serializer.toJson<String>(roadSegmentIds),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'remoteId': serializer.toJson<String?>(remoteId),
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
    int? stopCount,
    Value<double?> elevationGainMeters = const Value.absent(),
    Value<double?> maxElevationMeters = const Value.absent(),
    double? maxGforce,
    int? hardCornersCount,
    int? hardBrakesCount,
    int? leftTurnCount,
    int? rightTurnCount,
    int? laneChangeCount,
    double? maxAccelerationMps2,
    double? maxDecelerationMps2,
    double? topCorneringSpeedKmh,
    Value<double?> zeroToHundredSeconds = const Value.absent(),
    Value<double?> fuelCostLocal = const Value.absent(),
    Value<String?> localCurrencyCode = const Value.absent(),
    Value<String?> weatherCondition = const Value.absent(),
    Value<double?> weatherTempC = const Value.absent(),
    bool? isNightDrive,
    String? mapTheme,
    Value<String?> country = const Value.absent(),
    Value<String?> locationName = const Value.absent(),
    String? roadSegmentIds,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    bool? isSynced,
    Value<String?> remoteId = const Value.absent(),
  }) => TripRow(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    topSpeedKmh: topSpeedKmh ?? this.topSpeedKmh,
    avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
    distanceKm: distanceKm ?? this.distanceKm,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    stoppedSeconds: stoppedSeconds ?? this.stoppedSeconds,
    stopCount: stopCount ?? this.stopCount,
    elevationGainMeters: elevationGainMeters.present
        ? elevationGainMeters.value
        : this.elevationGainMeters,
    maxElevationMeters: maxElevationMeters.present
        ? maxElevationMeters.value
        : this.maxElevationMeters,
    maxGforce: maxGforce ?? this.maxGforce,
    hardCornersCount: hardCornersCount ?? this.hardCornersCount,
    hardBrakesCount: hardBrakesCount ?? this.hardBrakesCount,
    leftTurnCount: leftTurnCount ?? this.leftTurnCount,
    rightTurnCount: rightTurnCount ?? this.rightTurnCount,
    laneChangeCount: laneChangeCount ?? this.laneChangeCount,
    maxAccelerationMps2: maxAccelerationMps2 ?? this.maxAccelerationMps2,
    maxDecelerationMps2: maxDecelerationMps2 ?? this.maxDecelerationMps2,
    topCorneringSpeedKmh: topCorneringSpeedKmh ?? this.topCorneringSpeedKmh,
    zeroToHundredSeconds: zeroToHundredSeconds.present
        ? zeroToHundredSeconds.value
        : this.zeroToHundredSeconds,
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
    locationName: locationName.present ? locationName.value : this.locationName,
    roadSegmentIds: roadSegmentIds ?? this.roadSegmentIds,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    isSynced: isSynced ?? this.isSynced,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
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
      stopCount: data.stopCount.present ? data.stopCount.value : this.stopCount,
      elevationGainMeters: data.elevationGainMeters.present
          ? data.elevationGainMeters.value
          : this.elevationGainMeters,
      maxElevationMeters: data.maxElevationMeters.present
          ? data.maxElevationMeters.value
          : this.maxElevationMeters,
      maxGforce: data.maxGforce.present ? data.maxGforce.value : this.maxGforce,
      hardCornersCount: data.hardCornersCount.present
          ? data.hardCornersCount.value
          : this.hardCornersCount,
      hardBrakesCount: data.hardBrakesCount.present
          ? data.hardBrakesCount.value
          : this.hardBrakesCount,
      leftTurnCount: data.leftTurnCount.present
          ? data.leftTurnCount.value
          : this.leftTurnCount,
      rightTurnCount: data.rightTurnCount.present
          ? data.rightTurnCount.value
          : this.rightTurnCount,
      laneChangeCount: data.laneChangeCount.present
          ? data.laneChangeCount.value
          : this.laneChangeCount,
      maxAccelerationMps2: data.maxAccelerationMps2.present
          ? data.maxAccelerationMps2.value
          : this.maxAccelerationMps2,
      maxDecelerationMps2: data.maxDecelerationMps2.present
          ? data.maxDecelerationMps2.value
          : this.maxDecelerationMps2,
      topCorneringSpeedKmh: data.topCorneringSpeedKmh.present
          ? data.topCorneringSpeedKmh.value
          : this.topCorneringSpeedKmh,
      zeroToHundredSeconds: data.zeroToHundredSeconds.present
          ? data.zeroToHundredSeconds.value
          : this.zeroToHundredSeconds,
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
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      roadSegmentIds: data.roadSegmentIds.present
          ? data.roadSegmentIds.value
          : this.roadSegmentIds,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
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
          ..write('stopCount: $stopCount, ')
          ..write('elevationGainMeters: $elevationGainMeters, ')
          ..write('maxElevationMeters: $maxElevationMeters, ')
          ..write('maxGforce: $maxGforce, ')
          ..write('hardCornersCount: $hardCornersCount, ')
          ..write('hardBrakesCount: $hardBrakesCount, ')
          ..write('leftTurnCount: $leftTurnCount, ')
          ..write('rightTurnCount: $rightTurnCount, ')
          ..write('laneChangeCount: $laneChangeCount, ')
          ..write('maxAccelerationMps2: $maxAccelerationMps2, ')
          ..write('maxDecelerationMps2: $maxDecelerationMps2, ')
          ..write('topCorneringSpeedKmh: $topCorneringSpeedKmh, ')
          ..write('zeroToHundredSeconds: $zeroToHundredSeconds, ')
          ..write('fuelCostLocal: $fuelCostLocal, ')
          ..write('localCurrencyCode: $localCurrencyCode, ')
          ..write('weatherCondition: $weatherCondition, ')
          ..write('weatherTempC: $weatherTempC, ')
          ..write('isNightDrive: $isNightDrive, ')
          ..write('mapTheme: $mapTheme, ')
          ..write('country: $country, ')
          ..write('locationName: $locationName, ')
          ..write('roadSegmentIds: $roadSegmentIds, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uid,
    topSpeedKmh,
    avgSpeedKmh,
    distanceKm,
    durationSeconds,
    stoppedSeconds,
    stopCount,
    elevationGainMeters,
    maxElevationMeters,
    maxGforce,
    hardCornersCount,
    hardBrakesCount,
    leftTurnCount,
    rightTurnCount,
    laneChangeCount,
    maxAccelerationMps2,
    maxDecelerationMps2,
    topCorneringSpeedKmh,
    zeroToHundredSeconds,
    fuelCostLocal,
    localCurrencyCode,
    weatherCondition,
    weatherTempC,
    isNightDrive,
    mapTheme,
    country,
    locationName,
    roadSegmentIds,
    startedAt,
    endedAt,
    isSynced,
    remoteId,
  ]);
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
          other.stopCount == this.stopCount &&
          other.elevationGainMeters == this.elevationGainMeters &&
          other.maxElevationMeters == this.maxElevationMeters &&
          other.maxGforce == this.maxGforce &&
          other.hardCornersCount == this.hardCornersCount &&
          other.hardBrakesCount == this.hardBrakesCount &&
          other.leftTurnCount == this.leftTurnCount &&
          other.rightTurnCount == this.rightTurnCount &&
          other.laneChangeCount == this.laneChangeCount &&
          other.maxAccelerationMps2 == this.maxAccelerationMps2 &&
          other.maxDecelerationMps2 == this.maxDecelerationMps2 &&
          other.topCorneringSpeedKmh == this.topCorneringSpeedKmh &&
          other.zeroToHundredSeconds == this.zeroToHundredSeconds &&
          other.fuelCostLocal == this.fuelCostLocal &&
          other.localCurrencyCode == this.localCurrencyCode &&
          other.weatherCondition == this.weatherCondition &&
          other.weatherTempC == this.weatherTempC &&
          other.isNightDrive == this.isNightDrive &&
          other.mapTheme == this.mapTheme &&
          other.country == this.country &&
          other.locationName == this.locationName &&
          other.roadSegmentIds == this.roadSegmentIds &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.isSynced == this.isSynced &&
          other.remoteId == this.remoteId);
}

class TripsCompanion extends UpdateCompanion<TripRow> {
  final Value<int> id;
  final Value<String> uid;
  final Value<double> topSpeedKmh;
  final Value<double> avgSpeedKmh;
  final Value<double> distanceKm;
  final Value<int> durationSeconds;
  final Value<int> stoppedSeconds;
  final Value<int> stopCount;
  final Value<double?> elevationGainMeters;
  final Value<double?> maxElevationMeters;
  final Value<double> maxGforce;
  final Value<int> hardCornersCount;
  final Value<int> hardBrakesCount;
  final Value<int> leftTurnCount;
  final Value<int> rightTurnCount;
  final Value<int> laneChangeCount;
  final Value<double> maxAccelerationMps2;
  final Value<double> maxDecelerationMps2;
  final Value<double> topCorneringSpeedKmh;
  final Value<double?> zeroToHundredSeconds;
  final Value<double?> fuelCostLocal;
  final Value<String?> localCurrencyCode;
  final Value<String?> weatherCondition;
  final Value<double?> weatherTempC;
  final Value<bool> isNightDrive;
  final Value<String> mapTheme;
  final Value<String?> country;
  final Value<String?> locationName;
  final Value<String> roadSegmentIds;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<bool> isSynced;
  final Value<String?> remoteId;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.topSpeedKmh = const Value.absent(),
    this.avgSpeedKmh = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.stoppedSeconds = const Value.absent(),
    this.stopCount = const Value.absent(),
    this.elevationGainMeters = const Value.absent(),
    this.maxElevationMeters = const Value.absent(),
    this.maxGforce = const Value.absent(),
    this.hardCornersCount = const Value.absent(),
    this.hardBrakesCount = const Value.absent(),
    this.leftTurnCount = const Value.absent(),
    this.rightTurnCount = const Value.absent(),
    this.laneChangeCount = const Value.absent(),
    this.maxAccelerationMps2 = const Value.absent(),
    this.maxDecelerationMps2 = const Value.absent(),
    this.topCorneringSpeedKmh = const Value.absent(),
    this.zeroToHundredSeconds = const Value.absent(),
    this.fuelCostLocal = const Value.absent(),
    this.localCurrencyCode = const Value.absent(),
    this.weatherCondition = const Value.absent(),
    this.weatherTempC = const Value.absent(),
    this.isNightDrive = const Value.absent(),
    this.mapTheme = const Value.absent(),
    this.country = const Value.absent(),
    this.locationName = const Value.absent(),
    this.roadSegmentIds = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
  });
  TripsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    required double topSpeedKmh,
    required double avgSpeedKmh,
    required double distanceKm,
    required int durationSeconds,
    this.stoppedSeconds = const Value.absent(),
    this.stopCount = const Value.absent(),
    this.elevationGainMeters = const Value.absent(),
    this.maxElevationMeters = const Value.absent(),
    this.maxGforce = const Value.absent(),
    this.hardCornersCount = const Value.absent(),
    this.hardBrakesCount = const Value.absent(),
    this.leftTurnCount = const Value.absent(),
    this.rightTurnCount = const Value.absent(),
    this.laneChangeCount = const Value.absent(),
    this.maxAccelerationMps2 = const Value.absent(),
    this.maxDecelerationMps2 = const Value.absent(),
    this.topCorneringSpeedKmh = const Value.absent(),
    this.zeroToHundredSeconds = const Value.absent(),
    this.fuelCostLocal = const Value.absent(),
    this.localCurrencyCode = const Value.absent(),
    this.weatherCondition = const Value.absent(),
    this.weatherTempC = const Value.absent(),
    this.isNightDrive = const Value.absent(),
    this.mapTheme = const Value.absent(),
    this.country = const Value.absent(),
    this.locationName = const Value.absent(),
    this.roadSegmentIds = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
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
    Expression<int>? stopCount,
    Expression<double>? elevationGainMeters,
    Expression<double>? maxElevationMeters,
    Expression<double>? maxGforce,
    Expression<int>? hardCornersCount,
    Expression<int>? hardBrakesCount,
    Expression<int>? leftTurnCount,
    Expression<int>? rightTurnCount,
    Expression<int>? laneChangeCount,
    Expression<double>? maxAccelerationMps2,
    Expression<double>? maxDecelerationMps2,
    Expression<double>? topCorneringSpeedKmh,
    Expression<double>? zeroToHundredSeconds,
    Expression<double>? fuelCostLocal,
    Expression<String>? localCurrencyCode,
    Expression<String>? weatherCondition,
    Expression<double>? weatherTempC,
    Expression<bool>? isNightDrive,
    Expression<String>? mapTheme,
    Expression<String>? country,
    Expression<String>? locationName,
    Expression<String>? roadSegmentIds,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<bool>? isSynced,
    Expression<String>? remoteId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (topSpeedKmh != null) 'top_speed_kmh': topSpeedKmh,
      if (avgSpeedKmh != null) 'avg_speed_kmh': avgSpeedKmh,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (stoppedSeconds != null) 'stopped_seconds': stoppedSeconds,
      if (stopCount != null) 'stop_count': stopCount,
      if (elevationGainMeters != null)
        'elevation_gain_meters': elevationGainMeters,
      if (maxElevationMeters != null)
        'max_elevation_meters': maxElevationMeters,
      if (maxGforce != null) 'max_gforce': maxGforce,
      if (hardCornersCount != null) 'hard_corners_count': hardCornersCount,
      if (hardBrakesCount != null) 'hard_brakes_count': hardBrakesCount,
      if (leftTurnCount != null) 'left_turn_count': leftTurnCount,
      if (rightTurnCount != null) 'right_turn_count': rightTurnCount,
      if (laneChangeCount != null) 'lane_change_count': laneChangeCount,
      if (maxAccelerationMps2 != null)
        'max_acceleration_mps2': maxAccelerationMps2,
      if (maxDecelerationMps2 != null)
        'max_deceleration_mps2': maxDecelerationMps2,
      if (topCorneringSpeedKmh != null)
        'top_cornering_speed_kmh': topCorneringSpeedKmh,
      if (zeroToHundredSeconds != null)
        'zero_to_hundred_seconds': zeroToHundredSeconds,
      if (fuelCostLocal != null) 'fuel_cost_local': fuelCostLocal,
      if (localCurrencyCode != null) 'local_currency_code': localCurrencyCode,
      if (weatherCondition != null) 'weather_condition': weatherCondition,
      if (weatherTempC != null) 'weather_temp_c': weatherTempC,
      if (isNightDrive != null) 'is_night_drive': isNightDrive,
      if (mapTheme != null) 'map_theme': mapTheme,
      if (country != null) 'country': country,
      if (locationName != null) 'location_name': locationName,
      if (roadSegmentIds != null) 'road_segment_ids': roadSegmentIds,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (remoteId != null) 'remote_id': remoteId,
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
    Value<int>? stopCount,
    Value<double?>? elevationGainMeters,
    Value<double?>? maxElevationMeters,
    Value<double>? maxGforce,
    Value<int>? hardCornersCount,
    Value<int>? hardBrakesCount,
    Value<int>? leftTurnCount,
    Value<int>? rightTurnCount,
    Value<int>? laneChangeCount,
    Value<double>? maxAccelerationMps2,
    Value<double>? maxDecelerationMps2,
    Value<double>? topCorneringSpeedKmh,
    Value<double?>? zeroToHundredSeconds,
    Value<double?>? fuelCostLocal,
    Value<String?>? localCurrencyCode,
    Value<String?>? weatherCondition,
    Value<double?>? weatherTempC,
    Value<bool>? isNightDrive,
    Value<String>? mapTheme,
    Value<String?>? country,
    Value<String?>? locationName,
    Value<String>? roadSegmentIds,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<bool>? isSynced,
    Value<String?>? remoteId,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      topSpeedKmh: topSpeedKmh ?? this.topSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      stoppedSeconds: stoppedSeconds ?? this.stoppedSeconds,
      stopCount: stopCount ?? this.stopCount,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      maxElevationMeters: maxElevationMeters ?? this.maxElevationMeters,
      maxGforce: maxGforce ?? this.maxGforce,
      hardCornersCount: hardCornersCount ?? this.hardCornersCount,
      hardBrakesCount: hardBrakesCount ?? this.hardBrakesCount,
      leftTurnCount: leftTurnCount ?? this.leftTurnCount,
      rightTurnCount: rightTurnCount ?? this.rightTurnCount,
      laneChangeCount: laneChangeCount ?? this.laneChangeCount,
      maxAccelerationMps2: maxAccelerationMps2 ?? this.maxAccelerationMps2,
      maxDecelerationMps2: maxDecelerationMps2 ?? this.maxDecelerationMps2,
      topCorneringSpeedKmh: topCorneringSpeedKmh ?? this.topCorneringSpeedKmh,
      zeroToHundredSeconds: zeroToHundredSeconds ?? this.zeroToHundredSeconds,
      fuelCostLocal: fuelCostLocal ?? this.fuelCostLocal,
      localCurrencyCode: localCurrencyCode ?? this.localCurrencyCode,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      weatherTempC: weatherTempC ?? this.weatherTempC,
      isNightDrive: isNightDrive ?? this.isNightDrive,
      mapTheme: mapTheme ?? this.mapTheme,
      country: country ?? this.country,
      locationName: locationName ?? this.locationName,
      roadSegmentIds: roadSegmentIds ?? this.roadSegmentIds,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
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
    if (stopCount.present) {
      map['stop_count'] = Variable<int>(stopCount.value);
    }
    if (elevationGainMeters.present) {
      map['elevation_gain_meters'] = Variable<double>(
        elevationGainMeters.value,
      );
    }
    if (maxElevationMeters.present) {
      map['max_elevation_meters'] = Variable<double>(maxElevationMeters.value);
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
    if (leftTurnCount.present) {
      map['left_turn_count'] = Variable<int>(leftTurnCount.value);
    }
    if (rightTurnCount.present) {
      map['right_turn_count'] = Variable<int>(rightTurnCount.value);
    }
    if (laneChangeCount.present) {
      map['lane_change_count'] = Variable<int>(laneChangeCount.value);
    }
    if (maxAccelerationMps2.present) {
      map['max_acceleration_mps2'] = Variable<double>(
        maxAccelerationMps2.value,
      );
    }
    if (maxDecelerationMps2.present) {
      map['max_deceleration_mps2'] = Variable<double>(
        maxDecelerationMps2.value,
      );
    }
    if (topCorneringSpeedKmh.present) {
      map['top_cornering_speed_kmh'] = Variable<double>(
        topCorneringSpeedKmh.value,
      );
    }
    if (zeroToHundredSeconds.present) {
      map['zero_to_hundred_seconds'] = Variable<double>(
        zeroToHundredSeconds.value,
      );
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
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (roadSegmentIds.present) {
      map['road_segment_ids'] = Variable<String>(roadSegmentIds.value);
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
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
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
          ..write('stopCount: $stopCount, ')
          ..write('elevationGainMeters: $elevationGainMeters, ')
          ..write('maxElevationMeters: $maxElevationMeters, ')
          ..write('maxGforce: $maxGforce, ')
          ..write('hardCornersCount: $hardCornersCount, ')
          ..write('hardBrakesCount: $hardBrakesCount, ')
          ..write('leftTurnCount: $leftTurnCount, ')
          ..write('rightTurnCount: $rightTurnCount, ')
          ..write('laneChangeCount: $laneChangeCount, ')
          ..write('maxAccelerationMps2: $maxAccelerationMps2, ')
          ..write('maxDecelerationMps2: $maxDecelerationMps2, ')
          ..write('topCorneringSpeedKmh: $topCorneringSpeedKmh, ')
          ..write('zeroToHundredSeconds: $zeroToHundredSeconds, ')
          ..write('fuelCostLocal: $fuelCostLocal, ')
          ..write('localCurrencyCode: $localCurrencyCode, ')
          ..write('weatherCondition: $weatherCondition, ')
          ..write('weatherTempC: $weatherTempC, ')
          ..write('isNightDrive: $isNightDrive, ')
          ..write('mapTheme: $mapTheme, ')
          ..write('country: $country, ')
          ..write('locationName: $locationName, ')
          ..write('roadSegmentIds: $roadSegmentIds, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('remoteId: $remoteId')
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
  static const VerificationMeta _altitudeMetersMeta = const VerificationMeta(
    'altitudeMeters',
  );
  @override
  late final GeneratedColumn<double> altitudeMeters = GeneratedColumn<double>(
    'altitude_meters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headingMeta = const VerificationMeta(
    'heading',
  );
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
    'heading',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
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
    altitudeMeters,
    heading,
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
    if (data.containsKey('altitude_meters')) {
      context.handle(
        _altitudeMetersMeta,
        altitudeMeters.isAcceptableOrUnknown(
          data['altitude_meters']!,
          _altitudeMetersMeta,
        ),
      );
    }
    if (data.containsKey('heading')) {
      context.handle(
        _headingMeta,
        heading.isAcceptableOrUnknown(data['heading']!, _headingMeta),
      );
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
      altitudeMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude_meters'],
      ),
      heading: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading'],
      ),
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

  /// Altitude above sea level in metres. Null when the fix's reported
  /// altitude accuracy was too poor to trust — see
  /// `GpsService._reliableAltitude`.
  final double? altitudeMeters;

  /// Compass bearing in degrees (0-360), the direction of travel at this
  /// sample. Null when the fix didn't report one or the vehicle was too
  /// slow for heading to be meaningful — see
  /// `AppConstants.turnMinSpeedKmh`. Feeds turn-direction / lane-change
  /// detection; never displayed directly.
  final double? heading;
  final DateTime timestamp;
  const WaypointRow({
    required this.id,
    required this.tripId,
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.accuracyMeters,
    this.altitudeMeters,
    this.heading,
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
    if (!nullToAbsent || altitudeMeters != null) {
      map['altitude_meters'] = Variable<double>(altitudeMeters);
    }
    if (!nullToAbsent || heading != null) {
      map['heading'] = Variable<double>(heading);
    }
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
      altitudeMeters: altitudeMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(altitudeMeters),
      heading: heading == null && nullToAbsent
          ? const Value.absent()
          : Value(heading),
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
      altitudeMeters: serializer.fromJson<double?>(json['altitudeMeters']),
      heading: serializer.fromJson<double?>(json['heading']),
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
      'altitudeMeters': serializer.toJson<double?>(altitudeMeters),
      'heading': serializer.toJson<double?>(heading),
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
    Value<double?> altitudeMeters = const Value.absent(),
    Value<double?> heading = const Value.absent(),
    DateTime? timestamp,
  }) => WaypointRow(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    speedKmh: speedKmh ?? this.speedKmh,
    accuracyMeters: accuracyMeters ?? this.accuracyMeters,
    altitudeMeters: altitudeMeters.present
        ? altitudeMeters.value
        : this.altitudeMeters,
    heading: heading.present ? heading.value : this.heading,
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
      altitudeMeters: data.altitudeMeters.present
          ? data.altitudeMeters.value
          : this.altitudeMeters,
      heading: data.heading.present ? data.heading.value : this.heading,
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
          ..write('altitudeMeters: $altitudeMeters, ')
          ..write('heading: $heading, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    lat,
    lng,
    speedKmh,
    accuracyMeters,
    altitudeMeters,
    heading,
    timestamp,
  );
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
          other.altitudeMeters == this.altitudeMeters &&
          other.heading == this.heading &&
          other.timestamp == this.timestamp);
}

class WaypointsCompanion extends UpdateCompanion<WaypointRow> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double> speedKmh;
  final Value<double> accuracyMeters;
  final Value<double?> altitudeMeters;
  final Value<double?> heading;
  final Value<DateTime> timestamp;
  const WaypointsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.speedKmh = const Value.absent(),
    this.accuracyMeters = const Value.absent(),
    this.altitudeMeters = const Value.absent(),
    this.heading = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  WaypointsCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    required double lat,
    required double lng,
    required double speedKmh,
    required double accuracyMeters,
    this.altitudeMeters = const Value.absent(),
    this.heading = const Value.absent(),
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
    Expression<double>? altitudeMeters,
    Expression<double>? heading,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (speedKmh != null) 'speed_kmh': speedKmh,
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
      if (altitudeMeters != null) 'altitude_meters': altitudeMeters,
      if (heading != null) 'heading': heading,
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
    Value<double?>? altitudeMeters,
    Value<double?>? heading,
    Value<DateTime>? timestamp,
  }) {
    return WaypointsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speedKmh: speedKmh ?? this.speedKmh,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      heading: heading ?? this.heading,
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
    if (altitudeMeters.present) {
      map['altitude_meters'] = Variable<double>(altitudeMeters.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
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
          ..write('altitudeMeters: $altitudeMeters, ')
          ..write('heading: $heading, ')
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
  static const VerificationMeta _minTripLengthMetersMeta =
      const VerificationMeta('minTripLengthMeters');
  @override
  late final GeneratedColumn<double> minTripLengthMeters =
      GeneratedColumn<double>(
        'min_trip_length_meters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(500),
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
  static const VerificationMeta _freeTripLimitMeta = const VerificationMeta(
    'freeTripLimit',
  );
  @override
  late final GeneratedColumn<int> freeTripLimit = GeneratedColumn<int>(
    'free_trip_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _oemAdviceShownMeta = const VerificationMeta(
    'oemAdviceShown',
  );
  @override
  late final GeneratedColumn<bool> oemAdviceShown = GeneratedColumn<bool>(
    'oem_advice_shown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("oem_advice_shown" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bgLocationDisclosureAckedMeta =
      const VerificationMeta('bgLocationDisclosureAcked');
  @override
  late final GeneratedColumn<bool> bgLocationDisclosureAcked =
      GeneratedColumn<bool>(
        'bg_location_disclosure_acked',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("bg_location_disclosure_acked" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _speedGoalKmhMeta = const VerificationMeta(
    'speedGoalKmh',
  );
  @override
  late final GeneratedColumn<double> speedGoalKmh = GeneratedColumn<double>(
    'speed_goal_kmh',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceGoalKmMeta = const VerificationMeta(
    'distanceGoalKm',
  );
  @override
  late final GeneratedColumn<double> distanceGoalKm = GeneratedColumn<double>(
    'distance_goal_km',
    aliasedName,
    true,
    type: DriftSqlType.double,
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
    minTripLengthMeters,
    freeTripsUsed,
    freeTripLimit,
    isPro,
    onboardingComplete,
    oemAdviceShown,
    bgLocationDisclosureAcked,
    speedGoalKmh,
    distanceGoalKm,
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
    if (data.containsKey('min_trip_length_meters')) {
      context.handle(
        _minTripLengthMetersMeta,
        minTripLengthMeters.isAcceptableOrUnknown(
          data['min_trip_length_meters']!,
          _minTripLengthMetersMeta,
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
    if (data.containsKey('free_trip_limit')) {
      context.handle(
        _freeTripLimitMeta,
        freeTripLimit.isAcceptableOrUnknown(
          data['free_trip_limit']!,
          _freeTripLimitMeta,
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
    if (data.containsKey('oem_advice_shown')) {
      context.handle(
        _oemAdviceShownMeta,
        oemAdviceShown.isAcceptableOrUnknown(
          data['oem_advice_shown']!,
          _oemAdviceShownMeta,
        ),
      );
    }
    if (data.containsKey('bg_location_disclosure_acked')) {
      context.handle(
        _bgLocationDisclosureAckedMeta,
        bgLocationDisclosureAcked.isAcceptableOrUnknown(
          data['bg_location_disclosure_acked']!,
          _bgLocationDisclosureAckedMeta,
        ),
      );
    }
    if (data.containsKey('speed_goal_kmh')) {
      context.handle(
        _speedGoalKmhMeta,
        speedGoalKmh.isAcceptableOrUnknown(
          data['speed_goal_kmh']!,
          _speedGoalKmhMeta,
        ),
      );
    }
    if (data.containsKey('distance_goal_km')) {
      context.handle(
        _distanceGoalKmMeta,
        distanceGoalKm.isAcceptableOrUnknown(
          data['distance_goal_km']!,
          _distanceGoalKmMeta,
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
      minTripLengthMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_trip_length_meters'],
      )!,
      freeTripsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}free_trips_used'],
      )!,
      freeTripLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}free_trip_limit'],
      ),
      isPro: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pro'],
      )!,
      onboardingComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_complete'],
      )!,
      oemAdviceShown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}oem_advice_shown'],
      )!,
      bgLocationDisclosureAcked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bg_location_disclosure_acked'],
      )!,
      speedGoalKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_goal_kmh'],
      ),
      distanceGoalKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_goal_km'],
      ),
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

  /// Trips shorter than this (metres) are discarded on End, not saved.
  /// Default 500 m filters out accidental Start→End taps without
  /// eating a real short drive.
  final double minTripLengthMeters;
  final int freeTripsUsed;

  /// The free-trip allowance actually granted to THIS user, persisted at
  /// creation time rather than read from a global constant — so a later
  /// change to the default (3 → 1) can't retroactively cut an existing
  /// user's already-granted allowance. Null on rows created before this
  /// column existed; the migration backfills those to the old default
  /// (3) so nobody already using the app loses trips they were promised.
  /// New rows get the new default (1) explicitly at insert time.
  final int? freeTripLimit;
  final bool isPro;
  final bool onboardingComplete;

  /// Set to true once we've shown the user the OEM battery-killer
  /// bottom sheet (Xiaomi / Oppo / Huawei / Vivo / etc). Persisted so
  /// the prompt fires at most once per install — repeatedly nagging a
  /// user who already saw it is worse UX than letting them figure out
  /// they need to whitelist DriveRank.
  final bool oemAdviceShown;

  /// Set once the user has been shown the in-app Prominent Disclosure
  /// for background location and either accepted or skipped it. Drives
  /// the gate in TrackingBloc that blocks Start until the disclosure
  /// has been surfaced at least once — Google Play policy compliance.
  final bool bgLocationDisclosureAcked;

  /// The user's current "beat this" targets, recomputed by
  /// `TrackingBloc` after every trip (see `GoalCalculator`). Null until
  /// the first trip completes. Only two fields, not a table, because
  /// there is exactly one active goal per metric at a time — no
  /// history of past goals is needed, `Trips` already has the record
  /// of what was actually driven.
  final double? speedGoalKmh;
  final double? distanceGoalKm;
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
    required this.minTripLengthMeters,
    required this.freeTripsUsed,
    this.freeTripLimit,
    required this.isPro,
    required this.onboardingComplete,
    required this.oemAdviceShown,
    required this.bgLocationDisclosureAcked,
    this.speedGoalKmh,
    this.distanceGoalKm,
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
    map['min_trip_length_meters'] = Variable<double>(minTripLengthMeters);
    map['free_trips_used'] = Variable<int>(freeTripsUsed);
    if (!nullToAbsent || freeTripLimit != null) {
      map['free_trip_limit'] = Variable<int>(freeTripLimit);
    }
    map['is_pro'] = Variable<bool>(isPro);
    map['onboarding_complete'] = Variable<bool>(onboardingComplete);
    map['oem_advice_shown'] = Variable<bool>(oemAdviceShown);
    map['bg_location_disclosure_acked'] = Variable<bool>(
      bgLocationDisclosureAcked,
    );
    if (!nullToAbsent || speedGoalKmh != null) {
      map['speed_goal_kmh'] = Variable<double>(speedGoalKmh);
    }
    if (!nullToAbsent || distanceGoalKm != null) {
      map['distance_goal_km'] = Variable<double>(distanceGoalKm);
    }
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
      minTripLengthMeters: Value(minTripLengthMeters),
      freeTripsUsed: Value(freeTripsUsed),
      freeTripLimit: freeTripLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(freeTripLimit),
      isPro: Value(isPro),
      onboardingComplete: Value(onboardingComplete),
      oemAdviceShown: Value(oemAdviceShown),
      bgLocationDisclosureAcked: Value(bgLocationDisclosureAcked),
      speedGoalKmh: speedGoalKmh == null && nullToAbsent
          ? const Value.absent()
          : Value(speedGoalKmh),
      distanceGoalKm: distanceGoalKm == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceGoalKm),
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
      minTripLengthMeters: serializer.fromJson<double>(
        json['minTripLengthMeters'],
      ),
      freeTripsUsed: serializer.fromJson<int>(json['freeTripsUsed']),
      freeTripLimit: serializer.fromJson<int?>(json['freeTripLimit']),
      isPro: serializer.fromJson<bool>(json['isPro']),
      onboardingComplete: serializer.fromJson<bool>(json['onboardingComplete']),
      oemAdviceShown: serializer.fromJson<bool>(json['oemAdviceShown']),
      bgLocationDisclosureAcked: serializer.fromJson<bool>(
        json['bgLocationDisclosureAcked'],
      ),
      speedGoalKmh: serializer.fromJson<double?>(json['speedGoalKmh']),
      distanceGoalKm: serializer.fromJson<double?>(json['distanceGoalKm']),
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
      'minTripLengthMeters': serializer.toJson<double>(minTripLengthMeters),
      'freeTripsUsed': serializer.toJson<int>(freeTripsUsed),
      'freeTripLimit': serializer.toJson<int?>(freeTripLimit),
      'isPro': serializer.toJson<bool>(isPro),
      'onboardingComplete': serializer.toJson<bool>(onboardingComplete),
      'oemAdviceShown': serializer.toJson<bool>(oemAdviceShown),
      'bgLocationDisclosureAcked': serializer.toJson<bool>(
        bgLocationDisclosureAcked,
      ),
      'speedGoalKmh': serializer.toJson<double?>(speedGoalKmh),
      'distanceGoalKm': serializer.toJson<double?>(distanceGoalKm),
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
    double? minTripLengthMeters,
    int? freeTripsUsed,
    Value<int?> freeTripLimit = const Value.absent(),
    bool? isPro,
    bool? onboardingComplete,
    bool? oemAdviceShown,
    bool? bgLocationDisclosureAcked,
    Value<double?> speedGoalKmh = const Value.absent(),
    Value<double?> distanceGoalKm = const Value.absent(),
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
    minTripLengthMeters: minTripLengthMeters ?? this.minTripLengthMeters,
    freeTripsUsed: freeTripsUsed ?? this.freeTripsUsed,
    freeTripLimit: freeTripLimit.present
        ? freeTripLimit.value
        : this.freeTripLimit,
    isPro: isPro ?? this.isPro,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    oemAdviceShown: oemAdviceShown ?? this.oemAdviceShown,
    bgLocationDisclosureAcked:
        bgLocationDisclosureAcked ?? this.bgLocationDisclosureAcked,
    speedGoalKmh: speedGoalKmh.present ? speedGoalKmh.value : this.speedGoalKmh,
    distanceGoalKm: distanceGoalKm.present
        ? distanceGoalKm.value
        : this.distanceGoalKm,
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
      minTripLengthMeters: data.minTripLengthMeters.present
          ? data.minTripLengthMeters.value
          : this.minTripLengthMeters,
      freeTripsUsed: data.freeTripsUsed.present
          ? data.freeTripsUsed.value
          : this.freeTripsUsed,
      freeTripLimit: data.freeTripLimit.present
          ? data.freeTripLimit.value
          : this.freeTripLimit,
      isPro: data.isPro.present ? data.isPro.value : this.isPro,
      onboardingComplete: data.onboardingComplete.present
          ? data.onboardingComplete.value
          : this.onboardingComplete,
      oemAdviceShown: data.oemAdviceShown.present
          ? data.oemAdviceShown.value
          : this.oemAdviceShown,
      bgLocationDisclosureAcked: data.bgLocationDisclosureAcked.present
          ? data.bgLocationDisclosureAcked.value
          : this.bgLocationDisclosureAcked,
      speedGoalKmh: data.speedGoalKmh.present
          ? data.speedGoalKmh.value
          : this.speedGoalKmh,
      distanceGoalKm: data.distanceGoalKm.present
          ? data.distanceGoalKm.value
          : this.distanceGoalKm,
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
          ..write('minTripLengthMeters: $minTripLengthMeters, ')
          ..write('freeTripsUsed: $freeTripsUsed, ')
          ..write('freeTripLimit: $freeTripLimit, ')
          ..write('isPro: $isPro, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('oemAdviceShown: $oemAdviceShown, ')
          ..write('bgLocationDisclosureAcked: $bgLocationDisclosureAcked, ')
          ..write('speedGoalKmh: $speedGoalKmh, ')
          ..write('distanceGoalKm: $distanceGoalKm, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    minTripLengthMeters,
    freeTripsUsed,
    freeTripLimit,
    isPro,
    onboardingComplete,
    oemAdviceShown,
    bgLocationDisclosureAcked,
    speedGoalKmh,
    distanceGoalKm,
    createdAt,
  ]);
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
          other.minTripLengthMeters == this.minTripLengthMeters &&
          other.freeTripsUsed == this.freeTripsUsed &&
          other.freeTripLimit == this.freeTripLimit &&
          other.isPro == this.isPro &&
          other.onboardingComplete == this.onboardingComplete &&
          other.oemAdviceShown == this.oemAdviceShown &&
          other.bgLocationDisclosureAcked == this.bgLocationDisclosureAcked &&
          other.speedGoalKmh == this.speedGoalKmh &&
          other.distanceGoalKm == this.distanceGoalKm &&
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
  final Value<double> minTripLengthMeters;
  final Value<int> freeTripsUsed;
  final Value<int?> freeTripLimit;
  final Value<bool> isPro;
  final Value<bool> onboardingComplete;
  final Value<bool> oemAdviceShown;
  final Value<bool> bgLocationDisclosureAcked;
  final Value<double?> speedGoalKmh;
  final Value<double?> distanceGoalKm;
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
    this.minTripLengthMeters = const Value.absent(),
    this.freeTripsUsed = const Value.absent(),
    this.freeTripLimit = const Value.absent(),
    this.isPro = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    this.oemAdviceShown = const Value.absent(),
    this.bgLocationDisclosureAcked = const Value.absent(),
    this.speedGoalKmh = const Value.absent(),
    this.distanceGoalKm = const Value.absent(),
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
    this.minTripLengthMeters = const Value.absent(),
    this.freeTripsUsed = const Value.absent(),
    this.freeTripLimit = const Value.absent(),
    this.isPro = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    this.oemAdviceShown = const Value.absent(),
    this.bgLocationDisclosureAcked = const Value.absent(),
    this.speedGoalKmh = const Value.absent(),
    this.distanceGoalKm = const Value.absent(),
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
    Expression<double>? minTripLengthMeters,
    Expression<int>? freeTripsUsed,
    Expression<int>? freeTripLimit,
    Expression<bool>? isPro,
    Expression<bool>? onboardingComplete,
    Expression<bool>? oemAdviceShown,
    Expression<bool>? bgLocationDisclosureAcked,
    Expression<double>? speedGoalKmh,
    Expression<double>? distanceGoalKm,
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
      if (minTripLengthMeters != null)
        'min_trip_length_meters': minTripLengthMeters,
      if (freeTripsUsed != null) 'free_trips_used': freeTripsUsed,
      if (freeTripLimit != null) 'free_trip_limit': freeTripLimit,
      if (isPro != null) 'is_pro': isPro,
      if (onboardingComplete != null) 'onboarding_complete': onboardingComplete,
      if (oemAdviceShown != null) 'oem_advice_shown': oemAdviceShown,
      if (bgLocationDisclosureAcked != null)
        'bg_location_disclosure_acked': bgLocationDisclosureAcked,
      if (speedGoalKmh != null) 'speed_goal_kmh': speedGoalKmh,
      if (distanceGoalKm != null) 'distance_goal_km': distanceGoalKm,
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
    Value<double>? minTripLengthMeters,
    Value<int>? freeTripsUsed,
    Value<int?>? freeTripLimit,
    Value<bool>? isPro,
    Value<bool>? onboardingComplete,
    Value<bool>? oemAdviceShown,
    Value<bool>? bgLocationDisclosureAcked,
    Value<double?>? speedGoalKmh,
    Value<double?>? distanceGoalKm,
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
      minTripLengthMeters: minTripLengthMeters ?? this.minTripLengthMeters,
      freeTripsUsed: freeTripsUsed ?? this.freeTripsUsed,
      freeTripLimit: freeTripLimit ?? this.freeTripLimit,
      isPro: isPro ?? this.isPro,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      oemAdviceShown: oemAdviceShown ?? this.oemAdviceShown,
      bgLocationDisclosureAcked:
          bgLocationDisclosureAcked ?? this.bgLocationDisclosureAcked,
      speedGoalKmh: speedGoalKmh ?? this.speedGoalKmh,
      distanceGoalKm: distanceGoalKm ?? this.distanceGoalKm,
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
    if (minTripLengthMeters.present) {
      map['min_trip_length_meters'] = Variable<double>(
        minTripLengthMeters.value,
      );
    }
    if (freeTripsUsed.present) {
      map['free_trips_used'] = Variable<int>(freeTripsUsed.value);
    }
    if (freeTripLimit.present) {
      map['free_trip_limit'] = Variable<int>(freeTripLimit.value);
    }
    if (isPro.present) {
      map['is_pro'] = Variable<bool>(isPro.value);
    }
    if (onboardingComplete.present) {
      map['onboarding_complete'] = Variable<bool>(onboardingComplete.value);
    }
    if (oemAdviceShown.present) {
      map['oem_advice_shown'] = Variable<bool>(oemAdviceShown.value);
    }
    if (bgLocationDisclosureAcked.present) {
      map['bg_location_disclosure_acked'] = Variable<bool>(
        bgLocationDisclosureAcked.value,
      );
    }
    if (speedGoalKmh.present) {
      map['speed_goal_kmh'] = Variable<double>(speedGoalKmh.value);
    }
    if (distanceGoalKm.present) {
      map['distance_goal_km'] = Variable<double>(distanceGoalKm.value);
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
          ..write('minTripLengthMeters: $minTripLengthMeters, ')
          ..write('freeTripsUsed: $freeTripsUsed, ')
          ..write('freeTripLimit: $freeTripLimit, ')
          ..write('isPro: $isPro, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('oemAdviceShown: $oemAdviceShown, ')
          ..write('bgLocationDisclosureAcked: $bgLocationDisclosureAcked, ')
          ..write('speedGoalKmh: $speedGoalKmh, ')
          ..write('distanceGoalKm: $distanceGoalKm, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LiveTripsTable extends LiveTrips
    with TableInfo<$LiveTripsTable, LiveTripRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiveTripsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
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
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
    'distance_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _interruptionCountMeta = const VerificationMeta(
    'interruptionCount',
  );
  @override
  late final GeneratedColumn<int> interruptionCount = GeneratedColumn<int>(
    'interruption_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wasPausedMeta = const VerificationMeta(
    'wasPaused',
  );
  @override
  late final GeneratedColumn<bool> wasPaused = GeneratedColumn<bool>(
    'was_paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    status,
    startedAt,
    distanceKm,
    topSpeedKmh,
    avgSpeedKmh,
    durationSeconds,
    maxGforce,
    hardCornersCount,
    hardBrakesCount,
    interruptionCount,
    wasPaused,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'live_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiveTripRow> instance, {
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    }
    if (data.containsKey('top_speed_kmh')) {
      context.handle(
        _topSpeedKmhMeta,
        topSpeedKmh.isAcceptableOrUnknown(
          data['top_speed_kmh']!,
          _topSpeedKmhMeta,
        ),
      );
    }
    if (data.containsKey('avg_speed_kmh')) {
      context.handle(
        _avgSpeedKmhMeta,
        avgSpeedKmh.isAcceptableOrUnknown(
          data['avg_speed_kmh']!,
          _avgSpeedKmhMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
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
    if (data.containsKey('interruption_count')) {
      context.handle(
        _interruptionCountMeta,
        interruptionCount.isAcceptableOrUnknown(
          data['interruption_count']!,
          _interruptionCountMeta,
        ),
      );
    }
    if (data.containsKey('was_paused')) {
      context.handle(
        _wasPausedMeta,
        wasPaused.isAcceptableOrUnknown(data['was_paused']!, _wasPausedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LiveTripRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiveTripRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_km'],
      )!,
      topSpeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}top_speed_kmh'],
      )!,
      avgSpeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_speed_kmh'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
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
      interruptionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interruption_count'],
      )!,
      wasPaused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_paused'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LiveTripsTable createAlias(String alias) {
    return $LiveTripsTable(attachedDatabase, alias);
  }
}

class LiveTripRow extends DataClass implements Insertable<LiveTripRow> {
  final int id;

  /// User id this trip belongs to. Mirrors `Trips.uid` so completed
  /// trips inherit ownership cleanly.
  final String uid;

  /// Status — stored as the enum's `.name` so adding a new case in
  /// code doesn't break old rows. See [TripStatusEnum].
  final String status;

  /// Wall-clock start of the trip. Used for duration when ticking and
  /// preserved through Resume so paused intervals don't count.
  final DateTime startedAt;

  /// Most-recent rollup of stats. Recomputable from [LiveWaypoints]
  /// in the worst case, but cached here so the tracking page can
  /// render the recovery banner without a full waypoint scan.
  final double distanceKm;
  final double topSpeedKmh;
  final double avgSpeedKmh;
  final int durationSeconds;
  final double maxGforce;
  final int hardCornersCount;
  final int hardBrakesCount;

  /// Number of times this single trip had to recover from an
  /// interrupted state. Surfaced on the saved trip card later as the
  /// foundation for a "Trip Quality" badge.
  final int interruptionCount;

  /// True when the trip was sitting in `paused` at the moment the
  /// snapshot was taken — drives whether the recovery banner reads
  /// "you paused at 12:34" vs "your trip was interrupted at 12:34".
  final bool wasPaused;

  /// When this row was last written. The bloc uses
  /// `now - updatedAt > 30s` as the heuristic for "the OS killed us
  /// before we could finish" and flips status → interrupted.
  final DateTime updatedAt;
  const LiveTripRow({
    required this.id,
    required this.uid,
    required this.status,
    required this.startedAt,
    required this.distanceKm,
    required this.topSpeedKmh,
    required this.avgSpeedKmh,
    required this.durationSeconds,
    required this.maxGforce,
    required this.hardCornersCount,
    required this.hardBrakesCount,
    required this.interruptionCount,
    required this.wasPaused,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<String>(uid);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['distance_km'] = Variable<double>(distanceKm);
    map['top_speed_kmh'] = Variable<double>(topSpeedKmh);
    map['avg_speed_kmh'] = Variable<double>(avgSpeedKmh);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['max_gforce'] = Variable<double>(maxGforce);
    map['hard_corners_count'] = Variable<int>(hardCornersCount);
    map['hard_brakes_count'] = Variable<int>(hardBrakesCount);
    map['interruption_count'] = Variable<int>(interruptionCount);
    map['was_paused'] = Variable<bool>(wasPaused);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LiveTripsCompanion toCompanion(bool nullToAbsent) {
    return LiveTripsCompanion(
      id: Value(id),
      uid: Value(uid),
      status: Value(status),
      startedAt: Value(startedAt),
      distanceKm: Value(distanceKm),
      topSpeedKmh: Value(topSpeedKmh),
      avgSpeedKmh: Value(avgSpeedKmh),
      durationSeconds: Value(durationSeconds),
      maxGforce: Value(maxGforce),
      hardCornersCount: Value(hardCornersCount),
      hardBrakesCount: Value(hardBrakesCount),
      interruptionCount: Value(interruptionCount),
      wasPaused: Value(wasPaused),
      updatedAt: Value(updatedAt),
    );
  }

  factory LiveTripRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiveTripRow(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      distanceKm: serializer.fromJson<double>(json['distanceKm']),
      topSpeedKmh: serializer.fromJson<double>(json['topSpeedKmh']),
      avgSpeedKmh: serializer.fromJson<double>(json['avgSpeedKmh']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      maxGforce: serializer.fromJson<double>(json['maxGforce']),
      hardCornersCount: serializer.fromJson<int>(json['hardCornersCount']),
      hardBrakesCount: serializer.fromJson<int>(json['hardBrakesCount']),
      interruptionCount: serializer.fromJson<int>(json['interruptionCount']),
      wasPaused: serializer.fromJson<bool>(json['wasPaused']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'distanceKm': serializer.toJson<double>(distanceKm),
      'topSpeedKmh': serializer.toJson<double>(topSpeedKmh),
      'avgSpeedKmh': serializer.toJson<double>(avgSpeedKmh),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'maxGforce': serializer.toJson<double>(maxGforce),
      'hardCornersCount': serializer.toJson<int>(hardCornersCount),
      'hardBrakesCount': serializer.toJson<int>(hardBrakesCount),
      'interruptionCount': serializer.toJson<int>(interruptionCount),
      'wasPaused': serializer.toJson<bool>(wasPaused),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LiveTripRow copyWith({
    int? id,
    String? uid,
    String? status,
    DateTime? startedAt,
    double? distanceKm,
    double? topSpeedKmh,
    double? avgSpeedKmh,
    int? durationSeconds,
    double? maxGforce,
    int? hardCornersCount,
    int? hardBrakesCount,
    int? interruptionCount,
    bool? wasPaused,
    DateTime? updatedAt,
  }) => LiveTripRow(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    distanceKm: distanceKm ?? this.distanceKm,
    topSpeedKmh: topSpeedKmh ?? this.topSpeedKmh,
    avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    maxGforce: maxGforce ?? this.maxGforce,
    hardCornersCount: hardCornersCount ?? this.hardCornersCount,
    hardBrakesCount: hardBrakesCount ?? this.hardBrakesCount,
    interruptionCount: interruptionCount ?? this.interruptionCount,
    wasPaused: wasPaused ?? this.wasPaused,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LiveTripRow copyWithCompanion(LiveTripsCompanion data) {
    return LiveTripRow(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
      topSpeedKmh: data.topSpeedKmh.present
          ? data.topSpeedKmh.value
          : this.topSpeedKmh,
      avgSpeedKmh: data.avgSpeedKmh.present
          ? data.avgSpeedKmh.value
          : this.avgSpeedKmh,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      maxGforce: data.maxGforce.present ? data.maxGforce.value : this.maxGforce,
      hardCornersCount: data.hardCornersCount.present
          ? data.hardCornersCount.value
          : this.hardCornersCount,
      hardBrakesCount: data.hardBrakesCount.present
          ? data.hardBrakesCount.value
          : this.hardBrakesCount,
      interruptionCount: data.interruptionCount.present
          ? data.interruptionCount.value
          : this.interruptionCount,
      wasPaused: data.wasPaused.present ? data.wasPaused.value : this.wasPaused,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiveTripRow(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('topSpeedKmh: $topSpeedKmh, ')
          ..write('avgSpeedKmh: $avgSpeedKmh, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('maxGforce: $maxGforce, ')
          ..write('hardCornersCount: $hardCornersCount, ')
          ..write('hardBrakesCount: $hardBrakesCount, ')
          ..write('interruptionCount: $interruptionCount, ')
          ..write('wasPaused: $wasPaused, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    status,
    startedAt,
    distanceKm,
    topSpeedKmh,
    avgSpeedKmh,
    durationSeconds,
    maxGforce,
    hardCornersCount,
    hardBrakesCount,
    interruptionCount,
    wasPaused,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveTripRow &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.distanceKm == this.distanceKm &&
          other.topSpeedKmh == this.topSpeedKmh &&
          other.avgSpeedKmh == this.avgSpeedKmh &&
          other.durationSeconds == this.durationSeconds &&
          other.maxGforce == this.maxGforce &&
          other.hardCornersCount == this.hardCornersCount &&
          other.hardBrakesCount == this.hardBrakesCount &&
          other.interruptionCount == this.interruptionCount &&
          other.wasPaused == this.wasPaused &&
          other.updatedAt == this.updatedAt);
}

class LiveTripsCompanion extends UpdateCompanion<LiveTripRow> {
  final Value<int> id;
  final Value<String> uid;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<double> distanceKm;
  final Value<double> topSpeedKmh;
  final Value<double> avgSpeedKmh;
  final Value<int> durationSeconds;
  final Value<double> maxGforce;
  final Value<int> hardCornersCount;
  final Value<int> hardBrakesCount;
  final Value<int> interruptionCount;
  final Value<bool> wasPaused;
  final Value<DateTime> updatedAt;
  const LiveTripsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.topSpeedKmh = const Value.absent(),
    this.avgSpeedKmh = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.maxGforce = const Value.absent(),
    this.hardCornersCount = const Value.absent(),
    this.hardBrakesCount = const Value.absent(),
    this.interruptionCount = const Value.absent(),
    this.wasPaused = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LiveTripsCompanion.insert({
    this.id = const Value.absent(),
    required String uid,
    this.status = const Value.absent(),
    required DateTime startedAt,
    this.distanceKm = const Value.absent(),
    this.topSpeedKmh = const Value.absent(),
    this.avgSpeedKmh = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.maxGforce = const Value.absent(),
    this.hardCornersCount = const Value.absent(),
    this.hardBrakesCount = const Value.absent(),
    this.interruptionCount = const Value.absent(),
    this.wasPaused = const Value.absent(),
    required DateTime updatedAt,
  }) : uid = Value(uid),
       startedAt = Value(startedAt),
       updatedAt = Value(updatedAt);
  static Insertable<LiveTripRow> custom({
    Expression<int>? id,
    Expression<String>? uid,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<double>? distanceKm,
    Expression<double>? topSpeedKmh,
    Expression<double>? avgSpeedKmh,
    Expression<int>? durationSeconds,
    Expression<double>? maxGforce,
    Expression<int>? hardCornersCount,
    Expression<int>? hardBrakesCount,
    Expression<int>? interruptionCount,
    Expression<bool>? wasPaused,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (topSpeedKmh != null) 'top_speed_kmh': topSpeedKmh,
      if (avgSpeedKmh != null) 'avg_speed_kmh': avgSpeedKmh,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (maxGforce != null) 'max_gforce': maxGforce,
      if (hardCornersCount != null) 'hard_corners_count': hardCornersCount,
      if (hardBrakesCount != null) 'hard_brakes_count': hardBrakesCount,
      if (interruptionCount != null) 'interruption_count': interruptionCount,
      if (wasPaused != null) 'was_paused': wasPaused,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LiveTripsCompanion copyWith({
    Value<int>? id,
    Value<String>? uid,
    Value<String>? status,
    Value<DateTime>? startedAt,
    Value<double>? distanceKm,
    Value<double>? topSpeedKmh,
    Value<double>? avgSpeedKmh,
    Value<int>? durationSeconds,
    Value<double>? maxGforce,
    Value<int>? hardCornersCount,
    Value<int>? hardBrakesCount,
    Value<int>? interruptionCount,
    Value<bool>? wasPaused,
    Value<DateTime>? updatedAt,
  }) {
    return LiveTripsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      distanceKm: distanceKm ?? this.distanceKm,
      topSpeedKmh: topSpeedKmh ?? this.topSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      maxGforce: maxGforce ?? this.maxGforce,
      hardCornersCount: hardCornersCount ?? this.hardCornersCount,
      hardBrakesCount: hardBrakesCount ?? this.hardBrakesCount,
      interruptionCount: interruptionCount ?? this.interruptionCount,
      wasPaused: wasPaused ?? this.wasPaused,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (topSpeedKmh.present) {
      map['top_speed_kmh'] = Variable<double>(topSpeedKmh.value);
    }
    if (avgSpeedKmh.present) {
      map['avg_speed_kmh'] = Variable<double>(avgSpeedKmh.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
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
    if (interruptionCount.present) {
      map['interruption_count'] = Variable<int>(interruptionCount.value);
    }
    if (wasPaused.present) {
      map['was_paused'] = Variable<bool>(wasPaused.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiveTripsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('topSpeedKmh: $topSpeedKmh, ')
          ..write('avgSpeedKmh: $avgSpeedKmh, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('maxGforce: $maxGforce, ')
          ..write('hardCornersCount: $hardCornersCount, ')
          ..write('hardBrakesCount: $hardBrakesCount, ')
          ..write('interruptionCount: $interruptionCount, ')
          ..write('wasPaused: $wasPaused, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LiveWaypointsTable extends LiveWaypoints
    with TableInfo<$LiveWaypointsTable, LiveWaypointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiveWaypointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tripLocalIdMeta = const VerificationMeta(
    'tripLocalId',
  );
  @override
  late final GeneratedColumn<int> tripLocalId = GeneratedColumn<int>(
    'trip_local_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    tripLocalId,
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
  static const String $name = 'live_waypoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiveWaypointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_local_id')) {
      context.handle(
        _tripLocalIdMeta,
        tripLocalId.isAcceptableOrUnknown(
          data['trip_local_id']!,
          _tripLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tripLocalIdMeta);
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
  LiveWaypointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiveWaypointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tripLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trip_local_id'],
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
  $LiveWaypointsTable createAlias(String alias) {
    return $LiveWaypointsTable(attachedDatabase, alias);
  }
}

class LiveWaypointRow extends DataClass implements Insertable<LiveWaypointRow> {
  final int id;
  final int tripLocalId;
  final double lat;
  final double lng;
  final double speedKmh;
  final double accuracyMeters;
  final DateTime timestamp;
  const LiveWaypointRow({
    required this.id,
    required this.tripLocalId,
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
    map['trip_local_id'] = Variable<int>(tripLocalId);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['speed_kmh'] = Variable<double>(speedKmh);
    map['accuracy_meters'] = Variable<double>(accuracyMeters);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  LiveWaypointsCompanion toCompanion(bool nullToAbsent) {
    return LiveWaypointsCompanion(
      id: Value(id),
      tripLocalId: Value(tripLocalId),
      lat: Value(lat),
      lng: Value(lng),
      speedKmh: Value(speedKmh),
      accuracyMeters: Value(accuracyMeters),
      timestamp: Value(timestamp),
    );
  }

  factory LiveWaypointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiveWaypointRow(
      id: serializer.fromJson<int>(json['id']),
      tripLocalId: serializer.fromJson<int>(json['tripLocalId']),
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
      'tripLocalId': serializer.toJson<int>(tripLocalId),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'speedKmh': serializer.toJson<double>(speedKmh),
      'accuracyMeters': serializer.toJson<double>(accuracyMeters),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  LiveWaypointRow copyWith({
    int? id,
    int? tripLocalId,
    double? lat,
    double? lng,
    double? speedKmh,
    double? accuracyMeters,
    DateTime? timestamp,
  }) => LiveWaypointRow(
    id: id ?? this.id,
    tripLocalId: tripLocalId ?? this.tripLocalId,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    speedKmh: speedKmh ?? this.speedKmh,
    accuracyMeters: accuracyMeters ?? this.accuracyMeters,
    timestamp: timestamp ?? this.timestamp,
  );
  LiveWaypointRow copyWithCompanion(LiveWaypointsCompanion data) {
    return LiveWaypointRow(
      id: data.id.present ? data.id.value : this.id,
      tripLocalId: data.tripLocalId.present
          ? data.tripLocalId.value
          : this.tripLocalId,
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
    return (StringBuffer('LiveWaypointRow(')
          ..write('id: $id, ')
          ..write('tripLocalId: $tripLocalId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('speedKmh: $speedKmh, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripLocalId,
    lat,
    lng,
    speedKmh,
    accuracyMeters,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveWaypointRow &&
          other.id == this.id &&
          other.tripLocalId == this.tripLocalId &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.speedKmh == this.speedKmh &&
          other.accuracyMeters == this.accuracyMeters &&
          other.timestamp == this.timestamp);
}

class LiveWaypointsCompanion extends UpdateCompanion<LiveWaypointRow> {
  final Value<int> id;
  final Value<int> tripLocalId;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double> speedKmh;
  final Value<double> accuracyMeters;
  final Value<DateTime> timestamp;
  const LiveWaypointsCompanion({
    this.id = const Value.absent(),
    this.tripLocalId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.speedKmh = const Value.absent(),
    this.accuracyMeters = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  LiveWaypointsCompanion.insert({
    this.id = const Value.absent(),
    required int tripLocalId,
    required double lat,
    required double lng,
    required double speedKmh,
    required double accuracyMeters,
    required DateTime timestamp,
  }) : tripLocalId = Value(tripLocalId),
       lat = Value(lat),
       lng = Value(lng),
       speedKmh = Value(speedKmh),
       accuracyMeters = Value(accuracyMeters),
       timestamp = Value(timestamp);
  static Insertable<LiveWaypointRow> custom({
    Expression<int>? id,
    Expression<int>? tripLocalId,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? speedKmh,
    Expression<double>? accuracyMeters,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripLocalId != null) 'trip_local_id': tripLocalId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (speedKmh != null) 'speed_kmh': speedKmh,
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  LiveWaypointsCompanion copyWith({
    Value<int>? id,
    Value<int>? tripLocalId,
    Value<double>? lat,
    Value<double>? lng,
    Value<double>? speedKmh,
    Value<double>? accuracyMeters,
    Value<DateTime>? timestamp,
  }) {
    return LiveWaypointsCompanion(
      id: id ?? this.id,
      tripLocalId: tripLocalId ?? this.tripLocalId,
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
    if (tripLocalId.present) {
      map['trip_local_id'] = Variable<int>(tripLocalId.value);
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
    return (StringBuffer('LiveWaypointsCompanion(')
          ..write('id: $id, ')
          ..write('tripLocalId: $tripLocalId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('speedKmh: $speedKmh, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

abstract class _$LegacyAppDatabaseV10 extends GeneratedDatabase {
  _$LegacyAppDatabaseV10(QueryExecutor e) : super(e);
  $LegacyAppDatabaseV10Manager get managers =>
      $LegacyAppDatabaseV10Manager(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $WaypointsTable waypoints = $WaypointsTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final $LiveTripsTable liveTrips = $LiveTripsTable(this);
  late final $LiveWaypointsTable liveWaypoints = $LiveWaypointsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trips,
    waypoints,
    userSettings,
    liveTrips,
    liveWaypoints,
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
      Value<int> stopCount,
      Value<double?> elevationGainMeters,
      Value<double?> maxElevationMeters,
      Value<double> maxGforce,
      Value<int> hardCornersCount,
      Value<int> hardBrakesCount,
      Value<int> leftTurnCount,
      Value<int> rightTurnCount,
      Value<int> laneChangeCount,
      Value<double> maxAccelerationMps2,
      Value<double> maxDecelerationMps2,
      Value<double> topCorneringSpeedKmh,
      Value<double?> zeroToHundredSeconds,
      Value<double?> fuelCostLocal,
      Value<String?> localCurrencyCode,
      Value<String?> weatherCondition,
      Value<double?> weatherTempC,
      Value<bool> isNightDrive,
      Value<String> mapTheme,
      Value<String?> country,
      Value<String?> locationName,
      Value<String> roadSegmentIds,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<bool> isSynced,
      Value<String?> remoteId,
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
      Value<int> stopCount,
      Value<double?> elevationGainMeters,
      Value<double?> maxElevationMeters,
      Value<double> maxGforce,
      Value<int> hardCornersCount,
      Value<int> hardBrakesCount,
      Value<int> leftTurnCount,
      Value<int> rightTurnCount,
      Value<int> laneChangeCount,
      Value<double> maxAccelerationMps2,
      Value<double> maxDecelerationMps2,
      Value<double> topCorneringSpeedKmh,
      Value<double?> zeroToHundredSeconds,
      Value<double?> fuelCostLocal,
      Value<String?> localCurrencyCode,
      Value<String?> weatherCondition,
      Value<double?> weatherTempC,
      Value<bool> isNightDrive,
      Value<String> mapTheme,
      Value<String?> country,
      Value<String?> locationName,
      Value<String> roadSegmentIds,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<bool> isSynced,
      Value<String?> remoteId,
    });

final class $$TripsTableReferences
    extends BaseReferences<_$LegacyAppDatabaseV10, $TripsTable, TripRow> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WaypointsTable, List<WaypointRow>>
  _waypointsRefsTable(_$LegacyAppDatabaseV10 db) =>
      MultiTypedResultKey.fromTable(
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

class $$TripsTableFilterComposer
    extends Composer<_$LegacyAppDatabaseV10, $TripsTable> {
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

  ColumnFilters<int> get stopCount => $composableBuilder(
    column: $table.stopCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationGainMeters => $composableBuilder(
    column: $table.elevationGainMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxElevationMeters => $composableBuilder(
    column: $table.maxElevationMeters,
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

  ColumnFilters<int> get leftTurnCount => $composableBuilder(
    column: $table.leftTurnCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rightTurnCount => $composableBuilder(
    column: $table.rightTurnCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get laneChangeCount => $composableBuilder(
    column: $table.laneChangeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxAccelerationMps2 => $composableBuilder(
    column: $table.maxAccelerationMps2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxDecelerationMps2 => $composableBuilder(
    column: $table.maxDecelerationMps2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get topCorneringSpeedKmh => $composableBuilder(
    column: $table.topCorneringSpeedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get zeroToHundredSeconds => $composableBuilder(
    column: $table.zeroToHundredSeconds,
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

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roadSegmentIds => $composableBuilder(
    column: $table.roadSegmentIds,
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

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
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
    extends Composer<_$LegacyAppDatabaseV10, $TripsTable> {
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

  ColumnOrderings<int> get stopCount => $composableBuilder(
    column: $table.stopCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationGainMeters => $composableBuilder(
    column: $table.elevationGainMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxElevationMeters => $composableBuilder(
    column: $table.maxElevationMeters,
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

  ColumnOrderings<int> get leftTurnCount => $composableBuilder(
    column: $table.leftTurnCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rightTurnCount => $composableBuilder(
    column: $table.rightTurnCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get laneChangeCount => $composableBuilder(
    column: $table.laneChangeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxAccelerationMps2 => $composableBuilder(
    column: $table.maxAccelerationMps2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxDecelerationMps2 => $composableBuilder(
    column: $table.maxDecelerationMps2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get topCorneringSpeedKmh => $composableBuilder(
    column: $table.topCorneringSpeedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zeroToHundredSeconds => $composableBuilder(
    column: $table.zeroToHundredSeconds,
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

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roadSegmentIds => $composableBuilder(
    column: $table.roadSegmentIds,
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

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$LegacyAppDatabaseV10, $TripsTable> {
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

  GeneratedColumn<int> get stopCount =>
      $composableBuilder(column: $table.stopCount, builder: (column) => column);

  GeneratedColumn<double> get elevationGainMeters => $composableBuilder(
    column: $table.elevationGainMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxElevationMeters => $composableBuilder(
    column: $table.maxElevationMeters,
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

  GeneratedColumn<int> get leftTurnCount => $composableBuilder(
    column: $table.leftTurnCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rightTurnCount => $composableBuilder(
    column: $table.rightTurnCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get laneChangeCount => $composableBuilder(
    column: $table.laneChangeCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxAccelerationMps2 => $composableBuilder(
    column: $table.maxAccelerationMps2,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxDecelerationMps2 => $composableBuilder(
    column: $table.maxDecelerationMps2,
    builder: (column) => column,
  );

  GeneratedColumn<double> get topCorneringSpeedKmh => $composableBuilder(
    column: $table.topCorneringSpeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get zeroToHundredSeconds => $composableBuilder(
    column: $table.zeroToHundredSeconds,
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

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roadSegmentIds => $composableBuilder(
    column: $table.roadSegmentIds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

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
          _$LegacyAppDatabaseV10,
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
  $$TripsTableTableManager(_$LegacyAppDatabaseV10 db, $TripsTable table)
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
                Value<int> stopCount = const Value.absent(),
                Value<double?> elevationGainMeters = const Value.absent(),
                Value<double?> maxElevationMeters = const Value.absent(),
                Value<double> maxGforce = const Value.absent(),
                Value<int> hardCornersCount = const Value.absent(),
                Value<int> hardBrakesCount = const Value.absent(),
                Value<int> leftTurnCount = const Value.absent(),
                Value<int> rightTurnCount = const Value.absent(),
                Value<int> laneChangeCount = const Value.absent(),
                Value<double> maxAccelerationMps2 = const Value.absent(),
                Value<double> maxDecelerationMps2 = const Value.absent(),
                Value<double> topCorneringSpeedKmh = const Value.absent(),
                Value<double?> zeroToHundredSeconds = const Value.absent(),
                Value<double?> fuelCostLocal = const Value.absent(),
                Value<String?> localCurrencyCode = const Value.absent(),
                Value<String?> weatherCondition = const Value.absent(),
                Value<double?> weatherTempC = const Value.absent(),
                Value<bool> isNightDrive = const Value.absent(),
                Value<String> mapTheme = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<String> roadSegmentIds = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                uid: uid,
                topSpeedKmh: topSpeedKmh,
                avgSpeedKmh: avgSpeedKmh,
                distanceKm: distanceKm,
                durationSeconds: durationSeconds,
                stoppedSeconds: stoppedSeconds,
                stopCount: stopCount,
                elevationGainMeters: elevationGainMeters,
                maxElevationMeters: maxElevationMeters,
                maxGforce: maxGforce,
                hardCornersCount: hardCornersCount,
                hardBrakesCount: hardBrakesCount,
                leftTurnCount: leftTurnCount,
                rightTurnCount: rightTurnCount,
                laneChangeCount: laneChangeCount,
                maxAccelerationMps2: maxAccelerationMps2,
                maxDecelerationMps2: maxDecelerationMps2,
                topCorneringSpeedKmh: topCorneringSpeedKmh,
                zeroToHundredSeconds: zeroToHundredSeconds,
                fuelCostLocal: fuelCostLocal,
                localCurrencyCode: localCurrencyCode,
                weatherCondition: weatherCondition,
                weatherTempC: weatherTempC,
                isNightDrive: isNightDrive,
                mapTheme: mapTheme,
                country: country,
                locationName: locationName,
                roadSegmentIds: roadSegmentIds,
                startedAt: startedAt,
                endedAt: endedAt,
                isSynced: isSynced,
                remoteId: remoteId,
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
                Value<int> stopCount = const Value.absent(),
                Value<double?> elevationGainMeters = const Value.absent(),
                Value<double?> maxElevationMeters = const Value.absent(),
                Value<double> maxGforce = const Value.absent(),
                Value<int> hardCornersCount = const Value.absent(),
                Value<int> hardBrakesCount = const Value.absent(),
                Value<int> leftTurnCount = const Value.absent(),
                Value<int> rightTurnCount = const Value.absent(),
                Value<int> laneChangeCount = const Value.absent(),
                Value<double> maxAccelerationMps2 = const Value.absent(),
                Value<double> maxDecelerationMps2 = const Value.absent(),
                Value<double> topCorneringSpeedKmh = const Value.absent(),
                Value<double?> zeroToHundredSeconds = const Value.absent(),
                Value<double?> fuelCostLocal = const Value.absent(),
                Value<String?> localCurrencyCode = const Value.absent(),
                Value<String?> weatherCondition = const Value.absent(),
                Value<double?> weatherTempC = const Value.absent(),
                Value<bool> isNightDrive = const Value.absent(),
                Value<String> mapTheme = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<String> roadSegmentIds = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
              }) => TripsCompanion.insert(
                id: id,
                uid: uid,
                topSpeedKmh: topSpeedKmh,
                avgSpeedKmh: avgSpeedKmh,
                distanceKm: distanceKm,
                durationSeconds: durationSeconds,
                stoppedSeconds: stoppedSeconds,
                stopCount: stopCount,
                elevationGainMeters: elevationGainMeters,
                maxElevationMeters: maxElevationMeters,
                maxGforce: maxGforce,
                hardCornersCount: hardCornersCount,
                hardBrakesCount: hardBrakesCount,
                leftTurnCount: leftTurnCount,
                rightTurnCount: rightTurnCount,
                laneChangeCount: laneChangeCount,
                maxAccelerationMps2: maxAccelerationMps2,
                maxDecelerationMps2: maxDecelerationMps2,
                topCorneringSpeedKmh: topCorneringSpeedKmh,
                zeroToHundredSeconds: zeroToHundredSeconds,
                fuelCostLocal: fuelCostLocal,
                localCurrencyCode: localCurrencyCode,
                weatherCondition: weatherCondition,
                weatherTempC: weatherTempC,
                isNightDrive: isNightDrive,
                mapTheme: mapTheme,
                country: country,
                locationName: locationName,
                roadSegmentIds: roadSegmentIds,
                startedAt: startedAt,
                endedAt: endedAt,
                isSynced: isSynced,
                remoteId: remoteId,
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
      _$LegacyAppDatabaseV10,
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
      Value<double?> altitudeMeters,
      Value<double?> heading,
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
      Value<double?> altitudeMeters,
      Value<double?> heading,
      Value<DateTime> timestamp,
    });

final class $$WaypointsTableReferences
    extends
        BaseReferences<_$LegacyAppDatabaseV10, $WaypointsTable, WaypointRow> {
  $$WaypointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$LegacyAppDatabaseV10 db) => db.trips
      .createAlias($_aliasNameGenerator(db.waypoints.tripId, db.trips.id));

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
    extends Composer<_$LegacyAppDatabaseV10, $WaypointsTable> {
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

  ColumnFilters<double> get altitudeMeters => $composableBuilder(
    column: $table.altitudeMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heading => $composableBuilder(
    column: $table.heading,
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
    extends Composer<_$LegacyAppDatabaseV10, $WaypointsTable> {
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

  ColumnOrderings<double> get altitudeMeters => $composableBuilder(
    column: $table.altitudeMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heading => $composableBuilder(
    column: $table.heading,
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
    extends Composer<_$LegacyAppDatabaseV10, $WaypointsTable> {
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

  GeneratedColumn<double> get altitudeMeters => $composableBuilder(
    column: $table.altitudeMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

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
          _$LegacyAppDatabaseV10,
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
  $$WaypointsTableTableManager(_$LegacyAppDatabaseV10 db, $WaypointsTable table)
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
                Value<double?> altitudeMeters = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => WaypointsCompanion(
                id: id,
                tripId: tripId,
                lat: lat,
                lng: lng,
                speedKmh: speedKmh,
                accuracyMeters: accuracyMeters,
                altitudeMeters: altitudeMeters,
                heading: heading,
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
                Value<double?> altitudeMeters = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                required DateTime timestamp,
              }) => WaypointsCompanion.insert(
                id: id,
                tripId: tripId,
                lat: lat,
                lng: lng,
                speedKmh: speedKmh,
                accuracyMeters: accuracyMeters,
                altitudeMeters: altitudeMeters,
                heading: heading,
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
      _$LegacyAppDatabaseV10,
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
      Value<double> minTripLengthMeters,
      Value<int> freeTripsUsed,
      Value<int?> freeTripLimit,
      Value<bool> isPro,
      Value<bool> onboardingComplete,
      Value<bool> oemAdviceShown,
      Value<bool> bgLocationDisclosureAcked,
      Value<double?> speedGoalKmh,
      Value<double?> distanceGoalKm,
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
      Value<double> minTripLengthMeters,
      Value<int> freeTripsUsed,
      Value<int?> freeTripLimit,
      Value<bool> isPro,
      Value<bool> onboardingComplete,
      Value<bool> oemAdviceShown,
      Value<bool> bgLocationDisclosureAcked,
      Value<double?> speedGoalKmh,
      Value<double?> distanceGoalKm,
      Value<DateTime> createdAt,
    });

class $$UserSettingsTableFilterComposer
    extends Composer<_$LegacyAppDatabaseV10, $UserSettingsTable> {
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

  ColumnFilters<double> get minTripLengthMeters => $composableBuilder(
    column: $table.minTripLengthMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freeTripsUsed => $composableBuilder(
    column: $table.freeTripsUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freeTripLimit => $composableBuilder(
    column: $table.freeTripLimit,
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

  ColumnFilters<bool> get oemAdviceShown => $composableBuilder(
    column: $table.oemAdviceShown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bgLocationDisclosureAcked => $composableBuilder(
    column: $table.bgLocationDisclosureAcked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedGoalKmh => $composableBuilder(
    column: $table.speedGoalKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceGoalKm => $composableBuilder(
    column: $table.distanceGoalKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$LegacyAppDatabaseV10, $UserSettingsTable> {
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

  ColumnOrderings<double> get minTripLengthMeters => $composableBuilder(
    column: $table.minTripLengthMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freeTripsUsed => $composableBuilder(
    column: $table.freeTripsUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freeTripLimit => $composableBuilder(
    column: $table.freeTripLimit,
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

  ColumnOrderings<bool> get oemAdviceShown => $composableBuilder(
    column: $table.oemAdviceShown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bgLocationDisclosureAcked => $composableBuilder(
    column: $table.bgLocationDisclosureAcked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedGoalKmh => $composableBuilder(
    column: $table.speedGoalKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceGoalKm => $composableBuilder(
    column: $table.distanceGoalKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$LegacyAppDatabaseV10, $UserSettingsTable> {
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

  GeneratedColumn<double> get minTripLengthMeters => $composableBuilder(
    column: $table.minTripLengthMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get freeTripsUsed => $composableBuilder(
    column: $table.freeTripsUsed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get freeTripLimit => $composableBuilder(
    column: $table.freeTripLimit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPro =>
      $composableBuilder(column: $table.isPro, builder: (column) => column);

  GeneratedColumn<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get oemAdviceShown => $composableBuilder(
    column: $table.oemAdviceShown,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bgLocationDisclosureAcked => $composableBuilder(
    column: $table.bgLocationDisclosureAcked,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speedGoalKmh => $composableBuilder(
    column: $table.speedGoalKmh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceGoalKm => $composableBuilder(
    column: $table.distanceGoalKm,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserSettingsTableTableManager
    extends
        RootTableManager<
          _$LegacyAppDatabaseV10,
          $UserSettingsTable,
          UserSettingsRow,
          $$UserSettingsTableFilterComposer,
          $$UserSettingsTableOrderingComposer,
          $$UserSettingsTableAnnotationComposer,
          $$UserSettingsTableCreateCompanionBuilder,
          $$UserSettingsTableUpdateCompanionBuilder,
          (
            UserSettingsRow,
            BaseReferences<
              _$LegacyAppDatabaseV10,
              $UserSettingsTable,
              UserSettingsRow
            >,
          ),
          UserSettingsRow,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableManager(
    _$LegacyAppDatabaseV10 db,
    $UserSettingsTable table,
  ) : super(
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
                Value<double> minTripLengthMeters = const Value.absent(),
                Value<int> freeTripsUsed = const Value.absent(),
                Value<int?> freeTripLimit = const Value.absent(),
                Value<bool> isPro = const Value.absent(),
                Value<bool> onboardingComplete = const Value.absent(),
                Value<bool> oemAdviceShown = const Value.absent(),
                Value<bool> bgLocationDisclosureAcked = const Value.absent(),
                Value<double?> speedGoalKmh = const Value.absent(),
                Value<double?> distanceGoalKm = const Value.absent(),
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
                minTripLengthMeters: minTripLengthMeters,
                freeTripsUsed: freeTripsUsed,
                freeTripLimit: freeTripLimit,
                isPro: isPro,
                onboardingComplete: onboardingComplete,
                oemAdviceShown: oemAdviceShown,
                bgLocationDisclosureAcked: bgLocationDisclosureAcked,
                speedGoalKmh: speedGoalKmh,
                distanceGoalKm: distanceGoalKm,
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
                Value<double> minTripLengthMeters = const Value.absent(),
                Value<int> freeTripsUsed = const Value.absent(),
                Value<int?> freeTripLimit = const Value.absent(),
                Value<bool> isPro = const Value.absent(),
                Value<bool> onboardingComplete = const Value.absent(),
                Value<bool> oemAdviceShown = const Value.absent(),
                Value<bool> bgLocationDisclosureAcked = const Value.absent(),
                Value<double?> speedGoalKmh = const Value.absent(),
                Value<double?> distanceGoalKm = const Value.absent(),
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
                minTripLengthMeters: minTripLengthMeters,
                freeTripsUsed: freeTripsUsed,
                freeTripLimit: freeTripLimit,
                isPro: isPro,
                onboardingComplete: onboardingComplete,
                oemAdviceShown: oemAdviceShown,
                bgLocationDisclosureAcked: bgLocationDisclosureAcked,
                speedGoalKmh: speedGoalKmh,
                distanceGoalKm: distanceGoalKm,
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
      _$LegacyAppDatabaseV10,
      $UserSettingsTable,
      UserSettingsRow,
      $$UserSettingsTableFilterComposer,
      $$UserSettingsTableOrderingComposer,
      $$UserSettingsTableAnnotationComposer,
      $$UserSettingsTableCreateCompanionBuilder,
      $$UserSettingsTableUpdateCompanionBuilder,
      (
        UserSettingsRow,
        BaseReferences<
          _$LegacyAppDatabaseV10,
          $UserSettingsTable,
          UserSettingsRow
        >,
      ),
      UserSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$LiveTripsTableCreateCompanionBuilder =
    LiveTripsCompanion Function({
      Value<int> id,
      required String uid,
      Value<String> status,
      required DateTime startedAt,
      Value<double> distanceKm,
      Value<double> topSpeedKmh,
      Value<double> avgSpeedKmh,
      Value<int> durationSeconds,
      Value<double> maxGforce,
      Value<int> hardCornersCount,
      Value<int> hardBrakesCount,
      Value<int> interruptionCount,
      Value<bool> wasPaused,
      required DateTime updatedAt,
    });
typedef $$LiveTripsTableUpdateCompanionBuilder =
    LiveTripsCompanion Function({
      Value<int> id,
      Value<String> uid,
      Value<String> status,
      Value<DateTime> startedAt,
      Value<double> distanceKm,
      Value<double> topSpeedKmh,
      Value<double> avgSpeedKmh,
      Value<int> durationSeconds,
      Value<double> maxGforce,
      Value<int> hardCornersCount,
      Value<int> hardBrakesCount,
      Value<int> interruptionCount,
      Value<bool> wasPaused,
      Value<DateTime> updatedAt,
    });

class $$LiveTripsTableFilterComposer
    extends Composer<_$LegacyAppDatabaseV10, $LiveTripsTable> {
  $$LiveTripsTableFilterComposer({
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
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

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
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

  ColumnFilters<int> get interruptionCount => $composableBuilder(
    column: $table.interruptionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasPaused => $composableBuilder(
    column: $table.wasPaused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LiveTripsTableOrderingComposer
    extends Composer<_$LegacyAppDatabaseV10, $LiveTripsTable> {
  $$LiveTripsTableOrderingComposer({
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
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

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
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

  ColumnOrderings<int> get interruptionCount => $composableBuilder(
    column: $table.interruptionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasPaused => $composableBuilder(
    column: $table.wasPaused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LiveTripsTableAnnotationComposer
    extends Composer<_$LegacyAppDatabaseV10, $LiveTripsTable> {
  $$LiveTripsTableAnnotationComposer({
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

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get topSpeedKmh => $composableBuilder(
    column: $table.topSpeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgSpeedKmh => $composableBuilder(
    column: $table.avgSpeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
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

  GeneratedColumn<int> get interruptionCount => $composableBuilder(
    column: $table.interruptionCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasPaused =>
      $composableBuilder(column: $table.wasPaused, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LiveTripsTableTableManager
    extends
        RootTableManager<
          _$LegacyAppDatabaseV10,
          $LiveTripsTable,
          LiveTripRow,
          $$LiveTripsTableFilterComposer,
          $$LiveTripsTableOrderingComposer,
          $$LiveTripsTableAnnotationComposer,
          $$LiveTripsTableCreateCompanionBuilder,
          $$LiveTripsTableUpdateCompanionBuilder,
          (
            LiveTripRow,
            BaseReferences<
              _$LegacyAppDatabaseV10,
              $LiveTripsTable,
              LiveTripRow
            >,
          ),
          LiveTripRow,
          PrefetchHooks Function()
        > {
  $$LiveTripsTableTableManager(_$LegacyAppDatabaseV10 db, $LiveTripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiveTripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiveTripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LiveTripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<double> distanceKm = const Value.absent(),
                Value<double> topSpeedKmh = const Value.absent(),
                Value<double> avgSpeedKmh = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double> maxGforce = const Value.absent(),
                Value<int> hardCornersCount = const Value.absent(),
                Value<int> hardBrakesCount = const Value.absent(),
                Value<int> interruptionCount = const Value.absent(),
                Value<bool> wasPaused = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LiveTripsCompanion(
                id: id,
                uid: uid,
                status: status,
                startedAt: startedAt,
                distanceKm: distanceKm,
                topSpeedKmh: topSpeedKmh,
                avgSpeedKmh: avgSpeedKmh,
                durationSeconds: durationSeconds,
                maxGforce: maxGforce,
                hardCornersCount: hardCornersCount,
                hardBrakesCount: hardBrakesCount,
                interruptionCount: interruptionCount,
                wasPaused: wasPaused,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uid,
                Value<String> status = const Value.absent(),
                required DateTime startedAt,
                Value<double> distanceKm = const Value.absent(),
                Value<double> topSpeedKmh = const Value.absent(),
                Value<double> avgSpeedKmh = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double> maxGforce = const Value.absent(),
                Value<int> hardCornersCount = const Value.absent(),
                Value<int> hardBrakesCount = const Value.absent(),
                Value<int> interruptionCount = const Value.absent(),
                Value<bool> wasPaused = const Value.absent(),
                required DateTime updatedAt,
              }) => LiveTripsCompanion.insert(
                id: id,
                uid: uid,
                status: status,
                startedAt: startedAt,
                distanceKm: distanceKm,
                topSpeedKmh: topSpeedKmh,
                avgSpeedKmh: avgSpeedKmh,
                durationSeconds: durationSeconds,
                maxGforce: maxGforce,
                hardCornersCount: hardCornersCount,
                hardBrakesCount: hardBrakesCount,
                interruptionCount: interruptionCount,
                wasPaused: wasPaused,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LiveTripsTableProcessedTableManager =
    ProcessedTableManager<
      _$LegacyAppDatabaseV10,
      $LiveTripsTable,
      LiveTripRow,
      $$LiveTripsTableFilterComposer,
      $$LiveTripsTableOrderingComposer,
      $$LiveTripsTableAnnotationComposer,
      $$LiveTripsTableCreateCompanionBuilder,
      $$LiveTripsTableUpdateCompanionBuilder,
      (
        LiveTripRow,
        BaseReferences<_$LegacyAppDatabaseV10, $LiveTripsTable, LiveTripRow>,
      ),
      LiveTripRow,
      PrefetchHooks Function()
    >;
typedef $$LiveWaypointsTableCreateCompanionBuilder =
    LiveWaypointsCompanion Function({
      Value<int> id,
      required int tripLocalId,
      required double lat,
      required double lng,
      required double speedKmh,
      required double accuracyMeters,
      required DateTime timestamp,
    });
typedef $$LiveWaypointsTableUpdateCompanionBuilder =
    LiveWaypointsCompanion Function({
      Value<int> id,
      Value<int> tripLocalId,
      Value<double> lat,
      Value<double> lng,
      Value<double> speedKmh,
      Value<double> accuracyMeters,
      Value<DateTime> timestamp,
    });

class $$LiveWaypointsTableFilterComposer
    extends Composer<_$LegacyAppDatabaseV10, $LiveWaypointsTable> {
  $$LiveWaypointsTableFilterComposer({
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

  ColumnFilters<int> get tripLocalId => $composableBuilder(
    column: $table.tripLocalId,
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
}

class $$LiveWaypointsTableOrderingComposer
    extends Composer<_$LegacyAppDatabaseV10, $LiveWaypointsTable> {
  $$LiveWaypointsTableOrderingComposer({
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

  ColumnOrderings<int> get tripLocalId => $composableBuilder(
    column: $table.tripLocalId,
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
}

class $$LiveWaypointsTableAnnotationComposer
    extends Composer<_$LegacyAppDatabaseV10, $LiveWaypointsTable> {
  $$LiveWaypointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tripLocalId => $composableBuilder(
    column: $table.tripLocalId,
    builder: (column) => column,
  );

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
}

class $$LiveWaypointsTableTableManager
    extends
        RootTableManager<
          _$LegacyAppDatabaseV10,
          $LiveWaypointsTable,
          LiveWaypointRow,
          $$LiveWaypointsTableFilterComposer,
          $$LiveWaypointsTableOrderingComposer,
          $$LiveWaypointsTableAnnotationComposer,
          $$LiveWaypointsTableCreateCompanionBuilder,
          $$LiveWaypointsTableUpdateCompanionBuilder,
          (
            LiveWaypointRow,
            BaseReferences<
              _$LegacyAppDatabaseV10,
              $LiveWaypointsTable,
              LiveWaypointRow
            >,
          ),
          LiveWaypointRow,
          PrefetchHooks Function()
        > {
  $$LiveWaypointsTableTableManager(
    _$LegacyAppDatabaseV10 db,
    $LiveWaypointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiveWaypointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiveWaypointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LiveWaypointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> tripLocalId = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double> speedKmh = const Value.absent(),
                Value<double> accuracyMeters = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => LiveWaypointsCompanion(
                id: id,
                tripLocalId: tripLocalId,
                lat: lat,
                lng: lng,
                speedKmh: speedKmh,
                accuracyMeters: accuracyMeters,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tripLocalId,
                required double lat,
                required double lng,
                required double speedKmh,
                required double accuracyMeters,
                required DateTime timestamp,
              }) => LiveWaypointsCompanion.insert(
                id: id,
                tripLocalId: tripLocalId,
                lat: lat,
                lng: lng,
                speedKmh: speedKmh,
                accuracyMeters: accuracyMeters,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LiveWaypointsTableProcessedTableManager =
    ProcessedTableManager<
      _$LegacyAppDatabaseV10,
      $LiveWaypointsTable,
      LiveWaypointRow,
      $$LiveWaypointsTableFilterComposer,
      $$LiveWaypointsTableOrderingComposer,
      $$LiveWaypointsTableAnnotationComposer,
      $$LiveWaypointsTableCreateCompanionBuilder,
      $$LiveWaypointsTableUpdateCompanionBuilder,
      (
        LiveWaypointRow,
        BaseReferences<
          _$LegacyAppDatabaseV10,
          $LiveWaypointsTable,
          LiveWaypointRow
        >,
      ),
      LiveWaypointRow,
      PrefetchHooks Function()
    >;

class $LegacyAppDatabaseV10Manager {
  final _$LegacyAppDatabaseV10 _db;
  $LegacyAppDatabaseV10Manager(this._db);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$WaypointsTableTableManager get waypoints =>
      $$WaypointsTableTableManager(_db, _db.waypoints);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
  $$LiveTripsTableTableManager get liveTrips =>
      $$LiveTripsTableTableManager(_db, _db.liveTrips);
  $$LiveWaypointsTableTableManager get liveWaypoints =>
      $$LiveWaypointsTableTableManager(_db, _db.liveWaypoints);
}
