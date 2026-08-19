import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/card_kind.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_bloc.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_event.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_state.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/journey_map.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Full-screen animated route replay — reached from the play button
/// on the trip detail page's map header. Reuses `JourneyMap` at full
/// size: the same speed-coloured polyline, play/pause, scrub bar,
/// 1x/2x/3x, live stats overlay, TOP SPEED badge, and re-centre button
/// already built for the (now-removed) Journey share card, just given
/// the whole screen instead of a card-sized `AspectRatio` box.
class RouteReplayPage extends StatelessWidget {
  const RouteReplayPage({required this.tripId, super.key});

  final int tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InsightsBloc>(
      create: (_) => getIt<InsightsBloc>()
        ..add(InsightsLoaded(tripId: tripId, kind: CardKind.journey)),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: FutureBuilder<VehicleType>(
                future: getIt<UserSettingsRepository>().read().then(
                  (row) => VehicleType.fromId(row.vehicleType),
                ),
                initialData: VehicleType.car,
                builder: (context, vehicleSnapshot) {
                  final vehicleType = vehicleSnapshot.data ?? VehicleType.car;
                  return BlocBuilder<InsightsBloc, InsightsState>(
                    builder: (context, state) {
                      return switch (state.status) {
                        InsightsStatus.loading => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.teal,
                          ),
                        ),
                        InsightsStatus.notFound ||
                        InsightsStatus.error => const _ErrorSurface(),
                        InsightsStatus.ready => JourneyMap(
                          bundle: state.bundle!,
                          locale: locale,
                          vehicleType: vehicleType,
                        ),
                      };
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Material(
            color: AppColors.card,
            shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.canPop() ? context.pop() : context.go('/home'),
              child: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Route Replay',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
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
          'Could not load this trip.',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
