import 'package:drive_rank/core/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// Global service locator. Don't reach for this inside widgets — wire
/// dependencies through BLoCs/repositories instead. The router and bootstrap
/// are the legitimate readers.
final GetIt getIt = GetIt.instance;

/// Production environment marker. A second env (`test`) can register fakes.
const String prodEnv = Environment.prod;

@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: false,
  asExtension: false,
)
Future<void> configureDependencies({String environment = prodEnv}) async {
  $initGetIt(getIt, environment: environment);
  // Settle any pending async singleton initialisations (e.g. Drift, services
  // that hit disk on construction) before the first widget builds.
  await getIt.allReady();
}
