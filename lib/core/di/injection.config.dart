// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:device_info_plus/device_info_plus.dart' as _i833;
import 'package:drive_rank/core/database/app_database.dart' as _i425;
import 'package:drive_rank/core/di/injection_module.dart' as _i953;
import 'package:drive_rank/core/network/network_info.dart' as _i721;
import 'package:drive_rank/core/router/app_router.dart' as _i901;
import 'package:drive_rank/core/services/account_deletion_service.dart'
    as _i427;
import 'package:drive_rank/core/services/active_trip_store.dart' as _i766;
import 'package:drive_rank/core/services/auth_service.dart' as _i1009;
import 'package:drive_rank/core/services/battery_optimization_service.dart'
    as _i595;
import 'package:drive_rank/core/services/card_export_service.dart' as _i261;
import 'package:drive_rank/core/services/debug_seed_service.dart' as _i411;
import 'package:drive_rank/core/services/device_identity_service.dart' as _i529;
import 'package:drive_rank/core/services/free_trip_counter_service.dart'
    as _i1058;
import 'package:drive_rank/core/services/geocoding_service.dart' as _i853;
import 'package:drive_rank/core/services/gps_service.dart' as _i375;
import 'package:drive_rank/core/services/live_trip_notification_service.dart'
    as _i201;
import 'package:drive_rank/core/services/local_notifications_gateway.dart'
    as _i750;
import 'package:drive_rank/core/services/locale_service.dart' as _i447;
import 'package:drive_rank/core/services/oem_battery_advisor.dart' as _i207;
import 'package:drive_rank/core/services/paywall_service.dart' as _i495;
import 'package:drive_rank/core/services/permission_service.dart' as _i576;
import 'package:drive_rank/core/services/push_service.dart' as _i488;
import 'package:drive_rank/core/services/retention_notification_service.dart'
    as _i183;
import 'package:drive_rank/core/services/sensor_service.dart' as _i125;
import 'package:drive_rank/core/services/telemetry_service.dart' as _i46;
import 'package:drive_rank/features/history/presentation/bloc/history_bloc.dart'
    as _i586;
import 'package:drive_rank/features/onboarding/data/repositories/car_repository_impl.dart'
    as _i639;
import 'package:drive_rank/features/onboarding/domain/repositories/car_repository.dart'
    as _i972;
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart'
    as _i162;
import 'package:drive_rank/features/paywall/presentation/bloc/paywall_bloc.dart'
    as _i284;
import 'package:drive_rank/features/personal_bests/data/personal_bests_repository.dart'
    as _i244;
import 'package:drive_rank/features/personal_bests/presentation/bloc/personal_bests_bloc.dart'
    as _i314;
import 'package:drive_rank/features/profile/presentation/bloc/profile_bloc.dart'
    as _i868;
import 'package:drive_rank/features/social/data/datasources/social_local_data_source.dart'
    as _i866;
import 'package:drive_rank/features/social/data/processors/local_social_trip_processor.dart'
    as _i319;
import 'package:drive_rank/features/social/data/repositories/social_repository_impl.dart'
    as _i621;
import 'package:drive_rank/features/social/data/services/competition_mirror_sink.dart'
    as _i800;
import 'package:drive_rank/features/social/data/services/competition_value_publisher.dart'
    as _i1058;
import 'package:drive_rank/features/social/data/services/friends_sync_service.dart'
    as _i709;
import 'package:drive_rank/features/social/data/services/social_directory.dart'
    as _i408;
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart'
    as _i247;
import 'package:drive_rank/features/social/domain/usecases/compare_with_benchmark.dart'
    as _i1018;
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart'
    as _i163;
import 'package:drive_rank/features/social/domain/usecases/create_target.dart'
    as _i302;
import 'package:drive_rank/features/social/domain/usecases/get_global_leaderboard.dart'
    as _i932;
import 'package:drive_rank/features/social/domain/usecases/get_qualifying_days.dart'
    as _i218;
import 'package:drive_rank/features/social/domain/usecases/get_targets.dart'
    as _i683;
import 'package:drive_rank/features/social/domain/usecases/get_trip_rank_change.dart'
    as _i593;
import 'package:drive_rank/features/social/domain/usecases/refresh_target_progress.dart'
    as _i717;
import 'package:drive_rank/features/social/domain/usecases/social_trip_processor.dart'
    as _i804;
import 'package:drive_rank/features/social/presentation/bloc/rankings_bloc.dart'
    as _i840;
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_bloc.dart'
    as _i687;
import 'package:drive_rank/features/trip_insights/data/insights_repository.dart'
    as _i337;
import 'package:drive_rank/features/trip_insights/domain/usecases/build_insights.dart'
    as _i486;
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_bloc.dart'
    as _i723;
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_social_bloc.dart'
    as _i121;
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_bloc.dart'
    as _i990;
import 'package:drive_rank/shared/repositories/trip_repository.dart' as _i634;
import 'package:drive_rank/shared/repositories/user_settings_repository.dart'
    as _i727;
import 'package:drive_rank/shared/services/car_photo_service.dart' as _i405;
import 'package:drive_rank/shared/services/cloud_sync_service.dart' as _i221;
import 'package:drive_rank/shared/services/public_profile_service.dart'
    as _i364;
import 'package:drive_rank/shared/services/remote_trip_sink.dart' as _i88;
import 'package:drive_rank/shared/services/road_segment_service.dart' as _i928;
import 'package:drive_rank/shared/services/sync_manager.dart' as _i830;
import 'package:drive_rank/shared/services/territory_stats_service.dart'
    as _i970;
import 'package:drive_rank/shared/services/trip_stats_service.dart' as _i67;
import 'package:drive_rank/shared/services/username_reservation_service.dart'
    as _i343;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final injectionModule = _$InjectionModule();
  gh.singleton<_i425.AppDatabase>(() => _i425.AppDatabase());
  gh.singleton<_i901.AppRouter>(() => _i901.AppRouter());
  gh.singleton<_i375.GpsService>(() => _i375.GpsService());
  gh.singleton<_i125.SensorService>(() => _i125.SensorService());
  gh.lazySingleton<_i833.DeviceInfoPlugin>(
    () => injectionModule.deviceInfoPlugin(),
  );
  gh.lazySingleton<_i895.Connectivity>(() => injectionModule.connectivity());
  gh.lazySingleton<_i595.BatteryOptimizationService>(
    () => const _i595.BatteryOptimizationService(),
  );
  gh.lazySingleton<_i261.CardExportService>(() => _i261.CardExportService());
  gh.lazySingleton<_i529.DeviceIdentityService>(
    () => _i529.DeviceIdentityService(),
  );
  gh.lazySingleton<_i853.GeocodingService>(() => _i853.GeocodingService());
  gh.lazySingleton<_i750.LocalNotificationsGateway>(
    () => _i750.LocalNotificationsGateway(),
  );
  gh.lazySingleton<_i447.LocaleService>(() => _i447.LocaleService());
  gh.lazySingleton<_i576.PermissionService>(() => _i576.PermissionService());
  gh.lazySingleton<_i405.CarPhotoService>(() => _i405.CarPhotoService());
  gh.lazySingleton<_i928.RoadSegmentService>(() => _i928.RoadSegmentService());
  gh.lazySingleton<_i972.CarRepository>(() => _i639.AssetCarRepository());
  gh.lazySingleton<_i207.OemBatteryAdvisor>(
    () => _i207.OemBatteryAdvisor(gh<_i833.DeviceInfoPlugin>()),
  );
  gh.lazySingleton<_i488.PushService>(() => injectionModule.noopPush());
  gh.lazySingleton<_i408.SocialDirectory>(
    () => const _i408.NoopSocialDirectory(),
  );
  gh.factory<_i486.BuildInsights>(
    () => _i486.BuildInsights(gh<_i447.LocaleService>()),
  );
  gh.lazySingleton<_i46.TelemetryService>(
    () => injectionModule.consoleTelemetry(),
  );
  gh.lazySingleton<_i495.PaywallService>(
    () => _i495.PreviewPaywallService(gh<_i447.LocaleService>()),
  );
  gh.lazySingleton<_i800.CompetitionMirrorSink>(
    () => const _i800.NoopCompetitionMirrorSink(),
  );
  gh.lazySingleton<_i88.RemoteTripSink>(() => const _i88.NoopRemoteTripSink());
  gh.lazySingleton<_i163.CompetitionMetricCalculator>(
    () => const _i163.DefaultCompetitionMetricCalculator(),
  );
  gh.lazySingleton<_i364.PublicProfileService>(
    () => _i364.NoopPublicProfileService(),
  );
  gh.lazySingleton<_i1058.FreeTripCounterService>(
    () => _i1058.FreeTripCounterService(gh<_i529.DeviceIdentityService>()),
  );
  gh.lazySingleton<_i1009.AuthService>(() => injectionModule.anonymousAuth());
  gh.lazySingleton<_i343.UsernameReservationService>(
    () => const _i343.NoopUsernameReservationService(),
  );
  gh.lazySingleton<_i727.UserSettingsRepository>(
    () => _i727.UserSettingsRepository(
      gh<_i425.AppDatabase>(),
      gh<_i447.LocaleService>(),
      gh<_i1058.FreeTripCounterService>(),
    ),
  );
  gh.lazySingleton<_i721.NetworkInfo>(
    () => _i721.NetworkInfo(gh<_i895.Connectivity>()),
  );
  gh.lazySingleton<_i634.TripRepository>(
    () => _i634.TripRepository(
      gh<_i425.AppDatabase>(),
      gh<_i853.GeocodingService>(),
    ),
  );
  gh.lazySingleton<_i221.CloudSyncService>(
    () => _i221.CloudSyncService(
      gh<_i634.TripRepository>(),
      gh<_i405.CarPhotoService>(),
    ),
  );
  gh.singleton<_i830.SyncManager>(
    () => _i830.SyncManager(
      gh<_i425.AppDatabase>(),
      gh<_i721.NetworkInfo>(),
      gh<_i46.TelemetryService>(),
    ),
  );
  gh.lazySingleton<_i201.LiveTripNotificationService>(
    () => _i201.LiveTripNotificationService(
      gh<_i447.LocaleService>(),
      gh<_i750.LocalNotificationsGateway>(),
    ),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i411.DebugSeedService>(
    () => _i411.DebugSeedService(
      gh<_i634.TripRepository>(),
      gh<_i727.UserSettingsRepository>(),
    ),
  );
  gh.lazySingleton<_i244.PersonalBestsRepository>(
    () => _i244.PersonalBestsRepository(
      gh<_i634.TripRepository>(),
      gh<_i727.UserSettingsRepository>(),
    ),
  );
  gh.factory<_i586.HistoryBloc>(
    () => _i586.HistoryBloc(
      gh<_i634.TripRepository>(),
      gh<_i727.UserSettingsRepository>(),
    ),
  );
  gh.lazySingleton<_i766.ActiveTripStore>(
    () => _i766.ActiveTripStore(gh<_i425.AppDatabase>()),
  );
  gh.lazySingleton<_i866.SocialLocalDataSource>(
    () => _i866.SocialLocalDataSource(gh<_i425.AppDatabase>()),
  );
  gh.lazySingleton<_i427.AccountDeletionService>(
    () => _i427.AccountDeletionService(
      gh<_i634.TripRepository>(),
      gh<_i727.UserSettingsRepository>(),
      gh<_i766.ActiveTripStore>(),
      gh<_i1058.FreeTripCounterService>(),
      gh<_i1009.AuthService>(),
      gh<_i221.CloudSyncService>(),
    ),
  );
  gh.factory<_i284.PaywallBloc>(
    () => _i284.PaywallBloc(
      gh<_i495.PaywallService>(),
      gh<_i727.UserSettingsRepository>(),
      gh<_i634.TripRepository>(),
      gh<_i46.TelemetryService>(),
      gh<_i488.PushService>(),
    ),
  );
  gh.lazySingleton<_i337.InsightsRepository>(
    () => _i337.InsightsRepository(
      gh<_i425.AppDatabase>(),
      gh<_i634.TripRepository>(),
      gh<_i486.BuildInsights>(),
    ),
  );
  gh.lazySingleton<_i709.FriendsSyncService>(
    () => _i709.FriendsSyncService(
      gh<_i866.SocialLocalDataSource>(),
      gh<_i727.UserSettingsRepository>(),
    ),
  );
  gh.factory<_i314.PersonalBestsBloc>(
    () => _i314.PersonalBestsBloc(gh<_i244.PersonalBestsRepository>()),
  );
  gh.factory<_i162.OnboardingBloc>(
    () => _i162.OnboardingBloc(
      gh<_i972.CarRepository>(),
      gh<_i727.UserSettingsRepository>(),
      gh<_i447.LocaleService>(),
      gh<_i576.PermissionService>(),
      gh<_i46.TelemetryService>(),
      gh<_i488.PushService>(),
      gh<_i343.UsernameReservationService>(),
    ),
  );
  gh.lazySingleton<_i183.RetentionNotificationService>(
    () => _i183.RetentionNotificationService(
      gh<_i750.LocalNotificationsGateway>(),
      gh<_i447.LocaleService>(),
      gh<_i576.PermissionService>(),
      gh<_i46.TelemetryService>(),
      gh<_i634.TripRepository>(),
    ),
  );
  gh.factory<_i990.TripSummaryBloc>(
    () => _i990.TripSummaryBloc(
      gh<_i634.TripRepository>(),
      gh<_i727.UserSettingsRepository>(),
      gh<_i261.CardExportService>(),
    ),
  );
  gh.lazySingleton<_i970.TerritoryStatsService>(
    () => _i970.TerritoryStatsService(gh<_i634.TripRepository>()),
  );
  gh.lazySingleton<_i67.TripStatsService>(
    () => _i67.TripStatsService(gh<_i634.TripRepository>()),
  );
  gh.factory<_i723.InsightsBloc>(
    () => _i723.InsightsBloc(
      gh<_i337.InsightsRepository>(),
      gh<_i46.TelemetryService>(),
    ),
  );
  gh.lazySingleton<_i247.SocialRepository>(
    () => _i621.SocialRepositoryImpl(gh<_i866.SocialLocalDataSource>()),
  );
  gh.factory<_i868.ProfileBloc>(
    () => _i868.ProfileBloc(
      gh<_i727.UserSettingsRepository>(),
      gh<_i67.TripStatsService>(),
      gh<_i970.TerritoryStatsService>(),
    ),
  );
  gh.lazySingleton<_i1058.CompetitionValuePublisher>(
    () => _i1058.CompetitionValuePublisher(
      gh<_i727.UserSettingsRepository>(),
      gh<_i247.SocialRepository>(),
      gh<_i163.CompetitionMetricCalculator>(),
    ),
  );
  gh.factory<_i1018.CompareWithBenchmark>(
    () => _i1018.CompareWithBenchmark(
      gh<_i247.SocialRepository>(),
      gh<_i163.CompetitionMetricCalculator>(),
    ),
  );
  gh.factory<_i932.GetGlobalLeaderboard>(
    () => _i932.GetGlobalLeaderboard(
      gh<_i247.SocialRepository>(),
      gh<_i163.CompetitionMetricCalculator>(),
    ),
  );
  gh.factory<_i683.GetTargets>(
    () => _i683.GetTargets(
      gh<_i247.SocialRepository>(),
      gh<_i163.CompetitionMetricCalculator>(),
    ),
  );
  gh.factory<_i717.RefreshTargetProgress>(
    () => _i717.RefreshTargetProgress(
      gh<_i247.SocialRepository>(),
      gh<_i163.CompetitionMetricCalculator>(),
    ),
  );
  gh.lazySingleton<_i804.SocialTripProcessor>(
    () => _i319.LocalSocialTripProcessor(
      gh<_i247.SocialRepository>(),
      gh<_i163.CompetitionMetricCalculator>(),
      gh<_i717.RefreshTargetProgress>(),
    ),
  );
  gh.factory<_i218.GetQualifyingDays>(
    () => _i218.GetQualifyingDays(gh<_i247.SocialRepository>()),
  );
  gh.factory<_i687.TrackingBloc>(
    () => _i687.TrackingBloc(
      gh<_i375.GpsService>(),
      gh<_i125.SensorService>(),
      gh<_i576.PermissionService>(),
      gh<_i634.TripRepository>(),
      gh<_i727.UserSettingsRepository>(),
      gh<_i928.RoadSegmentService>(),
      gh<_i766.ActiveTripStore>(),
      gh<_i201.LiveTripNotificationService>(),
      gh<_i46.TelemetryService>(),
      gh<_i183.RetentionNotificationService>(),
      gh<_i804.SocialTripProcessor>(),
    ),
  );
  gh.factory<_i593.GetTripRankChange>(
    () => _i593.GetTripRankChange(gh<_i932.GetGlobalLeaderboard>()),
  );
  gh.factory<_i121.TripSocialBloc>(
    () => _i121.TripSocialBloc(
      gh<_i634.TripRepository>(),
      gh<_i727.UserSettingsRepository>(),
      gh<_i247.SocialRepository>(),
      gh<_i593.GetTripRankChange>(),
      gh<_i683.GetTargets>(),
    ),
  );
  gh.factory<_i302.CreateTarget>(
    () => _i302.CreateTarget(
      gh<_i247.SocialRepository>(),
      gh<_i717.RefreshTargetProgress>(),
    ),
  );
  gh.factory<_i840.RankingsBloc>(
    () => _i840.RankingsBloc(
      gh<_i727.UserSettingsRepository>(),
      gh<_i634.TripRepository>(),
      gh<_i932.GetGlobalLeaderboard>(),
      gh<_i683.GetTargets>(),
      gh<_i302.CreateTarget>(),
      gh<_i247.SocialRepository>(),
      gh<_i218.GetQualifyingDays>(),
    ),
  );
  return getIt;
}

class _$InjectionModule extends _i953.InjectionModule {}
