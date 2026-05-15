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
import 'package:drive_rank/core/services/gps_service.dart' as _i375;
import 'package:drive_rank/core/services/locale_service.dart' as _i447;
import 'package:drive_rank/core/services/permission_service.dart' as _i576;
import 'package:drive_rank/core/services/sensor_service.dart' as _i125;
import 'package:drive_rank/features/onboarding/data/repositories/car_repository_impl.dart'
    as _i639;
import 'package:drive_rank/features/onboarding/domain/repositories/car_repository.dart'
    as _i972;
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart'
    as _i162;
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_bloc.dart'
    as _i687;
import 'package:drive_rank/shared/repositories/user_settings_repository.dart'
    as _i727;
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
  gh.lazySingleton<_i447.LocaleService>(() => _i447.LocaleService());
  gh.lazySingleton<_i576.PermissionService>(() => _i576.PermissionService());
  gh.lazySingleton<_i972.CarRepository>(() => _i639.AssetCarRepository());
  gh.lazySingleton<_i727.UserSettingsRepository>(
    () => _i727.UserSettingsRepository(
      gh<_i425.AppDatabase>(),
      gh<_i447.LocaleService>(),
    ),
  );
  gh.factory<_i687.TrackingBloc>(
    () => _i687.TrackingBloc(
      gh<_i375.GpsService>(),
      gh<_i125.SensorService>(),
      gh<_i576.PermissionService>(),
    ),
  );
  gh.factory<_i162.OnboardingBloc>(
    () => _i162.OnboardingBloc(
      gh<_i972.CarRepository>(),
      gh<_i727.UserSettingsRepository>(),
      gh<_i447.LocaleService>(),
      gh<_i576.PermissionService>(),
    ),
  );
  return getIt;
}
