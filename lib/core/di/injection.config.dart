// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:drive_rank/core/database/app_database.dart' as _i425;
import 'package:drive_rank/core/router/app_router.dart' as _i901;
import 'package:drive_rank/core/services/card_export_service.dart' as _i261;
import 'package:drive_rank/core/services/gps_service.dart' as _i375;
import 'package:drive_rank/core/services/locale_service.dart' as _i447;
import 'package:drive_rank/core/services/paywall_service.dart' as _i495;
import 'package:drive_rank/core/services/permission_service.dart' as _i576;
import 'package:drive_rank/core/services/sensor_service.dart' as _i125;
import 'package:drive_rank/features/history/presentation/bloc/history_bloc.dart'
    as _i586;
import 'package:drive_rank/features/leaderboard/presentation/bloc/leaderboard_bloc.dart'
    as _i505;
import 'package:drive_rank/features/onboarding/data/repositories/car_repository_impl.dart'
    as _i639;
import 'package:drive_rank/features/onboarding/domain/repositories/car_repository.dart'
    as _i972;
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart'
    as _i162;
import 'package:drive_rank/features/paywall/presentation/bloc/paywall_bloc.dart'
    as _i284;
import 'package:drive_rank/features/profile/presentation/bloc/profile_bloc.dart'
    as _i868;
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_bloc.dart'
    as _i687;
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_bloc.dart'
    as _i990;
import 'package:drive_rank/shared/repositories/leaderboard_repository.dart'
    as _i1045;
import 'package:drive_rank/shared/repositories/trip_repository.dart' as _i634;
import 'package:drive_rank/shared/repositories/user_settings_repository.dart'
    as _i727;
import 'package:drive_rank/shared/services/road_segment_service.dart' as _i928;
import 'package:drive_rank/shared/services/trip_stats_service.dart' as _i67;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  gh.singleton<_i425.AppDatabase>(() => _i425.AppDatabase());
  gh.singleton<_i901.AppRouter>(() => _i901.AppRouter());
  gh.singleton<_i375.GpsService>(() => _i375.GpsService());
  gh.singleton<_i125.SensorService>(() => _i125.SensorService());
  gh.lazySingleton<_i261.CardExportService>(() => _i261.CardExportService());
  gh.lazySingleton<_i447.LocaleService>(() => _i447.LocaleService());
  gh.lazySingleton<_i576.PermissionService>(() => _i576.PermissionService());
  gh.lazySingleton<_i928.RoadSegmentService>(() => _i928.RoadSegmentService());
  gh.lazySingleton<_i972.CarRepository>(() => _i639.AssetCarRepository());
  gh.lazySingleton<_i727.UserSettingsRepository>(
    () => _i727.UserSettingsRepository(
      gh<_i425.AppDatabase>(),
      gh<_i447.LocaleService>(),
    ),
  );
  gh.lazySingleton<_i495.PaywallService>(
    () => _i495.PreviewPaywallService(gh<_i447.LocaleService>()),
  );
  gh.factory<_i162.OnboardingBloc>(
    () => _i162.OnboardingBloc(
      gh<_i972.CarRepository>(),
      gh<_i727.UserSettingsRepository>(),
      gh<_i447.LocaleService>(),
      gh<_i576.PermissionService>(),
    ),
  );
  gh.lazySingleton<_i634.TripRepository>(
    () => _i634.TripRepository(gh<_i425.AppDatabase>()),
  );
  gh.factory<_i687.TrackingBloc>(
    () => _i687.TrackingBloc(
      gh<_i375.GpsService>(),
      gh<_i125.SensorService>(),
      gh<_i576.PermissionService>(),
      gh<_i634.TripRepository>(),
      gh<_i727.UserSettingsRepository>(),
      gh<_i928.RoadSegmentService>(),
    ),
  );
  gh.factory<_i990.TripSummaryBloc>(
    () => _i990.TripSummaryBloc(
      gh<_i634.TripRepository>(),
      gh<_i727.UserSettingsRepository>(),
      gh<_i261.CardExportService>(),
    ),
  );
  gh.factory<_i284.PaywallBloc>(
    () => _i284.PaywallBloc(
      gh<_i495.PaywallService>(),
      gh<_i727.UserSettingsRepository>(),
      gh<_i634.TripRepository>(),
    ),
  );
  gh.lazySingleton<_i67.TripStatsService>(
    () => _i67.TripStatsService(gh<_i634.TripRepository>()),
  );
  gh.lazySingleton<_i1045.LeaderboardRepository>(
    () => _i1045.MockLeaderboardRepository(
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
  gh.factory<_i868.ProfileBloc>(
    () => _i868.ProfileBloc(
      gh<_i727.UserSettingsRepository>(),
      gh<_i67.TripStatsService>(),
    ),
  );
  gh.factory<_i505.LeaderboardBloc>(
    () => _i505.LeaderboardBloc(
      gh<_i1045.LeaderboardRepository>(),
      gh<_i928.RoadSegmentService>(),
      gh<_i727.UserSettingsRepository>(),
    ),
  );
  return getIt;
}
