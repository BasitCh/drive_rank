import 'dart:async';

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/card_export_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/card_kind.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_bloc.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_event.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_state.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/card_chrome.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/performance_card_view.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Performance share page — hero strip + energetic Speed Over Time
/// chart, sized as a single screenshot. Same widget tree on-screen as
/// in the exported image, so what the user previews is exactly what
/// share_plus posts.
class PerformanceCardPage extends StatelessWidget {
  const PerformanceCardPage({required this.tripId, super.key});

  final int tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InsightsBloc>(
      create: (_) => getIt<InsightsBloc>()
        ..add(InsightsLoaded(
          tripId: tripId,
          kind: CardKind.performance,
        )),
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final GlobalKey _boundaryKey = GlobalKey();
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
    context
        .read<InsightsBloc>()
        .add(const InsightsShareRequested(CardKind.performance));
    // Let the spinner paint + give fl_chart's gradient one more frame
    // to settle before we hand the boundary to toImage. Shorter than
    // the Journey card delay because there are no tiles to wait on.
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!context.mounted) return;
    final ok = await getIt<CardExportService>().captureAndShare(
      _boundaryKey,
      subject: AppStrings.performanceCardShareSubject,
    );
    if (ok) {
      unawaited(
        getIt<TelemetryService>().track(
          TelemetryEvents.performanceCardExported,
        ),
      );
    }
    if (!context.mounted) return;
    context.read<InsightsBloc>().add(const InsightsShareFinished());
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not capture performance card.'),
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
                CardChromeBar(
                  title: AppStrings.performanceCardTitle,
                  shareLabel: AppStrings.performanceCardShareCta,
                  isSharing: state.isSharing,
                  onShare: state.status == InsightsStatus.ready
                      ? () => _onShare(context)
                      : () {},
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
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.xxl,
                        ),
                        child: RepaintBoundary(
                          key: _boundaryKey,
                          child: PerformanceCardView(
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

class _ErrorSurface extends StatelessWidget {
  const _ErrorSurface();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          AppStrings.performanceCardLoadError,
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
