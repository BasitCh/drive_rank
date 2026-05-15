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
import 'package:drive_rank/core/services/locale_service.dart' as _i447;
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
  gh.lazySingleton<_i447.LocaleService>(() => _i447.LocaleService());
  return getIt;
}
