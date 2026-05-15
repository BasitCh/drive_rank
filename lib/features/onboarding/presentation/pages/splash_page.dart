import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Entry point — for Session 1 this just shows the wordmark and routes on.
/// The real animated 3-slide splash lives in Session 2.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Session 1: skip straight to onboarding; the redirect rule decides
      // where the user actually lands based on onboarding state.
      if (!mounted) return;
      context.go(RouteNames.onboarding);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Text(AppStrings.appName, style: AppTextStyles.brandLogo),
        ),
      ),
    );
  }
}
