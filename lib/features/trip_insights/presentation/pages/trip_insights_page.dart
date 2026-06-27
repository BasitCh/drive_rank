import 'dart:async';

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/card_export_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_bloc.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_event.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_state.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/insights_social_card.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Trip Insights — the premium, screenshot-ready analytics surface.
///
/// Same widget tree as the share output: the in-app page wraps the
/// composite `InsightsSocialCard` in a `Scaffold` + chrome, and the
/// share button captures the same boundary off-screen. One source of
/// truth means the post-share image matches what the user just saw.
class TripInsightsPage extends StatelessWidget {
  const TripInsightsPage({required this.tripId, super.key});

  final int tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InsightsBloc>(
      create: (_) =>
          getIt<InsightsBloc>()..add(InsightsLoaded(tripId)),
      child: const _TripInsightsBody(),
    );
  }
}

class _TripInsightsBody extends StatefulWidget {
  const _TripInsightsBody();

  @override
  State<_TripInsightsBody> createState() => _TripInsightsBodyState();
}

class _TripInsightsBodyState extends State<_TripInsightsBody> {
  /// Wraps the composite social card so `CardExportService.capture`
  /// can take a PNG of exactly what's on screen.
  final GlobalKey _boundaryKey = GlobalKey();

  /// Resolved once on first build — used by the brand header copy and
  /// the share filename. Loaded async so the first frame doesn't block;
  /// header just shows the bare date until it lands.
  String? _vehicleLabel;

  @override
  void initState() {
    super.initState();
    _resolveVehicleLabel();
  }

  Future<void> _resolveVehicleLabel() async {
    try {
      final settings = await getIt<UserSettingsRepository>().read();
      if (!mounted) return;
      final make = settings.carMake;
      final model = settings.carModel;
      final label = (make.isEmpty && model.isEmpty)
          ? 'My Car'
          : '$make $model'.trim();
      setState(() => _vehicleLabel = label);
    } catch (_) {
      if (mounted) setState(() => _vehicleLabel = 'My Car');
    }
  }

  Future<void> _onShare(BuildContext context) async {
    context.read<InsightsBloc>().add(const InsightsShareRequested());
    // Map tiles can take a beat to settle on first show — a 1200ms
    // wait greatly reduces grey-square screenshots on slower networks
    // (worth the perceived latency for the marketing screenshot).
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!context.mounted) {
      return;
    }
    final ok = await getIt<CardExportService>().captureAndShare(
      _boundaryKey,
      subject: AppStrings.tripInsightsShareSubject,
    );
    if (ok) {
      unawaited(
        getIt<TelemetryService>().track(TelemetryEvents.insightsExported),
      );
    }
    if (!context.mounted) return;
    context.read<InsightsBloc>().add(const InsightsShareFinished());
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not capture insights card.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<InsightsBloc, InsightsState>(
          builder: (context, state) {
            return Column(
              children: [
                _Header(
                  isSharing: state.isSharing,
                  canShare: state.status == InsightsStatus.ready,
                  onShare: () => _onShare(context),
                ),
                Expanded(
                  child: switch (state.status) {
                    InsightsStatus.loading => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.teal,
                        ),
                      ),
                    InsightsStatus.notFound ||
                    InsightsStatus.error =>
                      const _ErrorSurface(),
                    InsightsStatus.ready => SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          0,
                          0,
                          AppSpacing.xxl,
                        ),
                        child: RepaintBoundary(
                          key: _boundaryKey,
                          child: InsightsSocialCard(
                            bundle: state.bundle!,
                            locale: locale,
                            vehicleLabel: _vehicleLabel ?? 'My Car',
                          ),
                        ),
                      ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isSharing,
    required this.canShare,
    required this.onShare,
  });

  final bool isSharing;
  final bool canShare;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          _CircleButton(
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              AppStrings.tripInsightsTitle,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _ShareCtaButton(
            isSharing: isSharing,
            enabled: canShare,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 30, height: 30, child: Center(child: child)),
      ),
    );
  }
}

class _ShareCtaButton extends StatelessWidget {
  const _ShareCtaButton({
    required this.isSharing,
    required this.enabled,
    required this.onTap,
  });

  final bool isSharing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.teal : AppColors.card,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: (isSharing || !enabled) ? null : onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSharing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: AppColors.bg,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(
                  Icons.ios_share_rounded,
                  color: enabled ? AppColors.bg : AppColors.textTertiary,
                  size: 14,
                ),
              const SizedBox(width: 4),
              Text(
                AppStrings.tripInsightsShare,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: enabled ? AppColors.bg : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorSurface extends StatelessWidget {
  const _ErrorSurface();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          AppStrings.tripInsightsLoadError,
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
