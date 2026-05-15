import 'package:drive_rank/bootstrap.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/app_router.dart';
import 'package:drive_rank/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await bootstrap(() => const DriveRankApp());
}

class DriveRankApp extends StatelessWidget {
  const DriveRankApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = getIt<AppRouter>().router;

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
