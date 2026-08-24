import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:drive_rank/features/profile/presentation/widgets/monthly_trend_chart.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/speed_breakdown_bar.dart';
import 'package:drive_rank/shared/models/car_category.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/models/monthly_report.dart';
import 'package:drive_rank/shared/models/territory_stats.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/widgets/car_silhouette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (_) => getIt<ProfileBloc>()..add(const ProfileLoaded()),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state.status == ProfileStatus.loading ||
                state.settings == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              );
            }
            return _Loaded(state: state, locale: locale);
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.locale});

  final ProfileState state;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    final settings = state.settings!;
    final lifetime = state.lifetime;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Header(settings: settings),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ThisMonthCard(
                monthly: state.currentMonth,
                trend: state.monthlyTrend,
                locale: locale,
                onTap: () => context.push(RouteNames.monthlyReport),
              ),
              const SizedBox(height: 10),
              _TerritoryCard(
                territory: state.territory,
                countryCode: settings.country,
                onTap: () => context.push(RouteNames.territory),
              ),
              const SizedBox(height: 10),
              _StatRow(
                left: _StatCard(
                  icon: Icons.route_rounded,
                  value: locale.formatDistance(
                    lifetime.totalDistanceKm,
                    fractionDigits: 0,
                  ),
                  label: AppStrings.profileStatTotalDistance,
                ),
                right: _StatCard(
                  icon: Icons.schedule_rounded,
                  value: locale.formatDuration(lifetime.totalDurationSeconds),
                  label: AppStrings.profileStatTotalDuration,
                  badgeColor: AppColors.orange,
                ),
              ),
              const SizedBox(height: 8),
              _StatRow(
                left: _StatCard(
                  icon: Icons.speed_rounded,
                  value: locale.formatSpeedValue(lifetime.topSpeedKmh),
                  unit: locale.speedUnitLabel,
                  label: AppStrings.profileStatTopSpeed,
                  valueColor: AppColors.teal,
                ),
                right: lifetime.bestZeroToHundredSeconds == null
                    ? null
                    : _StatCard(
                        icon: Icons.bolt_rounded,
                        value:
                            '${lifetime.bestZeroToHundredSeconds!.toStringAsFixed(2)}s',
                        label:
                            'Best '
                            '${locale.unitSystem == UnitSystem.imperial ? AppStrings.tripSummaryZeroToSixty : AppStrings.tripSummaryZeroToHundred}',
                        badgeColor: AppColors.red,
                      ),
              ),
              if (lifetime.tripCount > 0) ...[
                const SizedBox(height: 18),
                const _SectionLabel(AppStrings.profileManeuversTitle),
                const SizedBox(height: 8),
                _StatRow(
                  left: _StatCard(
                    icon: Icons.turn_left_rounded,
                    value: lifetime.totalLeftTurns.toString(),
                    label: AppStrings.profileStatLeftTurns,
                    valueColor: AppColors.blue,
                  ),
                  right: _StatCard(
                    icon: Icons.turn_right_rounded,
                    value: lifetime.totalRightTurns.toString(),
                    label: AppStrings.profileStatRightTurns,
                    valueColor: AppColors.red,
                  ),
                ),
                const SizedBox(height: 8),
                _StatRow(
                  left: _StatCard(
                    icon: Icons.front_hand_rounded,
                    value: lifetime.totalHardBrakes.toString(),
                    label: AppStrings.profileStatBrakeEvents,
                    valueColor: AppColors.orange,
                  ),
                  right: _StatCard(
                    icon: Icons.swap_horiz_rounded,
                    value: lifetime.totalLaneChanges.toString(),
                    label: AppStrings.profileStatLaneChanges,
                    valueColor: AppColors.green,
                  ),
                ),
                if (lifetime.totalLeftTurns + lifetime.totalRightTurns > 0) ...[
                  const SizedBox(height: 10),
                  _TurnPreferenceBar(
                    leftTurns: lifetime.totalLeftTurns,
                    rightTurns: lifetime.totalRightTurns,
                  ),
                ],
                const SizedBox(height: 18),
                _StatRow(
                  left: _StatCard(
                    icon: Icons.arrow_downward_rounded,
                    value:
                        '${lifetime.bestMaxDeceleration.toStringAsFixed(1)} m/s²',
                    label: AppStrings.profileStatMaxDeceleration,
                    badgeColor: AppColors.red,
                  ),
                  right: _StatCard(
                    icon: Icons.arrow_upward_rounded,
                    value:
                        '${lifetime.bestMaxAcceleration.toStringAsFixed(1)} m/s²',
                    label: AppStrings.profileStatMaxAcceleration,
                    badgeColor: AppColors.green,
                  ),
                ),
                const SizedBox(height: 8),
                _StatRow(
                  left: _StatCard(
                    icon: Icons.vibration_rounded,
                    value: '${lifetime.bestGforce.toStringAsFixed(1)}g',
                    label: AppStrings.profileStatBestGforce,
                    valueColor: AppColors.orange,
                  ),
                  right: _StatCard(
                    icon: Icons.alt_route_rounded,
                    value: locale.formatSpeedValue(
                      lifetime.bestCorneringSpeedKmh,
                    ),
                    unit: locale.speedUnitLabel,
                    label: AppStrings.profileStatTopCorneringSpeed,
                    valueColor: AppColors.blue,
                  ),
                ),
              ],
              if (state.lifetimeSpeedBreakdown.any(
                (s) => s.percentage > 0,
              )) ...[
                const SizedBox(height: 18),
                SpeedBreakdownBar(
                  slices: state.lifetimeSpeedBreakdown,
                  locale: locale,
                ),
              ],
              const SizedBox(height: 18),
              const _SectionLabel(AppStrings.profileMoreStatsTitle),
              const SizedBox(height: 8),
              _StatRow(
                left: _StatCard(
                  icon: Icons.flag_rounded,
                  value: lifetime.tripCount.toString(),
                  label: AppStrings.profileStatTotalTrips,
                ),
                right: _StatCard(
                  icon: Icons.stop_circle_rounded,
                  value: lifetime.totalStopCount.toString(),
                  label: AppStrings.profileStatTotalStops,
                ),
              ),
              const SizedBox(height: 8),
              _StatRow(
                left: _StatCard(
                  icon: Icons.straighten_rounded,
                  value: locale.formatDistance(
                    lifetime.avgTripLengthKm,
                    fractionDigits: 1,
                  ),
                  label: AppStrings.profileStatAvgTripLength,
                ),
                right: _StatCard(
                  icon: Icons.schedule_rounded,
                  value: locale.formatDuration(lifetime.totalDurationSeconds),
                  label: AppStrings.profileStatTotalDuration,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.settings});

  final UserSettingsRow settings;

  @override
  Widget build(BuildContext context) {
    final country = countryFromCode(settings.country ?? 'US');
    final username = settings.username.isEmpty
        ? AppStrings.profileUsernamePlaceholder
        : settings.username;
    final carLabel = [
      if (settings.carMake.isNotEmpty) settings.carMake,
      if (settings.carModel.isNotEmpty) settings.carModel,
      if (settings.carYear != null) settings.carYear.toString(),
    ].join(' ');
    final meta = [
      if (country != null) '${country.flag} ${country.name}',
      if (carLabel.isNotEmpty) carLabel,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(color: AppColors.teal, width: 2),
            ),
            alignment: Alignment.center,
            child: ClipOval(
              child: AspectRatio(
                aspectRatio: 1,
                child: Builder(
                  builder: (context) {
                    // The category SVGs are 2:1 landscape — BoxFit.cover
                    // inside this square avatar crops most of the width
                    // away, leaving just a sliver of the roofline. Only
                    // an actual uploaded photo (arbitrary aspect ratio)
                    // should fill-crop; the SVG fallback needs contain.
                    final hasPhoto =
                        settings.carPhotoPath != null &&
                        settings.carPhotoPath!.isNotEmpty;
                    return CarSilhouette(
                      category: _category,
                      photoPath: settings.carPhotoPath,
                      fit: hasPhoto ? BoxFit.cover : BoxFit.contain,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: AppTextStyles.headingMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _SettingsButton(onTap: () => context.push(RouteNames.settings)),
        ],
      ),
    );
  }

  CarCategory get _category {
    if (settings.vehicleType == VehicleType.motorbike.id) {
      return CarCategory.motorbike;
    }
    // The "category" lookup against car_makes.json happens in the
    // onboarding picker — here we just pick the broad fallback by
    // vehicle type so the SVG isn't blank when no photo exists.
    return CarCategory.defaultCategory;
  }
}

/// "This Month" hero — merges what used to be two separate blocks (the
/// `MonthlyReportCard` banner + a standalone `MonthlyTrendChart` card)
/// into one card: month name, the big distance number + trip count,
/// then the trend chart inline underneath, no nested card chrome.
/// Same destination as before — tapping anywhere still opens the full
/// Monthly Report page.
class _ThisMonthCard extends StatelessWidget {
  const _ThisMonthCard({
    required this.monthly,
    required this.trend,
    required this.locale,
    required this.onTap,
  });

  final MonthlyReport monthly;
  final List<MonthlyDistanceStat> trend;
  final LocaleService locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.profileThisMonth,
                style: AppTextStyles.label.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    locale.formatDistance(
                      monthly.totalDistanceKm,
                      fractionDigits: 1,
                    ),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '·',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${monthly.tripCount}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.directions_car_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              if (trend.isNotEmpty) ...[
                const SizedBox(height: 14),
                MonthlyTrendChart(stats: trend, locale: locale),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TerritoryCard extends StatelessWidget {
  const _TerritoryCard({
    required this.territory,
    required this.countryCode,
    required this.onTap,
  });

  final TerritoryStats? territory;
  final String? countryCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = territory;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.hexagon_outlined,
                    color: AppColors.teal,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.profileTerritoryTitle.toUpperCase(),
                      style: AppTextStyles.label.copyWith(fontSize: 10),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (t == null)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.teal,
                  ),
                )
              else ...[
                Text(
                  '${t.cellCount} territories',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${t.areaKm2.toStringAsFixed(1)} km²',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TerritoryPercentChip(
                        value: t.percentOfEarth,
                        label: AppStrings.profileTerritoryOfEarth,
                      ),
                    ),
                    if (t.percentOfCountry != null && countryCode != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TerritoryPercentChip(
                          value: t.percentOfCountry!,
                          label: countryCode!.toUpperCase(),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TerritoryPercentChip extends StatelessWidget {
  const _TerritoryPercentChip({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${value.toStringAsFixed(value < 1 ? 4 : 2)}%',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.microLabel.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

/// Proportional left/right split — same construction technique as the
/// existing `SpeedBreakdownBar` (a `Row` of colored `Expanded`
/// segments), just two segments instead of four speed buckets.
class _TurnPreferenceBar extends StatelessWidget {
  const _TurnPreferenceBar({required this.leftTurns, required this.rightTurns});

  final int leftTurns;
  final int rightTurns;

  @override
  Widget build(BuildContext context) {
    final total = leftTurns + rightTurns;
    final leftPct = total == 0 ? 0.5 : leftTurns / total;
    final leftLabel = '${(leftPct * 100).toStringAsFixed(1)}%';
    final rightLabel = '${(100 - leftPct * 100).toStringAsFixed(1)}%';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.profileTurnPreferenceTitle,
            style: AppTextStyles.title,
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 30,
              child: Row(
                children: [
                  Expanded(
                    flex: (leftPct * 1000).round().clamp(1, 999),
                    child: ColoredBox(
                      color: AppColors.blue,
                      child: Center(
                        child: Text(
                          leftLabel,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (1000 - (leftPct * 1000).round()).clamp(1, 999),
                    child: ColoredBox(
                      color: AppColors.red,
                      child: Center(
                        child: Text(
                          rightLabel,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.profileTurnPreferenceLeft,
                style: AppTextStyles.microLabel.copyWith(fontSize: 10),
              ),
              Text(
                AppStrings.profileTurnPreferenceRight,
                style: AppTextStyles.microLabel.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.title);
  }
}

/// A row of two `_StatCard`s — `right` is optional so a stat that
/// doesn't exist yet (e.g. best 0-100 before the user's ever hit
/// 100 km/h) can leave its half empty instead of a dead placeholder.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.left, this.right});

  final Widget left;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 8),
        Expanded(child: right ?? const SizedBox.shrink()),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.unit,
    this.valueColor,
    this.badgeColor,
  });

  final IconData icon;
  final String value;
  final String? unit;
  final String label;
  final Color? valueColor;

  /// When set, the icon renders inside a small filled circle of this
  /// color instead of as a plain colored glyph — the reference reserves
  /// this treatment for a handful of headline stats (Total Duration,
  /// Best 0-100, Max Accel/Decel), so it's opt-in per card.
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badgeColor != null)
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 14, color: Colors.white),
            )
          else
            Icon(
              icon,
              size: 18,
              color: valueColor ?? AppColors.textSecondary,
            ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: AppTextStyles.microLabel.copyWith(fontSize: 10),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.microLabel.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

/// Top-right settings entry point on the header — replaces the old
/// bottom-of-page "Edit Settings" row so there's a single, always-visible
/// way in, matching the reference layout.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.settings_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
